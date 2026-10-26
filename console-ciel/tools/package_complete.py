#!/usr/bin/env python3
"""Package the full CIEL project and existing binaries without nested archives.

No engine execution, export rebuild, user-data access or external upload.
The root folder is console-ciel/ and relative project paths are preserved.
"""
from __future__ import annotations

import hashlib
import argparse
import json
import os
from pathlib import Path
import re
from tempfile import NamedTemporaryFile
from zipfile import ZIP_DEFLATED, ZipFile

PROJECT_FOLDERS = (
    'scenes', 'scripts', 'assets', 'themes', 'data', 'tests', 'docs', 'tools', 'images_profil',
    'builds', 'export_templates', 'script_templates', 'feature_profiles',
    'text_editor_themes', 'shared', 'scratch', 'library-files',
)
EXCLUDED_DIRS = {'.godot', '__pycache__', '.pytest_cache', '.mypy_cache', '.ruff_cache', 'profiles'}
SECRET_FILES = {'export_credentials.cfg', 'credentials.json', 'token.json', 'service_account.json'}
PERSONAL_FILES = {'session.json', 'settings.cfg'}
TEMP_SUFFIXES = ('.tmp', '.temp', '.swp', '.swo', '.pyc', '.pyo', '.lock', '.part', '.bak', '~')


def excluded(path: Path, project: Path) -> str:
    relative = path.relative_to(project)
    if any(part in EXCLUDED_DIRS or part.startswith('.runtime-') for part in relative.parts):
        return 'cache ou sauvegarde personnelle'
    if path.suffix.lower() in {'.zip', '.tpz'}:
        return 'archive imbriquée ou modèles régénérables'
    if path.name in SECRET_FILES or path.name == '.env' or path.name.startswith('.env.') or path.suffix.lower() in {'.pem', '.key', '.p12', '.pfx'}:
        return 'secret ou configuration confidentielle'
    if path.name in PERSONAL_FILES:
        return 'sauvegarde personnelle'
    if path.name.endswith(TEMP_SUFFIXES) or path.name.startswith(('.windows-export-', '.windows-previous-')):
        return 'fichier temporaire'
    return ''




def archive_name(project: Path, source: Path) -> str:
    if source.is_relative_to(project):
        return 'console-ciel/' + source.relative_to(project).as_posix()
    return source.relative_to(project.parent).as_posix()


def archive_source(project: Path, name: str) -> Path:
    return project / name.removeprefix('console-ciel/') if name.startswith('console-ciel/') else project.parent / name


def add_solution_files(project: Path, files: list[Path], directories: set[Path]) -> None:
    """Include the repository solution sheet beside console-ciel/ in full ZIPs."""
    solutions = project.parent / 'solution'
    if not solutions.exists():
        return
    if solutions.is_symlink():
        raise ValueError('Dossier solution lié interdit.')
    directories.add(solutions)
    for source in sorted(solutions.rglob('*')):
        if source.is_symlink():
            raise ValueError(f'Lien solution interdit : {source}')
        if source.is_file() and not excluded(source, project.parent):
            files.append(source)
        elif source.is_dir() and not excluded(source, project.parent):
            directories.add(source)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def project_version(project: Path) -> str:
    config = (project / 'project.godot').read_text(encoding='utf-8')
    found = re.search(r'^config/version="([0-9]+\.[0-9]+\.[0-9]+)"$', config, re.MULTILINE)
    if not found:
        raise ValueError('Version logiciel absente ou invalide dans project.godot.')
    return found.group(1)


