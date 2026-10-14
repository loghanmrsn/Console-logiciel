#!/usr/bin/env python3
"""Verify the Raspberry Pi portable ZIP, ELF ARM64 and embedded Godot PCK."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import stat
import struct
import zipfile

EXECUTABLE = 'console-ciel.arm64'
LAUNCHERS = ('Lancer_Console_CIEL.sh', 'Installer_raccourci.sh')
REQUIRED_FILES = (
    EXECUTABLE, *LAUNCHERS, 'LIRE_MOI.txt', 'assets/console.svg',
    'assets/LICENSES.md', 'assets/licenses/CC0.txt', 'assets/licenses/GODOT_MIT.txt',
    'assets/licenses/GODOT_LICENSE_TEXTS.json', 'assets/licenses/GODOT_THIRD_PARTY.json',
    'images_profil/.gdignore', 'images_profil/LIRE_MOI.txt',
)
FORBIDDEN_PARTS = {'profiles', 'tests', 'tools', 'docs', 'builds', '.git', '__pycache__'}
PCK_HEADER_SIZE = 104  # magic + five uint32 fields + two uint64 offsets + sixteen reserved uint32
SECRET_NAMES = {'export_credentials.cfg', 'credentials.json', 'token.json', 'service_account.json',
                'session.json', 'settings.cfg'}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def safe_name(name: str) -> bool:
    """Accept only canonical relative POSIX paths, including Godot .godot imports."""
    path = PurePosixPath(name)
    return bool(name) and '\\' not in name and ':' not in name and all(ord(char) >= 32 and ord(char) != 127 for char in name) \
        and not path.is_absolute() and all(part not in {'', '.', '..'} for part in name.split('/'))


def development_or_secret(name: str) -> bool:
    parts = PurePosixPath(name).parts
    return any(part in FORBIDDEN_PARTS or part.startswith('.runtime-') for part in parts) \
        or any(part in SECRET_NAMES or part == '.env' or part.startswith('.env.') for part in parts) \
        or name.lower().endswith(('.zip', '.tpz', '.pem', '.key', '.p12', '.pfx',
                                '.tmp', '.temp', '.swp', '.swo', '.pyc', '.pyo', '.lock', '.part', '.bak', '~'))


def elf_metadata(payload: bytes) -> dict:
    require(len(payload) >= 64 and payload[:4] == b'\x7fELF', 'En-tête ELF absent ou tronqué.')
    require(payload[4:7] == bytes((2, 1, 1)), 'ELF64 little endian version 1 requis.')
    require(payload[7] in (0, 3), 'ABI ELF Linux/System V requis.')
    fields = struct.unpack_from('<HHIQQQIHHHHHH', payload, 16)
    kind, machine, version, entry, phoff, shoff, flags, ehsize, phsize, phcount, shsize, shcount, shnames = fields
    require(kind in (2, 3) and machine == 183 and version == 1 and entry > 0,
            'Exécutable ELF AArch64 requis.')
    require(ehsize == 64 and phsize == 56 and 0 < phcount < 65535,
            'En-têtes ELF invalides.')
    require(64 <= phoff and phoff + phsize * phcount <= len(payload),
            'Table des segments ELF hors limites.')
    if shcount:
        require(shsize == 64 and shoff >= 64 and shoff + shsize * shcount <= len(payload)
                and shnames < shcount, 'Table des sections ELF hors limites.')
    interpreters = []
    for index in range(phcount):
        ptype, pflags, offset, vaddr, paddr, size, memsize, align = struct.unpack_from(
            '<IIQQQQQQ', payload, phoff + phsize * index)
        require(offset <= len(payload) and size <= len(payload) - offset,
                'Segment ELF hors limites.')
        if ptype == 1:
            require(memsize >= size, 'Segment ELF LOAD invalide.')
        if ptype == 3:
            raw = payload[offset:offset + size]
            require(1 < size < 4096 and raw.endswith(b'\0') and b'\0' not in raw[:-1],
                    'Interpréteur ELF invalide.')
            interpreter = raw[:-1].decode('utf-8')
            require(interpreter.startswith('/') and '\n' not in interpreter,
                    'Chemin de l’interpréteur ELF invalide.')
            interpreters.append(interpreter)
    require(len(interpreters) <= 1, 'Interpréteurs ELF dupliqués.')
    return {'architecture': 'ELF64 little endian AArch64', 'elf_machine': machine,
            'elf_type': 'EXEC' if kind == 2 else 'DYN',
            'interpreter': interpreters[0] if interpreters else None,
            'program_headers': phcount, 'section_headers': shcount}


def embedded_pack(payload: bytes, project: Path) -> dict:
    require(len(payload) >= PCK_HEADER_SIZE + 12 and payload[-4:] == b'GDPC', 'Pack intégré absent.')
    pack_size = struct.unpack_from('<Q', payload, len(payload) - 12)[0]
    start = len(payload) - pack_size - 12
    pack_end = len(payload) - 12
    require(0 <= start < pack_end - PCK_HEADER_SIZE and payload[start:start + 4] == b'GDPC',
            'Emplacement PCK invalide.')
    format_version, major, minor, patch, flags = struct.unpack_from('<IIIII', payload, start + 4)
    require((format_version, major, minor, patch, flags) == (3, 4, 6, 3, 2),
            'Format moteur / PCK inattendu ; Godot 4.6.3, format 3 relatif non chiffré requis.')
    base, directory = struct.unpack_from('<QQ', payload, start + 24)
    directory_start = start + directory
    require(PCK_HEADER_SIZE <= base <= directory and start + PCK_HEADER_SIZE <= directory_start <= pack_end - 4,
            'Répertoire ou base des données PCK hors limites.')
    position = directory_start
    count = struct.unpack_from('<I', payload, position)[0]
    position += 4
    require(0 < count < 10000, 'Nombre de ressources invalide.')
    entries = []
    spans = []
    for _ in range(count):
        require(position + 4 <= pack_end, 'Répertoire PCK tronqué.')
        length = struct.unpack_from('<I', payload, position)[0]
        position += 4
        require(0 < length < 65536 and position + length + 36 <= pack_end,
                'Nom ou entrée PCK tronqué.')
        encoded = payload[position:position + length].rstrip(b'\0')
        name = encoded.decode('utf-8')
        position += length
        require(safe_name(name) and not development_or_secret(name),
                'Chemin de ressource interdit : ' + name)
        offset, size = struct.unpack_from('<QQ', payload, position)
        expected = payload[position + 16:position + 32]
        entry_flags = struct.unpack_from('<I', payload, position + 32)[0]
        position += 36
        begin = start + base + offset
        end = begin + size
        require(entry_flags == 0 and start + PCK_HEADER_SIZE <= begin <= end <= directory_start,
                'Bornes ou chiffrement inattendus : ' + name)
        require(hashlib.md5(payload[begin:end]).digest() == expected, 'Ressource altérée : ' + name)
        if size:
            spans.append((begin, end, name))
        entries.append({'file': name, 'bytes': size, 'md5': expected.hex()})
    spans.sort()
    require(all(a[1] <= b[0] for a, b in zip(spans, spans[1:])), 'Ressources PCK superposées.')
    files = {entry['file'] for entry in entries}
    require(len(files) == count, 'Ressource PCK dupliquée.')
    art = {name for name in files if name.startswith('assets/art/') and name.endswith('.svg.import')}
    expected_art = {path.relative_to(project).as_posix() + '.import'
                    for path in (project / 'assets/art').rglob('*.svg')}
    require(bool(expected_art) and art == expected_art, 'Collection graphique différente des sources livrées.')
    for name in ('data/game_rules.json', 'data/shop_catalog.json', 'data/controller_mapping.json', 'project.binary'):
        require(name in files, 'Ressource absente : ' + name)
    return {'embedded_files': entries, 'art_textures': len(art), 'pack_start': start,
            'pack_bytes': pack_size, 'pack_format': format_version,
            'godot_version': f'{major}.{minor}.{patch}', 'all_resource_md5_verified': True}


def verify(executable: Path, archive: Path, project: Path | None = None) -> dict:
    project = (project or Path(__file__).resolve().parents[1]).resolve()
    require(executable.is_file() and not executable.is_symlink(), 'Exécutable absent ou lié.')
    require(archive.is_file() and not archive.is_symlink(), 'Archive absente ou liée.')
    payload = executable.read_bytes()
    metadata = elf_metadata(payload)
    metadata.update(embedded_pack(payload, project))
    with zipfile.ZipFile(archive) as package:
        require(package.testzip() is None, 'CRC ZIP invalide.')
        names = package.namelist()
        require(len(names) == len(set(names)), 'Entrées ZIP dupliquées.')
        for info in package.infolist():
            name = info.filename.removesuffix('/')
            require(safe_name(name) and not development_or_secret(name), 'Chemin ZIP interdit : ' + name)
            mode = info.external_attr >> 16
            require(not stat.S_ISLNK(mode) and stat.S_IFMT(mode) in (0, stat.S_IFREG, stat.S_IFDIR),
                    'Lien ou fichier spécial ZIP interdit : ' + name)
            require(not info.flag_bits & 1, 'Entrée ZIP chiffrée : ' + name)
        for name in REQUIRED_FILES:
            require(name in names and not package.getinfo(name).is_dir(), 'Livraison incomplète : ' + name)
            info = package.getinfo(name)
            mode = info.external_attr >> 16
            expected = 0o755 if name in (EXECUTABLE, *LAUNCHERS) else 0o644
            require(info.create_system == 3 and stat.S_ISREG(mode) and stat.S_IMODE(mode) == expected,
                    f'Type de fichier ou permissions Unix {oct(expected)} incorrects : ' + name)
        require(package.read(EXECUTABLE) == payload, 'ZIP différent du binaire vérifié.')
        modes = {}
        for name in (EXECUTABLE, *LAUNCHERS):
            info = package.getinfo(name)
            modes[name] = stat.S_IMODE(info.external_attr >> 16)
            require(info.create_system == 3 and modes[name] == 0o755,
                    'Permissions Unix 0755 absentes : ' + name)
        file_records = [{'file': info.filename, 'bytes': info.file_size,
                         'sha256': hashlib.sha256(package.read(info.filename)).hexdigest()}
                        for info in package.infolist() if not info.is_dir()]
    return {'executable': str(executable), 'executable_bytes': len(payload),
            'executable_sha256': hashlib.sha256(payload).hexdigest(),
            'archive': str(archive), 'zip_bytes': archive.stat().st_size,
            'zip_sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
            'crc_valid': True, 'archive_entries': names, 'archive_files': file_records,
            'unix_executable_modes': {name: oct(mode) for name, mode in modes.items()},
            **metadata}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', type=Path, required=True)
    parser.add_argument('--zip', type=Path, required=True)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    report = verify(args.exe, args.zip)
    if args.report:
        require(not args.report.is_symlink() and not any(parent.is_symlink() for parent in args.report.parents),
                'Rapport lié interdit.')
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('LINUX_PACKAGE : ELF AArch64, CRC valide, %d ressources intactes, %d SVG importés, permissions 0755.'
          % (len(report['embedded_files']), report['art_textures']))


if __name__ == '__main__':
    main()
