#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
source "$project_dir/tools/godot_checked.sh"
engine_version="$("$godot_bin" --version)"
if [[ "$engine_version" != 4.6.3.stable.* ]]; then
  printf 'Godot 4.6.3 stable requis ; version reçue : %s\n' "$engine_version" >&2
  exit 1
fi
case "${1:-linux}" in
  linux|pc) preset='Linux PC x86_64'; target='linux-x86_64/console-ciel.x86_64' ;;
  arm64|pi) preset='Linux ARM64 Raspberry Pi'; target='linux-arm64/console-ciel.arm64' ;;
  windows) preset='Windows Desktop x86_64'; target='windows-x86_64/Console_CIEL.exe' ;;
  *) printf 'Usage : %s [linux|arm64|windows] [debug|release]\n' "$0" >&2; exit 2 ;;
esac
mode="${2:-release}"
if [[ "$mode" != debug && "$mode" != release ]]; then
  printf 'Mode attendu : debug ou release.\n' >&2
  exit 2
fi
mkdir -p -- "$project_dir/builds/$(dirname -- "$target")"
run_godot_checked "$godot_bin" --headless --path "$project_dir" --import
# Write to a new path: an old executable cannot be mistaken for this export.
export_staging_dir="$(mktemp -d "$project_dir/builds/$(dirname -- "$target")/.export.XXXXXX")"
trap 'rm -rf -- "$export_staging_dir"' EXIT
export_staging_path="$export_staging_dir/$(basename -- "$target")"
run_godot_checked "$godot_bin" --headless --path "$project_dir" "--export-$mode" "$preset" "$export_staging_path"
if [[ ! -s "$export_staging_path" ]]; then
  printf '%s\n' 'Export refusé : aucun exécutable produit.' >&2
  exit 1
fi
for export_file in "$export_staging_dir"/*; do
  mv -- "$export_file" "$project_dir/builds/$(dirname -- "$target")/"
done
printf 'Export créé : %s/builds/%s\n' "$project_dir" "$target"
