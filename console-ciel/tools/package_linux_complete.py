#!/usr/bin/env python3
"""Archive all CIEL sources with only the selected Raspberry Pi ARM64 delivery.

No engine execution, export rebuild, user-data access or external upload.
The root folder remains console-ciel/; older deliveries remain on disk.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import stat
from tempfile import NamedTemporaryFile
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

# Share the existing source exclusions without changing the Windows tool or API.
_spec = importlib.util.spec_from_file_location('ciel_complete_shared', Path(__file__).with_name('package_complete.py'))
_shared = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_shared)
PROJECT_FOLDERS = _shared.PROJECT_FOLDERS
excluded = _shared.excluded
sha256 = _shared.sha256
project_version = _shared.project_version

EXECUTABLE = 'console-ciel.arm64'
LAUNCHERS = ('Lancer_Console_CIEL.sh', 'Installer_raccourci.sh')
REQUIRED_DELIVERY = (
    EXECUTABLE, *LAUNCHERS, 'LIRE_MOI.txt', 'assets/console.svg',
    'assets/LICENSES.md', 'assets/licenses/CC0.txt', 'assets/licenses/GODOT_MIT.txt',
    'assets/licenses/GODOT_LICENSE_TEXTS.json', 'assets/licenses/GODOT_THIRD_PARTY.json',
    'images_profil/.gdignore', 'images_profil/LIRE_MOI.txt',
)


def create_archive(project: Path, output: Path, linux_directory: str) -> dict:
    if project.is_symlink() or output.is_symlink() or any(parent.is_symlink() for parent in output.parents):
        raise ValueError('Une source ou sortie liée est interdite.')
    project = project.resolve()
    output = output.absolute()
    version = project_version(project)
    if output.suffix.lower() != '.zip' or output == project / f'builds/Console_CIEL_Projet_Complet_{version}.zip':
        raise ValueError('La sortie doit être une archive ZIP distincte de la livraison complète Windows.')
    latest_relative = Path(linux_directory)
    if latest_relative.is_absolute() or '..' in latest_relative.parts or latest_relative.parts[:1] != ('builds',) \
            or latest_relative.as_posix() != linux_directory or len(latest_relative.parts) < 2:
        raise ValueError('La livraison Raspberry Pi doit être un dossier relatif sous builds/.')
    latest = project / latest_relative
    required = [project / 'project.godot', project / 'export_presets.cfg',
                *(latest / name for name in REQUIRED_DELIVERY)]
    if any(not path.is_file() or path.is_symlink() for path in required):
        raise ValueError(f'Projet ou livraison Raspberry Pi {version} incomplet : {latest_relative}.')
    for name in (EXECUTABLE, *LAUNCHERS):
        if stat.S_IMODE((latest / name).stat().st_mode) != 0o755:
            raise ValueError('Permissions 0755 requises : ' + name)
    files = []
    directories = set()
    skipped = []
    for item in project.iterdir():
        if not item.is_file():
            continue
        reason = excluded(item, project)
        if item.name == 'CONTENU_ARCHIVE.json':
            reason = 'manifeste généré pour cette archive'
        if reason:
            skipped.append({'path': item.name, 'reason': reason})
        elif item.is_symlink():
            raise ValueError(f'Lien source interdit : {item}')
        else:
            files.append(item)
    for folder in PROJECT_FOLDERS:
        top = project / folder
        if not top.is_dir():
            continue
        if top.is_symlink():
            raise ValueError(f'Dossier lié interdit : {top}')
        directories.add(top)
        for directory, children, names in os.walk(top, followlinks=False):
            parent = Path(directory)
            accepted = []
            for name in children:
                child = parent / name
                if folder == 'builds':
                    parts = child.relative_to(project).parts
                    selected = latest_relative.parts
                    related = parts[:len(selected)] == selected or selected[:len(parts)] == parts
                    if not related:
                        skipped.append({'path': child.relative_to(project).as_posix() + '/',
                                        'reason': 'autre livraison conservée séparément dans le dépôt'})
                        continue
                reason = excluded(child, project)
                if reason:
                    skipped.append({'path': child.relative_to(project).as_posix() + '/', 'reason': reason})
                elif child.is_symlink():
                    raise ValueError(f'Lien source interdit : {child}')
                else:
                    accepted.append(name)
                    directories.add(child)
            children[:] = accepted
            for name in names:
                source = parent / name
                relative = source.relative_to(project)
                reason = excluded(source, project)
                if source == output.with_suffix('.verification.json'):
                    reason = 'rapport externe généré après vérification'
                if folder == 'builds' and relative.parts[:len(latest_relative.parts)] != latest_relative.parts:
                    # Keep readable delivery metadata, but no other raw platform binary.
                    if source.suffix.lower() not in {'.md', '.json', '.txt', '.zip', '.tpz'}:
                        reason = 'autre binaire conservé séparément dans le dépôt'
                if reason:
                    skipped.append({'path': relative.as_posix(), 'reason': reason})
                elif source.is_symlink():
                    raise ValueError(f'Lien source interdit : {source}')
                else:
                    files.append(source)
    files = sorted(set(files))
    output.parent.mkdir(parents=True, exist_ok=True)
    with NamedTemporaryFile(dir=output.parent, suffix='.zip.tmp', delete=False) as temporary:
        stage = Path(temporary.name)
    records = []
    try:
        with ZipFile(stage, 'w', compression=ZIP_DEFLATED, compresslevel=6) as archive:
            for folder in sorted(directories):
                info = ZipInfo('console-ciel/' + folder.relative_to(project).as_posix() + '/')
                info.create_system = 3
                info.external_attr = (stat.S_IFDIR | 0o755) << 16 | 0x10
                archive.writestr(info, b'')
            for source in files:
                name = 'console-ciel/' + source.relative_to(project).as_posix()
                before = sha256(source)
                archive.write(source, name)
                records.append({'file': name, 'bytes': source.stat().st_size, 'sha256': before,
                                'unix_mode': oct(stat.S_IMODE(source.stat().st_mode))})
            archive.writestr('console-ciel/CONTENU_ARCHIVE.json', json.dumps(
                {'version': version, 'files': records, 'excluded': skipped,
                 'latest_linux_directory': latest_relative.as_posix(),
                 'notes': ['Aucun ZIP imbriqué ; exécutables existants non reconstruits.',
                           f'Utiliser {latest_relative.as_posix()}/Lancer_Console_CIEL.sh sur Raspberry Pi OS 64 bits avec bureau.',
                           'Les anciennes livraisons Linux et Windows restent conservées séparément dans le dépôt.']},
                ensure_ascii=False, indent=2))
        with ZipFile(stage) as archive:
            if archive.testzip() is not None or len(archive.namelist()) != len(set(archive.namelist())):
                raise ValueError('CRC incorrect ou entrée ZIP dupliquée.')
            for record in records:
                digest = hashlib.sha256()
                with archive.open(record['file']) as stream:
                    for chunk in iter(lambda: stream.read(1024 * 1024), b''):
                        digest.update(chunk)
                source = project / record['file'].removeprefix('console-ciel/')
                info = archive.getinfo(record['file'])
                if digest.hexdigest() != record['sha256'] or sha256(source) != record['sha256']:
                    raise ValueError(f'Octets différents ou source modifiée pendant l’archivage : {record["file"]}')
                if oct(stat.S_IMODE(info.external_attr >> 16)) != record['unix_mode']:
                    raise ValueError(f'Permissions différentes : {record["file"]}')
            names = set(archive.namelist())
            if any(name.lower().endswith(('.zip', '.tpz')) for name in names):
                raise ValueError('Archive imbriquée interdite.')
            if not {'console-ciel/' + path.relative_to(project).as_posix() for path in required}.issubset(names):
                raise ValueError('Archive incomplète.')
            for name in (EXECUTABLE, *LAUNCHERS):
                member = archive.getinfo('console-ciel/' + latest_relative.as_posix() + '/' + name)
                if member.create_system != 3 or stat.S_IMODE(member.external_attr >> 16) != 0o755:
                    raise ValueError('Permissions d’exécution perdues : ' + name)
        os.replace(stage, output)
    finally:
        stage.unlink(missing_ok=True)
    return {'archive': str(output), 'bytes': output.stat().st_size, 'sha256': sha256(output),
            'files': records, 'excluded': skipped, 'crc_valid': True,
            'all_source_hashes_verified': True, 'unix_permissions_verified': True,
            'layout': 'console-ciel/<organisation existante>',
            'linux_latest': 'console-ciel/' + latest_relative.as_posix() + '/' + EXECUTABLE,
            'notes': ['Sources et binaire ARM64 existants, sans nouvel export.',
                      'Seule la livraison Raspberry Pi sélectionnée est incluse ; anciennes livraisons conservées séparément.',
                      'Métadonnées Git, caches, secrets et sauvegardes personnelles non inclus.']}


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--linux-directory', required=True, help='Dossier relatif du binaire ARM64 existant sous builds/.')
    parser.add_argument('--output', type=Path, help='Destination facultative ; ne remplace pas l’archive complète Windows.')
    args = parser.parse_args()
    version = project_version(root)
    destination = args.output or root / f'builds/Console_CIEL_Projet_Complet_Raspberry_Pi_{version}.zip'
    report = create_archive(root, destination, args.linux_directory)
    destination.with_suffix('.verification.json').write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print(json.dumps({key: report[key] for key in ('archive', 'bytes', 'sha256', 'crc_valid',
                                                 'all_source_hashes_verified', 'unix_permissions_verified')}, ensure_ascii=False))
    print(f'{len(report["files"])} fichiers vérifiés.')


if __name__ == '__main__':
    main()
