#!/usr/bin/env python3
"""Tests isolés des lanceurs Pi ; aucune exécution ARM64 ou installation réelle."""

from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import time
import unittest


PROJECT = Path(__file__).resolve().parents[1]
SCRIPTS = PROJECT / "docs" / "linux"


class LinuxLauncherTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="console-ciel-linux-tests-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.package = self.root / 'Console CIEL été "quote" \\backslash $cash `tick` 100% %f %U'
        self.package.mkdir()
        for name in ("Lancer_Console_CIEL.sh", "Installer_raccourci.sh"):
            shutil.copy2(SCRIPTS / name, self.package / name)
        (self.package / "assets").mkdir()
        (self.package / "assets" / "console.svg").write_text(
            '<svg xmlns="http://www.w3.org/2000/svg"/>', encoding="utf-8"
        )
        self.mock_bin = self.root / "mock-bin"
        self.mock_bin.mkdir()
        self.write_command("uname", 'printf "%s\\n" "${MOCK_MACHINE:-aarch64}"')
        self.write_command("getconf", 'printf "%s\\n" "${MOCK_BITS:-64}"')
        self.record = self.root / "invocation.json"
        self.binary = self.package / "console-ciel.arm64"
        self.binary.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            "from pathlib import Path\n"
            "Path(os.environ['MOCK_RECORD']).write_text(json.dumps({\n"
            " 'args': sys.argv[1:], 'cwd': os.getcwd(),\n"
            " 'data': os.environ.get('XDG_DATA_HOME'),\n"
            " 'config': os.environ.get('XDG_CONFIG_HOME'),\n"
            " 'state': os.environ.get('XDG_STATE_HOME'),\n"
            " 'display': os.environ.get('DISPLAY'),\n"
            " 'wayland': os.environ.get('WAYLAND_DISPLAY')\n"
            "}), encoding='utf-8')\n"
            "sys.exit(int(os.environ.get('MOCK_BINARY_EXIT', '0')))\n",
            encoding="utf-8",
        )
        self.binary.chmod(0o755)
        self.env = os.environ.copy()
        self.env.pop("DISPLAY", None)
        self.env.pop("WAYLAND_DISPLAY", None)
        self.env.update(
            PATH=f"{self.mock_bin}{os.pathsep}{os.environ['PATH']}",
            MOCK_RECORD=str(self.record),
            MOCK_MACHINE="aarch64",
            MOCK_BITS="64",
            DISPLAY=":test",
            XDG_DATA_HOME=str(self.root / "données personnelles"),
            XDG_CONFIG_HOME=str(self.root / "configuration"),
            XDG_STATE_HOME=str(self.root / "état"),
            XDG_CACHE_HOME=str(self.root / "cache"),
        )

    def write_command(self, name: str, body: str) -> None:
        path = self.mock_bin / name
        path.write_text(f"#!/bin/bash\n{body}\n", encoding="utf-8")
        path.chmod(0o755)

    def run_script(self, name: str, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(self.package / name), *args],
            cwd=self.root,
            env=self.env,
            capture_output=True,
            text=True,
            timeout=15,
        )

    def launch(self, *args: str) -> subprocess.CompletedProcess[str]:
        return self.run_script("Lancer_Console_CIEL.sh", *args)

    def install(self) -> subprocess.CompletedProcess[str]:
        return self.run_script("Installer_raccourci.sh")

    @property
    def desktop_file(self) -> Path:
        return Path(self.env["XDG_DATA_HOME"]) / "applications" / "console-ciel.desktop"

    def invocation(self) -> dict:
        return json.loads(self.record.read_text(encoding="utf-8"))

    def test_bash_syntax(self) -> None:
        for name in ("Lancer_Console_CIEL.sh", "Installer_raccourci.sh"):
            with self.subTest(script=name):
                result = subprocess.run(
                    ["bash", "-n", str(SCRIPTS / name)], capture_output=True, text=True
                )
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_rejects_wrong_architectures_before_running_binary(self) -> None:
        for architecture in ("x86_64", "armv7l", "i686"):
            with self.subTest(architecture=architecture):
                self.env["MOCK_MACHINE"] = architecture
                result = self.launch()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("ARM64", result.stderr)
                self.assertIn(architecture, result.stderr)
                self.assertFalse(self.record.exists())

    def test_rejects_32_bit_userspace_on_64_bit_kernel(self) -> None:
        self.env["MOCK_BITS"] = "32"
        result = self.launch()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("32 bits", result.stderr)
        self.assertFalse(self.record.exists())

    def test_missing_binary_has_french_error(self) -> None:
        self.binary.unlink()
        result = self.launch()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Décompressez tout le ZIP", result.stderr)
        self.assertFalse(self.record.exists())

    def test_requires_graphical_session(self) -> None:
        self.env.pop("DISPLAY")
        result = self.launch()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("session de bureau", result.stderr)
        self.assertFalse(self.record.exists())

    def test_x11_launch_preserves_arguments_cwd_and_user_directories(self) -> None:
        arguments = ("--fullscreen", "--", "été avec espaces", '"quote"', "$(touch injection)", "100%", "")
        result = self.launch(*arguments)
        self.assertEqual(result.returncode, 0, result.stderr)
        invocation = self.invocation()
        self.assertEqual(
            invocation["args"],
            ["--rendering-method", "gl_compatibility", "--rendering-driver", "opengl3_es", *arguments],
        )
        self.assertEqual(invocation["cwd"], str(self.package))
        for key, variable in (("data", "XDG_DATA_HOME"), ("config", "XDG_CONFIG_HOME"), ("state", "XDG_STATE_HOME")):
            self.assertEqual(invocation[key], self.env[variable])
        self.assertFalse((self.package / "injection").exists())

    def test_accepts_wayland_without_display(self) -> None:
        self.env.pop("DISPLAY")
        self.env["WAYLAND_DISPLAY"] = "wayland-test"
        result = self.launch()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.invocation()["wayland"], "wayland-test")
        self.assertIsNone(self.invocation()["display"])

    def test_accepts_arm64_alias(self) -> None:
        self.env["MOCK_MACHINE"] = "arm64"
        result = self.launch()
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_restores_only_owner_execution_permission(self) -> None:
        self.binary.chmod(0o640)
        result = self.launch()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(stat.S_IMODE(self.binary.stat().st_mode), 0o740)

    def test_failed_chmod_does_not_launch_binary(self) -> None:
        self.binary.chmod(0o644)
        self.write_command("chmod", "exit 1")
        result = self.launch()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("impossible de rendre", result.stderr)
        self.assertFalse(self.record.exists())

    def test_preserves_binary_exit_status(self) -> None:
        self.env["MOCK_BINARY_EXIT"] = "37"
        result = self.launch()
        self.assertEqual(result.returncode, 37)

    def test_installs_only_user_menu_entry_and_can_update_it(self) -> None:
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stderr)
        desktop = self.desktop_file.read_text(encoding="utf-8")
        self.assertIn("Name=Console CIEL\n", desktop)
        self.assertIn("Terminal=false\n", desktop)
        self.assertIn("Exec=bash ", desktop)
        self.assertEqual(stat.S_IMODE(self.desktop_file.stat().st_mode), 0o644)
        self.assertEqual(list(self.desktop_file.parent.iterdir()), [self.desktop_file])
        self.assertFalse(self.record.exists())
        self.desktop_file.write_text("ancienne entrée", encoding="utf-8")
        updated = self.install()
        self.assertEqual(updated.returncode, 0, updated.stderr)
        self.assertEqual(self.desktop_file.read_text(encoding="utf-8"), desktop)

    def test_installer_rejects_relative_xdg_data_home(self) -> None:
        self.env["XDG_DATA_HOME"] = "dossier-relatif"
        result = self.install()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("chemin absolu", result.stderr)
        self.assertFalse((self.root / "dossier-relatif").exists())

    def test_installer_rejects_missing_launcher_or_icon(self) -> None:
        for missing in ("Lancer_Console_CIEL.sh", "assets/console.svg"):
            with self.subTest(missing=missing):
                file = self.package / missing
                backup = file.read_bytes()
                file.unlink()
                result = self.install()
                file.write_bytes(backup)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(self.desktop_file.exists())

    def test_installer_rejects_newline_in_package_path(self) -> None:
        newline_directory = self.root / "paquet\ninvalide"
        self.package.rename(newline_directory)
        self.package = newline_directory
        result = self.install()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("retour à la ligne", result.stderr)
        self.assertFalse(self.desktop_file.exists())

    @unittest.skipUnless(shutil.which("desktop-file-validate"), "desktop-file-validate absent")
    def test_desktop_entry_passes_freedesktop_validator(self) -> None:
        installed = self.install()
        self.assertEqual(installed.returncode, 0, installed.stderr)
        result = subprocess.run(
            ["desktop-file-validate", str(self.desktop_file)], capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)

    @unittest.skipUnless(shutil.which("gio"), "gio absent")
    def test_real_desktop_parser_launches_paths_with_quotes_spaces_and_percent(self) -> None:
        installed = self.install()
        self.assertEqual(installed.returncode, 0, installed.stderr)
        launched = subprocess.run(
            ["gio", "launch", str(self.desktop_file)],
            cwd=self.root,
            env=self.env,
            capture_output=True,
            text=True,
            timeout=15,
        )
        self.assertEqual(launched.returncode, 0, launched.stderr)
        deadline = time.monotonic() + 5
        while not self.record.exists() and time.monotonic() < deadline:
            time.sleep(0.02)
        self.assertTrue(self.record.exists(), launched.stderr)
        self.assertEqual(self.invocation()["cwd"], str(self.package))
        self.assertEqual(
            self.invocation()["args"],
            ["--rendering-method", "gl_compatibility", "--rendering-driver", "opengl3_es"],
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
