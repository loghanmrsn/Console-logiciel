"""Shared checks for test subprocess diagnostics; no application dependency."""
import re


def unexpected_engine_errors(output: str, intentional_config_corruption: bool = False) -> list[str]:
    errors = []
    for line in output.splitlines():
        if not line.startswith('ERROR:'):
            continue
        # These two suites deliberately corrupt only their isolated settings.cfg.
        if intentional_config_corruption and re.match(
                r'ERROR: ConfigFile parse error at user://tests/(?:run_|stability_)[^/]+/.*settings\.cfg(?:\.bak)?:', line):
            continue
        errors.append(line)
    return errors
