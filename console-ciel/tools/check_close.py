#!/usr/bin/env python3
"""Check four real application closures; inspect persisted documents after exit.

Every Godot process and XDG home uses an explicit disposable /tmp fixture.
Success requires the real main.gd quit path, native key validation, and exact
profile/settings documents. No normal profile is read or modified.
"""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def read_settings(path: Path) -> dict:
    values = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"([a-z_]+)=(.+)", line.strip())
        if not match or match.group(1) == "schema_version":
            continue
        key, raw = match.groups()
        if raw in ("true", "false"):
            values[key] = raw == "true"
        else:
            values[key] = float(raw) if "." in raw else int(raw)
    return values


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=shutil.which("godot") or "godot")
    parser.add_argument("--log-dir", type=Path, default=Path("tests/stability_results"))
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    logs = args.log_dir.resolve() if args.log_dir.is_absolute() else project / args.log_dir
    logs.mkdir(parents=True, exist_ok=True)
    cases = ("apply", "discard", "failure_retry", "failure_cancel")
    results = []
    with tempfile.TemporaryDirectory(prefix="ciel-close-") as temporary:
        runtime = Path(temporary)
        environment = os.environ.copy()
        for key, folder in (("XDG_DATA_HOME", "xdg-data"), ("XDG_CONFIG_HOME", "xdg-config"), ("XDG_CACHE_HOME", "xdg-cache")):
            environment[key] = str(runtime / folder)
        try:
            version = subprocess.check_output([args.godot, "--version"], cwd=project, env=environment, text=True, timeout=15).strip()
        except (OSError, subprocess.SubprocessError) as error:
            print("Version Godot impossible à lire : " + str(error))
            return 1
        if not version.startswith("4.6.3.stable."):
            raise SystemExit("Godot 4.6.3 requis : " + version)
        for case in cases:
            fixture = runtime / case
            fixture.mkdir()
            marker = fixture / "close_fixture.json"
            marker.write_text(json.dumps({"purpose": "CIEL isolated native close"}), encoding="utf-8")
            command = [args.godot, "--headless", "--path", str(project), "--script", "res://tests/close_persistence.gd", "--", "--case", case, "--test-data-root", str(fixture)]
            try:
                process = subprocess.run(command, cwd=project, env=environment, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
                output, status = process.stdout, process.returncode
            except subprocess.TimeoutExpired as error:
                output = error.stdout or b""
                if isinstance(output, bytes): output = output.decode("utf-8", errors="replace")
                output += "\nCLOSE FAIL : application did not close within 30 seconds.\n"
                status = 124
            except OSError as error:
                output = "CLOSE FAIL : moteur impossible à lancer : " + str(error)
                status = 127
            errors = []
            ready = re.search(r"^CLOSE_READY " + re.escape(case) + r" : (\d+) assertions, 0 échec\(s\)\.", output, re.MULTILINE)
            if status != 0: errors.append("code de sortie " + str(status))
            if not ready: errors.append("fermeture réelle non armée")
            if re.search(r"SCRIPT ERROR:|Parse Error:|^ERROR:|CLOSE FAIL|CLOSE_ABORT", output, re.MULTILINE): errors.append("erreur moteur ou assertion")
            external_checks = 0
            try:
                report = json.loads(marker.read_text(encoding="utf-8"))
                data = fixture / "data"
                files = list((data / "profiles").glob("*.json"))
                external_checks += 1
                if len(files) != 1: errors.append("le profil isolé unique n'a pas été conservé")
                profile = json.loads(files[0].read_text(encoding="utf-8"))
                external_checks += 1
                if profile != report["expected_profile"]: errors.append("progression, portefeuille, récompenses ou inventaire modifiés pendant la fermeture")
                actual = read_settings(data / "settings.cfg")
                external_checks += 1
                if actual != report["expected_settings"]: errors.append("réglages persistants différents du choix de fermeture")
                session = json.loads((data / "session.json").read_text(encoding="utf-8"))
                external_checks += 1
                if session.get("last_profile_id") != profile["id"]: errors.append("sélection du profil non conservée")
                external_checks += 1
                if list(data.rglob("*.tmp")): errors.append("document temporaire d'écriture laissé présent")
            except (OSError, ValueError, KeyError, IndexError) as error:
                errors.append("preuve persistante indisponible : " + str(error))
            assertions = (int(ready.group(1)) if ready else 0) + external_checks
            output += "\nCLOSE_EXTERNAL : " + ("documents exacts après sortie réelle" if not errors else "; ".join(errors)) + "\n"
            (logs / ("close_" + case + ".log")).write_text(output, encoding="utf-8")
            results.append({"case": case, "ok": not errors, "assertions": assertions, "exit_code": status, "errors": errors, "log": "close_" + case + ".log"})
            print(f"CLOSE {case} : {assertions} assertions, {'0 échec(s)' if not errors else '; '.join(errors)}.", flush=True)
    summary = {"godot": version, "cases": results, "assertions": sum(item["assertions"] for item in results), "failures": sum(not item["ok"] for item in results), "scope": "four real Godot closes plus external persistent-document checks; no graphical or physical-controller verification"}
    (logs / "close_summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Fermeture réelle : {summary['assertions']} assertions, {summary['failures']} échec(s).")
    return 0 if summary["failures"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
