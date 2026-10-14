#!/usr/bin/env python3
"""Regression checks for ARM64/PCK verification and source delivery packaging.

All executable bytes here are inert fixtures, never run as native programs.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import stat
import struct
import tempfile
import zipfile

import package_linux_complete as complete
import verify_linux_package as linux

COUNT = 0


def check(condition: bool, message: str) -> None:
    global COUNT
    COUNT += 1
    if not condition:
        raise AssertionError(message)
    print('OK ' + message)


def reject(operation, message: str) -> None:
    try:
        operation()
    except (ValueError, zipfile.BadZipFile):
        check(True, message)
    else:
        raise AssertionError(message)


def fixture_payload(extra: list[tuple[str, bytes]] | None = None) -> bytes:
    resources = [(name, ('fixture ' + name).encode()) for name in (
        'data/game_rules.json', 'data/shop_catalog.json', 'data/controller_mapping.json',
        'project.binary', 'assets/art/fixture.svg.import')]
    resources.extend(extra or [])
    data = bytearray()
    records = []
    for name, content in resources:
        records.append((name, len(data), content))
        data.extend(content)
    directory = bytearray(struct.pack('<I', len(records)))
    for name, offset, content in records:
        encoded = name.encode()
        encoded += b'\0' * ((-len(encoded)) % 4)
        directory.extend(struct.pack('<I', len(encoded)) + encoded)
        directory.extend(struct.pack('<QQ', offset, len(content)) + hashlib.md5(content).digest() + struct.pack('<I', 0))
    pack = bytearray(b'GDPC' + struct.pack('<IIIIIQQ', 3, 4, 6, 3, 2, 104, 104 + len(data)) + bytes(64))
    pack.extend(data)
    pack.extend(directory)
    elf = bytearray(256)
    elf[:16] = b'\x7fELF' + bytes((2, 1, 1, 0)) + bytes(8)
    elf[16:64] = struct.pack('<HHIQQQIHHHHHH', 2, 183, 1, 1, 64, 0, 0, 64, 56, 1, 64, 0, 0)
    interpreter = b'/lib/ld-linux-aarch64.so.1\0'
    elf[64:120] = struct.pack('<IIQQQQQQ', 3, 4, 120, 0, 0, len(interpreter), len(interpreter), 1)
    elf[120:120 + len(interpreter)] = interpreter
    return bytes(elf + pack + struct.pack('<Q', len(pack)) + b'GDPC')


def portable(archive: Path, payload: bytes, change: dict | None = None) -> None:
    change = change or {}
    with zipfile.ZipFile(archive, 'w') as output:
        for name in linux.REQUIRED_FILES:
            content = payload if name == linux.EXECUTABLE else ('fixture ' + name).encode()
            info = zipfile.ZipInfo(name)
            info.create_system = 3
            mode = 0o755 if name in (linux.EXECUTABLE, *linux.LAUNCHERS) else 0o644
            info.external_attr = (stat.S_IFREG | change.get('modes', {}).get(name, mode)) << 16
            output.writestr(info, content)
        if 'extra' in change:
            name, mode = change['extra']
            info = zipfile.ZipInfo(name)
            info.create_system = 3
            info.external_attr = mode << 16
            output.writestr(info, b'fixture extra')


def verify_checks(base: Path) -> None:
    project = base / 'project'
    (project / 'assets/art').mkdir(parents=True)
    (project / 'assets/art/fixture.svg').write_text('<svg/>')
    executable = base / linux.EXECUTABLE
    archive = base / 'portable.zip'
    payload = fixture_payload()
    executable.write_bytes(payload)
    portable(archive, payload)
    report = linux.verify(executable, archive, project)
    check(report['elf_machine'] == 183 and report['elf_type'] == 'EXEC'
          and report['interpreter'] == '/lib/ld-linux-aarch64.so.1', 'ELF ARM64 et interpréteur détectés')
    check(report['all_resource_md5_verified'] and len(report['embedded_files']) == 5
          and report['art_textures'] == 1, 'Répertoire PCK, MD5 et collection SVG vérifiés')
    check(report['crc_valid'] and all(mode == '0o755' for mode in report['unix_executable_modes'].values()),
          'ZIP portable complet et trois permissions Unix vérifiés')
    check(report['executable_sha256'] == hashlib.sha256(payload).hexdigest(), 'Empreinte ELF identique à la source')
    for changed, message in (
        (payload[:4] + bytes((1,)) + payload[5:], 'ELF 32 bits refusé'),
        (payload[:18] + struct.pack('<H', 62) + payload[20:], 'ELF x86_64 refusé'),
        (payload[:5] + bytes((2,)) + payload[6:], 'ELF big endian refusé'),
        (payload[:32] + struct.pack('<Q', len(payload)) + payload[40:], 'Table ELF hors limites refusée'),
        (payload[:-12] + struct.pack('<Q', len(payload)) + payload[-4:], 'Footer PCK hors limites refusé'),
        (payload[:256 + 20] + struct.pack('<I', 3) + payload[256 + 24:], 'PCK chiffré refusé'),
        (payload.replace(b'fixture data/game_rules.json', b'Fixture data/game_rules.json', 1), 'Altération ressource PCK refusée'),
    ):
        executable.write_bytes(changed)
        portable(archive, changed)
        reject(lambda: linux.verify(executable, archive, project), message)
    for name in ('../evil', '/absolute', 'data\\evil', 'data/./evil', 'data/\nevil', 'profiles/session.json', 'tools/source.py', '.env'):
        changed = fixture_payload([(name, b'fixture')])
        executable.write_bytes(changed)
        portable(archive, changed)
        reject(lambda: linux.verify(executable, archive, project), 'Chemin PCK interdit refusé : ' + repr(name))
    duplicate = fixture_payload([('project.binary', b'duplicate')])
    executable.write_bytes(duplicate)
    portable(archive, duplicate)
    reject(lambda: linux.verify(executable, archive, project), 'Ressource PCK dupliquée refusée')
    executable.write_bytes(payload)
    portable(archive, payload, {'modes': {linux.LAUNCHERS[0]: 0o644}})
    reject(lambda: linux.verify(executable, archive, project), 'Permission de lancement perdue refusée')
    portable(archive, payload, {'modes': {'assets/console.svg': 0o777}})
    reject(lambda: linux.verify(executable, archive, project), 'Permissions de fichier de données incorrectes refusées')
    for name, mode in (('assets/linked', stat.S_IFLNK | 0o777), ('../escape', stat.S_IFREG | 0o644),
                       ('profiles/session.json', stat.S_IFREG | 0o644), ('archive.zip', stat.S_IFREG | 0o644)):
        portable(archive, payload, {'extra': (name, mode)})
        reject(lambda: linux.verify(executable, archive, project), 'Contenu ZIP interdit refusé : ' + name)
    portable(archive, payload)
    changed = archive.read_bytes().replace(b'fixture assets/console.svg', b'Fixture assets/console.svg', 1)
    archive.write_bytes(changed)
    reject(lambda: linux.verify(executable, archive, project), 'CRC ZIP altéré refusé')
    portable(archive, payload)
    executable.write_bytes(payload.replace(b'fixture project.binary', b'fixture project.binarY', 1))
    reject(lambda: linux.verify(executable, archive, project), 'Binaire différent de la livraison refusé')


def archive_checks(base: Path) -> None:
    project = base / 'source project with spaces'
    project.mkdir()
    (project / 'project.godot').write_text('config/version="0.6.1"\n')
    (project / 'export_presets.cfg').write_text('fixture presets')
    for folder in ('scripts', 'data', 'images_profil', 'tools'):
        (project / folder).mkdir()
    (project / 'scripts/source.gd').write_text('fixture source')
    (project / 'images_profil/.gdignore').write_bytes(b'')
    (project / 'images_profil/LIRE_MOI.txt').write_text('fixture local image instructions')
    selected_relative = 'builds/releases/raspberry-pi-arm64-0.6.1'
    selected = project / selected_relative
    for name in complete.REQUIRED_DELIVERY:
        path = selected / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(fixture_payload() if name == complete.EXECUTABLE else ('fixture ' + name).encode())
        path.chmod(0o755 if name in (complete.EXECUTABLE, *complete.LAUNCHERS) else 0o644)
    for relative in ('builds/windows-0.6.1/Console_CIEL.exe', 'builds/linux-old/console-ciel.arm64',
                     'builds/previous.zip', 'builds/templates.tpz', 'data/.env', 'data/token.json',
                     'data/settings.cfg', 'data/session.json', 'data/export_credentials.cfg',
                     'scripts/__pycache__/fixture.pyc', 'data/fixture.tmp'):
        path = project / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b'preserved exclusion fixture')
    output = project / 'builds/Console_CIEL_Projet_Complet_Raspberry_Pi_0.6.1.zip'
    report_path = output.with_suffix('.verification.json')
    report_path.write_text('previous self-report fixture')
    before = {path: path.read_bytes() for path in project.rglob('*') if path.is_file()}
    report = complete.create_archive(project, output, selected_relative)
    prefix = 'console-ciel/' + selected_relative + '/'
    with zipfile.ZipFile(output) as archive:
        names = archive.namelist()
        check(report['crc_valid'] and report['all_source_hashes_verified'] and report['unix_permissions_verified'],
              'Archive complète : CRC, SHA source et permissions vérifiés')
        check(archive.read(prefix + complete.EXECUTABLE) == before[selected / complete.EXECUTABLE],
              'Archive complète : seul binaire ARM64 sélectionné livré avec octets identiques')
        check(not any('windows-0.6.1/' in name or 'linux-old/' in name for name in names),
              'Archive complète : autres dossiers binaires exclus')
        check(not any(name.endswith(('.zip', '.tpz', '.pyc', '.tmp')) or '/.env' in name
                      or '/token.json' in name or '/settings.cfg' in name or '/session.json' in name
                      or '/export_credentials.cfg' in name for name in names),
              'Archive complète : archives imbriquées, caches et données personnelles exclus')
        check('console-ciel/images_profil/.gdignore' in names and prefix + 'images_profil/.gdignore' in names,
              'Archive complète : dossiers avatars source et portable livrés')
        check('console-ciel/' + report_path.relative_to(project).as_posix() not in names,
              'Archive complète : son propre rapport reste externe')
        check(all(stat.S_IMODE(archive.getinfo(prefix + name).external_attr >> 16) == 0o755
                  for name in (complete.EXECUTABLE, *complete.LAUNCHERS)),
              'Archive complète : ELF et lanceurs restent exécutables')
        manifest = json.loads(archive.read('console-ciel/CONTENU_ARCHIVE.json'))
        check(manifest['latest_linux_directory'] == selected_relative and manifest['version'] == '0.6.1',
              'Archive complète : manifeste désigne la livraison Pi et sa version')
    check(all(path.read_bytes() == content for path, content in before.items()),
          'Archive complète : anciens binaires, ZIP et sources restent intacts sur disque')
    good_output = output.read_bytes()
    external = base / 'external.txt'
    external.write_text('preserve external fixture')
    linked = project / 'data/linked.txt'
    linked.symlink_to(external)
    reject(lambda: complete.create_archive(project, output, selected_relative), 'Lien source refusé')
    check(output.read_bytes() == good_output and external.read_text() == 'preserve external fixture',
          'Échec : archive précédente et cible externe préservées')
    linked.unlink()
    linked_output = base / 'linked-output.zip'
    linked_output.symlink_to(external)
    reject(lambda: complete.create_archive(project, linked_output, selected_relative), 'Lien de sortie refusé')
    reject(lambda: complete.create_archive(project, project / 'project.godot', selected_relative), 'Sortie non ZIP refusée')
    reject(lambda: complete.create_archive(project, project / 'builds/Console_CIEL_Projet_Complet_0.6.1.zip', selected_relative),
           'Écrasement de la livraison complète Windows refusé')
    (selected / complete.LAUNCHERS[0]).chmod(0o644)
    reject(lambda: complete.create_archive(project, output, selected_relative), 'Archive complète : lanceur non exécutable refusé')
    for relative in ('../outside', '/absolute', 'builds', 'builds/../outside'):
        reject(lambda r=relative: complete.create_archive(project, output, r), 'Sélection Linux invalide refusée : ' + relative)


def main() -> None:
    with tempfile.TemporaryDirectory(prefix='ciel-linux-tools-') as temporary:
        base = Path(temporary)
        verify_checks(base)
        archive_checks(base)
    print(f'LINUX_TOOLS : {COUNT} assertions, 0 échec(s).')


if __name__ == '__main__':
    main()
