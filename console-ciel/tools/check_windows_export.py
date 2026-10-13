#!/usr/bin/env python3
"""Exercise PowerShell export failures in disposable fixtures, not real builds.

The stub emits PE headers only to test packaging guards. These are NOT runnable
executables and are deleted with the temporary directory. Actual deliverables
are exported separately by the official Godot engine and templates.
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--powershell", default=shutil.which("pwsh"))
    args = parser.parse_args()
    if not args.powershell:
        parser.error("PowerShell requis pour exécuter ces tests du script d'export.")
    checks = 0

    def check(condition: bool, message: str) -> None:
        nonlocal checks
        checks += 1
        if not condition:
            raise AssertionError(message)
        print("OK " + message)

    with tempfile.TemporaryDirectory(prefix="ciel-windows-export-test-") as temporary:
        base = Path(temporary)
        project = base / "projet avec espaces et accents é"
        (project / "tools").mkdir(parents=True)
        shutil.copy2(ROOT / "tools/export_windows.ps1", project / "tools/export_windows.ps1")
        for name in ("project.godot", "export_presets.cfg", "docs/windows/LIRE_MOI.txt", "assets/LICENSES.md", "assets/licenses/GODOT_MIT.txt"):
            destination = project / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, destination)
        stub = base / "godot factice avec espaces"
        stub.write_text('''#!/usr/bin/env python3
import os,struct,sys
from pathlib import Path
args=sys.argv[1:]
mode=os.environ['CIEL_EXPORT_TEST_MODE']
if '--version' in args:
 print('4.5.stable.official.fake' if mode=='version' else '4.6.3.stable.official.7d41c59c4');sys.exit(0)
if '--import' in args:
 if mode=='import_error': print('SCRIPT ERROR: deliberate import failure')
 sys.exit(0)
if '--export-release' in args or '--export-debug' in args:
 if mode=='export_error': print('ERROR: missing test templates');sys.exit(0)
 if mode=='exit_error': sys.exit(7)
 if mode=='empty': sys.exit(0)
 target=Path(args[-1])
 data=bytearray(512);struct.pack_into('<H',data,0,0x5a4d);struct.pack_into('<I',data,0x3c,128)
 struct.pack_into('<IH',data,128,0x4550,0x14c if mode=='wrong_arch' else 0x8664)
 target.write_bytes(b'not an executable' if mode=='invalid' else data)
 target.with_suffix('.pck').write_text('Associated test fixture; NOT runnable')
 target.with_name('test-associated.dll').write_text('Associated test fixture; NOT runnable')
''', encoding="utf-8")
        stub.chmod(0o755)
        environment = dict(os.environ)
        for key, folder in (("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache")):
            environment[key] = str(base / folder)
        script = project / "tools/export_windows.ps1"
        zip_path = project / "builds/Console_CIEL_Windows_x86_64.zip"
        exe_path = project / "builds/windows-x86_64/Console_CIEL.exe"

        def run(mode: str, executable: Path = stub) -> subprocess.CompletedProcess[str]:
            return subprocess.run([args.powershell, "-NoProfile", "-File", str(script), "-GodotPath", str(executable), "-ProjectPath", str(project)], env=dict(environment, CIEL_EXPORT_TEST_MODE=mode), text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)

        result = run("export_error")
        check(result.returncode != 0 and "interrompu" in result.stdout and not zip_path.exists(), "Modèles manquants : erreur explicite et aucun ZIP publié")
        result = run("good")
        check(result.returncode == 0 and exe_path.exists() and zip_path.exists(), "Chemins avec espaces et accents acceptés")
        with ZipFile(zip_path) as archive:
            check(archive.testzip() is None, "CRC de l'archive de test valide")
            check({"Console_CIEL.exe", "Console_CIEL.pck", "test-associated.dll", "LIRE_MOI.txt", "assets/LICENSES.md", "assets/licenses/GODOT_MIT.txt"}.issubset(archive.namelist()), "Fichiers associés et licences conservés")
            check(not any("profiles/" in item or item.endswith(("settings.cfg", "session.json")) for item in archive.namelist()), "Données utilisateur absentes de l'archive")
        previous_zip = zip_path.read_bytes()
        previous_exe = exe_path.read_bytes()
        for mode in ("import_error", "export_error", "exit_error", "empty", "invalid", "wrong_arch", "version"):
            result = run(mode)
            check(result.returncode != 0 and "interrompu" in result.stdout, f"Échec {mode} détecté")
            check(zip_path.read_bytes() == previous_zip and exe_path.read_bytes() == previous_exe, f"Échec {mode} conserve la livraison précédente")
        check(run("good", base / "moteur absent").returncode != 0, "Moteur absent détecté")
        result = run("good")
        check(result.returncode == 0, "Remplacement d'une archive précédente réussi : " + result.stdout)
        check(not list((project / "builds").glob(".windows-*")), "Répertoires de préparation nettoyés")
    print(f"WINDOWS_EXPORT_SCRIPT : {checks} assertions, 0 échec(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
