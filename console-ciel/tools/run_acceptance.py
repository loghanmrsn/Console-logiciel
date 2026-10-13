#!/usr/bin/env python3
"""Run native Godot acceptance tests and three genuine persistence relaunches.

No external dependency, graphical display or user's profiles required. Fixture
and runtime homes live in a temporary directory removed after the run. Native
Godot script errors count as failures even when the engine returns exit code 0.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from test_support import unexpected_engine_errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=shutil.which("godot") or "godot")
    parser.add_argument("--log-dir", type=Path, default=Path("tests/stability_results"))
    parser.add_argument("--process-only", action="store_true")
    parser.add_argument("--timeout", type=int, default=600, help="Maximum seconds per Godot test process (default: 600).")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    logs = (project / args.log_dir).resolve() if not args.log_dir.is_absolute() else args.log_dir
    logs.mkdir(parents=True, exist_ok=True)
    failed: list[str] = []
    results: list[dict] = []
    engine_version = "unknown"
    with tempfile.TemporaryDirectory(prefix="ciel-acceptance-") as temporary:
        runtime = Path(temporary)
        (runtime / "acceptance_fixture.json").write_text(json.dumps({
            "purpose": "CIEL isolated process acceptance", "schema_version": 1,
        }), encoding="utf-8")
        environment = os.environ.copy()
        for variable, folder in (("XDG_DATA_HOME", "xdg-data"), ("XDG_CONFIG_HOME", "xdg-config"), ("XDG_CACHE_HOME", "xdg-cache")):
            environment[variable] = str(runtime / folder)
        try:
            engine_version = subprocess.check_output([args.godot, "--version"], cwd=project, env=environment, text=True, timeout=15).strip()
        except (OSError, subprocess.SubprocessError) as error:
            print(f"Version Godot impossible à lire : {error}", file=sys.stderr)
            return 1
        if not engine_version.startswith("4.6.3.stable."):
            print(f"Godot 4.6.3 requis pour cette recette ; version reçue : {engine_version}", file=sys.stderr)
            return 1
        print(f"Godot : {engine_version}", flush=True)
        jobs: list[tuple[str, str, list[str]]] = []
        if not args.process_only:
            jobs += [
                ("business", "tests/run_tests.gd", []),
                ("investigation", "tests/investigation_tests.gd", []),
                ("controllers", "tests/controller_tests.gd", []),
                ("audit_regressions", "tests/audit_regressions.gd", []),
                ("audit_validation", "tests/audit_validation.gd", []),
                ("native_ui", "tests/ui_smoke.gd", []),
                ("stability", "tests/stability_tests.gd", []),
            ]
        jobs += [(f"persistence_{stage}", "tests/process_persistence.gd", ["--stage", stage, "--test-data-root", temporary]) for stage in ("write", "read_replay", "read_final")]
        for name, script, user_args in jobs:
            command = [args.godot, "--headless", "--path", str(project), "--script", f"res://{script}"]
            if user_args:
                command += ["--", *user_args]
            print(f"Exécution : {name}", flush=True)
            try:
                result = subprocess.run(command, cwd=project, env=environment, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=args.timeout)
                output = result.stdout
                status = result.returncode
            except (subprocess.TimeoutExpired, OSError) as error:
                partial = getattr(error, "stdout", "") or ""
                if isinstance(partial, bytes):
                    partial = partial.decode("utf-8", errors="replace")
                output = partial + "\n" + str(error)
                status = 124
            bad_log = bool(unexpected_engine_errors(output, name in ("business", "stability"))) or bool(re.search(r"(?:SCRIPT ERROR:|Parse Error:|^[ÉE]CHEC(?:\s+UI)?\s*:|\b[1-9]\d* échec\(s\))", output, re.MULTILINE))
            summary_prefix = {
                "business": "Résultat :",
                "investigation": "Résultat enquête :",
                "native_ui": "UI :",
                "controllers": "CONTROLLERS :",
                "audit_regressions": "AUDIT_REGRESSIONS :",
                "audit_validation": "AUDIT_VALIDATION :",
                "stability": "STABILITY :",
            }.get(name, "PROCESS_PERSISTENCE " + name.removeprefix("persistence_") + " :")
            finished = bool(re.search(r"^" + re.escape(summary_prefix) + r" \d+ assertions, 0 échec\(s\)\.", output, re.MULTILINE))
            successful = status == 0 and not bad_log and finished
            if status == 0 and not finished:
                output += "\nACCEPTANCE ERROR: final summary missing; process may have quit before completing tests.\n"
            (logs / f"{name}.log").write_text(output, encoding="utf-8")
            print(output.rstrip(), flush=True)
            counts = re.findall(r"(\d+) assertions", output)
            assertion_count = int(counts[-1]) if counts else 0
            results.append({"name": name, "ok": successful, "exit_code": status, "completed": finished, "assertions": assertion_count, "log": f"{name}.log"})
            if not successful:
                failed.append(name)
                if name.startswith("persistence_"):
                    # The next stage must never consume an incomplete fixture.
                    break
    summary = {"tested_at_utc": datetime.now(timezone.utc).isoformat(), "godot": args.godot, "engine_version": engine_version, "assertions": sum(item["assertions"] for item in results), "results": results, "failures": failed, "notes": ["Headless: no visual, physical controller, fullscreen, audio listening or Raspberry Pi performance claim.", "Input events and controller hotplug test hooks are explicitly synthetic.", "Three persistence stages execute in distinct OS processes using one marked temporary fixture."]}
    (logs / "summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("Recette : " + ("réussie" if not failed else "échecs : " + ", ".join(failed)))
    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main())
