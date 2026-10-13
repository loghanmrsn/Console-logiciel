#!/usr/bin/env python3
"""Archive project sources without following symlinks or including player data."""
from pathlib import Path
from tempfile import NamedTemporaryFile
from zipfile import ZIP_DEFLATED, ZipFile
import os

FOLDERS = ('scenes', 'scripts', 'assets', 'themes', 'data', 'tests', 'docs', 'tools')
ROOT_FILES = ('project.godot', 'default_bus_layout.tres', 'export_presets.cfg', 'README.md', '.gitignore')

def create_archive(project: Path, output: Path) -> int:
    project = project.resolve()
    for parent in (output, *output.parents):
        if parent.is_symlink():
            raise ValueError(f'Lien symbolique refusé pour la sortie : {parent}')
        if parent == project:
            break
    files = []
    for name in ROOT_FILES:
        path = project / name
        if path.is_symlink() or not path.is_file():
            raise ValueError(f'Source absente ou liée : {path}')
        files.append(path)
    for name in FOLDERS:
        folder = project / name
        if folder.is_symlink() or not folder.is_dir():
            raise ValueError(f'Dossier source absent ou lié : {folder}')
        for directory, dirs, names in os.walk(folder, followlinks=False):
            for entry in [*dirs, *names]:
                if (Path(directory) / entry).is_symlink():
                    raise ValueError(f'Lien symbolique refusé : {Path(directory) / entry}')
            dirs[:] = [name for name in dirs if name != '__pycache__']
            files.extend(Path(directory) / name for name in names)
    output.parent.mkdir(parents=True, exist_ok=True)
    with NamedTemporaryFile(dir=output.parent, suffix='.zip.tmp', delete=False) as staging:
        staging_path = Path(staging.name)
    try:
        with ZipFile(staging_path, 'w', compression=ZIP_DEFLATED) as archive:
            for path in sorted(set(files)):
                archive.write(path, 'console-ciel/' + path.relative_to(project).as_posix())
            if archive.testzip() is not None:
                raise ValueError('Vérification CRC de l’archive échouée.')
        os.replace(staging_path, output)
    finally:
        staging_path.unlink(missing_ok=True)
    return len(files)

if __name__ == '__main__':
    project = Path(__file__).resolve().parents[1]
    output = project / 'builds' / 'console-ciel-source.zip'
    count = create_archive(project, output)
    print(f'{count} fichiers : {output} ({output.stat().st_size} octets)')