def create_archive(project: Path, output: Path, windows_directory: str | None = None, current_windows_only: bool = False) -> dict:
    project = project.resolve()
    if output.is_symlink() or any(parent.is_symlink() for parent in output.parents):
        raise ValueError('Une sortie liée est interdite.')
    version = project_version(project)
    default_directory = f'builds/windows-x86_64-{"finition" if version == "0.3.1" else "refonte"}-{version}'
    latest_relative = Path(windows_directory or default_directory)
    if latest_relative.is_absolute() or '..' in latest_relative.parts or latest_relative.parts[:1] != ('builds',):
        raise ValueError('La livraison Windows doit être un dossier relatif sous builds/.')
    latest = project / latest_relative
    required = [
        project / 'project.godot', project / 'export_presets.cfg',
        latest / 'Console_CIEL.exe', latest / 'LIRE_MOI.txt',
        latest / 'assets/LICENSES.md', latest / 'assets/licenses/GODOT_MIT.txt',
    ]
    if any(not path.is_file() or path.is_symlink() for path in required):
        raise ValueError(f'Projet ou livraison Windows {version} incomplet : {latest_relative}.')
    files: list[Path] = []
    directories: set[Path] = set()
    skipped: list[dict] = []
    for item in project.iterdir():
        if not item.is_file():
            continue
        reason = excluded(item, project)
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
                if current_windows_only and folder == 'builds':
                    parts = child.relative_to(project).parts
                    selected_parts = latest_relative.parts
                    related = parts[:len(selected_parts)] == selected_parts or selected_parts[:len(parts)] == parts
                    if not related:
                        skipped.append({'path': child.relative_to(project).as_posix()+'/', 'reason': 'ancienne livraison conservée séparément dans le dépôt'})
                        continue
                reason = excluded(child, project)
                if reason:
                    skipped.append({'path': child.relative_to(project).as_posix()+'/', 'reason': reason})
                elif child.is_symlink():
                    raise ValueError(f'Lien source interdit : {child}')
                else:
                    accepted.append(name)
                    directories.add(child)
            children[:] = accepted
            for name in names:
                source = parent / name
                if source == output.with_suffix('.verification.json'):
                    skipped.append({'path': source.relative_to(project).as_posix(), 'reason': 'rapport de sortie généré après vérification'})
                    continue
                reason = excluded(source, project)
                if reason:
                    skipped.append({'path': source.relative_to(project).as_posix(), 'reason': reason})
                elif source.is_symlink():
                    raise ValueError(f'Lien source interdit : {source}')
                else:
                    files.append(source)
    add_solution_files(project, files, directories)
    files = sorted(set(files))
    output.parent.mkdir(parents=True, exist_ok=True)
    with NamedTemporaryFile(dir=output.parent, suffix='.zip.tmp', delete=False) as temporary:
        stage = Path(temporary.name)
    records = []
    try:
        with ZipFile(stage, 'w', compression=ZIP_DEFLATED, compresslevel=6) as archive:
            for folder in sorted(directories):
                archive.writestr(archive_name(project, folder)+'/', b'')
            for source in files:
                name = archive_name(project, source)
                before = sha256(source)
                archive.write(source, name)
                records.append({'file': name, 'bytes': source.stat().st_size, 'sha256': before})
            archive.writestr('console-ciel/CONTENU_ARCHIVE.json', json.dumps(
                {'version': version, 'files': records, 'excluded': skipped,
                 'latest_windows_directory': latest_relative.as_posix(),
                 'notes': ['Aucun ZIP imbriqué ; exécutables existants non reconstruits.',
                           f'Utiliser {latest_relative.as_posix()}/Console_CIEL.exe ; les anciens binaires restent conservés séparément.' if current_windows_only else f'Utiliser {latest_relative.as_posix()}/Console_CIEL.exe ; les anciens binaires restent dans leurs dossiers.']},
                ensure_ascii=False, indent=2))
        with ZipFile(stage) as archive:
            bad = archive.testzip()
            if bad is not None:
                raise ValueError(f'CRC incorrect : {bad}')
            for record in records:
                digest = hashlib.sha256()
                with archive.open(record['file']) as stream:
                    for chunk in iter(lambda: stream.read(1024 * 1024), b''):
                        digest.update(chunk)
                source = archive_source(project, record['file'])
                if digest.hexdigest() != record['sha256'] or sha256(source) != record['sha256']:
                    raise ValueError(f'Octets différents ou source modifiée pendant l’archivage : {record["file"]}')
            names = set(archive.namelist())
            if any(name.lower().endswith(('.zip', '.tpz')) for name in names):
                raise ValueError('Archive imbriquée interdite.')
            if not {'console-ciel/'+path.relative_to(project).as_posix() for path in required}.issubset(names):
                raise ValueError('Archive incomplète.')
        os.replace(stage, output)
    finally:
        stage.unlink(missing_ok=True)
    return {'archive': str(output), 'bytes': output.stat().st_size, 'sha256': sha256(output),
            'files': records, 'excluded': skipped, 'crc_valid': True,
            'all_source_hashes_verified': True, 'layout': 'console-ciel/<organisation existante>',
            'windows_latest': 'console-ciel/'+latest_relative.as_posix()+'/Console_CIEL.exe',
            'notes': ['Sources et binaires existants, sans nouvel export.',
                      'Anciennes livraisons conservées séparément ; seule la livraison Windows courante est incluse.' if current_windows_only else 'Ancien binaire Windows conservé dans son dossier existant ; aucun ZIP imbriqué.',
                      'Polices intégrées à Godot : notices dans assets/licenses/ ; pas de police du PC requise.',
                      'Métadonnées Git, caches, secrets et sauvegardes personnelles non inclus.']}


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--windows-directory', help='Dossier relatif des binaires existants sous builds/.')
    parser.add_argument('--current-windows-only', action='store_true', help='Inclure seulement les binaires Windows courants ; garder les anciennes livraisons séparément.')
    args = parser.parse_args()
    version = project_version(root)
    destination = root / f'builds/Console_CIEL_Projet_Complet_{version}.zip'
    report = create_archive(root, destination, args.windows_directory, args.current_windows_only)
    # Verification report is separate so it cannot recursively include itself.
    destination.with_suffix('.verification.json').write_text(
        json.dumps(report, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')
    print(json.dumps({key: report[key] for key in ['archive', 'bytes', 'sha256', 'crc_valid', 'all_source_hashes_verified']}, ensure_ascii=False))
    print(f'{len(report["files"])} fichiers vérifiés.')
