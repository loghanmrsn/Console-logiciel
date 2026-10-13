#!/usr/bin/env python3
"""Vérifie l'outil de démo avec Godot réel et des répertoires temporaires.

Python utilise seulement sa bibliothèque standard. Aucun profil normal n'est
lu, créé, modifié ou supprimé. Les outils restent exclus des exports.
"""

from __future__ import annotations

import copy
import json
import os
from pathlib import Path
import subprocess
import tempfile


PROJECT = Path(__file__).resolve().parents[1]
ASSERTIONS = 0


def check(condition: bool, description: str) -> None:
    global ASSERTIONS
    ASSERTIONS += 1
    if not condition:
        raise AssertionError(description)
    print(f"OK  {description}")


def execute(command: list[str], environment: dict[str, str], expected: int = 0) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(command, env=environment, text=True, capture_output=True, timeout=30, cwd=PROJECT)
    diagnostic = result.stdout + result.stderr
    check(result.returncode == expected, f"Commande {Path(command[0]).name} : code {expected} attendu" + (f"\n{diagnostic}" if result.returncode != expected else ""))
    check("SCRIPT ERROR" not in diagnostic and "\nERROR:" not in diagnostic, "Aucune erreur du moteur pendant la préparation")
    return result


def run() -> None:
    with tempfile.TemporaryDirectory(prefix="ciel-demo-check-") as temporary:
        isolated = Path(temporary)
        runtime = isolated / "runtime"
        normal_data = isolated / "normal-data"
        environment = dict(os.environ, XDG_DATA_HOME=str(normal_data), XDG_CONFIG_HOME=str(isolated / "normal-config"), XDG_CACHE_HOME=str(isolated / "normal-cache"))
        launcher = str(PROJECT / "tools/run_demo.sh")

        def prepare(*arguments: str, expected: int = 0) -> subprocess.CompletedProcess[str]:
            return execute([launcher, "--output", str(runtime), "--prepare-only", *arguments], environment, expected)

        manifest = runtime / ".demo_manifest.json"
        profile_directory = runtime / "data/console-ciel/profiles"
        prepare()
        first_id = json.loads(manifest.read_text())["profile_id"]
        fresh = json.loads((profile_directory / f"{first_id}.json").read_text())
        check(fresh["display_name"] == "CIEL Démo" and fresh["wallet"]["points"] == 0 and not fresh["rewarded_missions"], "Profil neuf de démonstration : aucun point distribué")
        prepare()
        check(json.loads(manifest.read_text())["profile_id"] == first_id, "Relance : identifiant inchangé")
        prepare("--prefilled")
        prefilled = json.loads((profile_directory / f"{first_id}.json").read_text())
        check(prefilled["wallet"]["points"] == 50 and prefilled["rewarded_missions"] == ["lighting"] and prefilled["progress"]["completed_missions"] == ["lighting"] and prefilled["progress"]["clues"] == ["badge_note"], "Préremplissage : vraie mission 1, récompense et indice cohérents")
        prepare("--prefilled")
        check(json.loads((profile_directory / f"{first_id}.json").read_text()) == prefilled, "Préremplissage répété : aucune récompense supplémentaire")

        second_profile = copy.deepcopy(fresh)
        second_id = "11111111111111111111111111111111"
        second_profile["id"] = second_id
        second_profile["display_name"] = "Autre profil"
        second_path = profile_directory / f"{second_id}.json"
        second_path.write_text(json.dumps(second_profile))
        second_content = second_path.read_bytes()
        prepare("--reset")
        recreated_id = json.loads(manifest.read_text())["profile_id"]
        recreated_path = profile_directory / f"{recreated_id}.json"
        check(recreated_id != first_id and not (profile_directory / f"{first_id}.json").exists(), "Réinitialisation : seul l'identifiant désigné est remplacé")
        check(second_path.read_bytes() == second_content, "Réinitialisation : second profil conservé octet pour octet")
        check(json.loads(recreated_path.read_text())["wallet"]["points"] == 0, "Réinitialisation : aucun faux crédit")

        valid_manifest = manifest.read_bytes()
        recreated_content = recreated_path.read_bytes()
        manifest.write_text("{ corrupted manifest }")
        prepare("--reset", expected=1)
        check(recreated_path.read_bytes() == recreated_content and second_path.read_bytes() == second_content, "Manifeste invalide : aucun profil modifié")
        manifest.write_bytes(valid_manifest)
        symbolic_profile = profile_directory / "linked.json"
        symbolic_profile.symlink_to(second_path)
        prepare("--reset", expected=2)
        check(second_path.read_bytes() == second_content, "Lien de document refusé avant le lancement Godot")
        symbolic_profile.unlink()

        symbolic_runtime = isolated / "link-runtime"
        symbolic_runtime.symlink_to(runtime, target_is_directory=True)
        execute([launcher, "--output", str(symbolic_runtime), "--reset", "--prepare-only"], environment, 2)
        check(recreated_path.read_bytes() == recreated_content, "Lien de racine refusé sans modifier la cible")
        unmarked_runtime = isolated / "unmarked"
        unmarked_directory = unmarked_runtime / "data/console-ciel/profiles"
        unmarked_directory.mkdir(parents=True)
        unmarked_profile = unmarked_directory / f"{second_id}.json"
        unmarked_profile.write_bytes(second_content)
        execute([launcher, "--output", str(unmarked_runtime), "--prepare-only"], environment, 1)
        check(unmarked_profile.read_bytes() == second_content and not (unmarked_runtime / ".demo_manifest.json").exists(), "Données sans manifeste : aucun remplacement")
        execute([launcher, "--output", str(normal_data / "console-ciel"), "--prepare-only"], environment, 2)
        execute([launcher, "--output", str(isolated / "missing"), "--reset", "--prepare-only"], environment, 1)

        demo_environment = dict(environment, XDG_DATA_HOME=str(runtime / "data"), XDG_CONFIG_HOME=str(runtime / "config"), XDG_CACHE_HOME=str(runtime / "cache"))
        execute([os.environ.get("GODOT_BIN", "godot"), "--headless", "--path", str(PROJECT), "--quit-after", "30"], demo_environment)
        check(json.loads(recreated_path.read_text())["wallet"]["points"] == 0 and second_path.read_bytes() == second_content, "Démarrage normal avec XDG isolés : profils conservés")
    print(f"Résultat préparation démo : {ASSERTIONS} vérifications, 0 échec. Les données temporaires ont été retirées.")


if __name__ == "__main__":
    run()
