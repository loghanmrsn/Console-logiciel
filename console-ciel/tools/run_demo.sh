#!/usr/bin/env bash
# Lanceur de développement ponctuel ; aucun service ni autostart n'est installé.
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
source "$project_dir/tools/godot_checked.sh"
demo_runtime_dir="$project_dir/builds/demo-runtime"
prepare_only=false
prepare_args=()
game_args=()

while (($#)); do
  case "$1" in
    --output)
      if (($# < 2)) || [[ "$2" != /* ]]; then
        printf '%s\n' '--output attend un chemin absolu local.' >&2
        exit 2
      fi
      demo_runtime_dir="$2"
      shift 2
      ;;
    --reset|--prefilled) prepare_args+=("$1"); shift ;;
    --prepare-only) prepare_only=true; shift ;;
    --fullscreen) game_args+=("--fullscreen"); shift ;;
    --help|-h)
      printf 'Usage : %s [--output /racine/isolée] [--reset] [--prefilled] [--prepare-only] [--fullscreen]\n' "$0"
      printf '%s\n' 'Défaut : builds/demo-runtime. Sans --reset, les données de démonstration sont conservées.'
      exit 0
      ;;
    *) printf 'Option inconnue : %s\n' "$1" >&2; exit 2 ;;
  esac
done

# Le moteur écrit son journal dès son démarrage : vérifier avant de changer
# les dossiers XDG, pas uniquement à l'intérieur de prepare_demo.gd.
demo_runtime_dir="$(realpath -ms -- "$demo_runtime_dir")"
if [[ "$demo_runtime_dir" == / || "$demo_runtime_dir" == /tmp || "$demo_runtime_dir" == /workspace || "$demo_runtime_dir" == "$project_dir" ]]; then
  printf '%s\n' 'Choisissez une sous-racine dédiée à la démonstration.' >&2
  exit 2
fi
normal_data_dir="$(realpath -m -- "${XDG_DATA_HOME:-$HOME/.local/share}/console-ciel")"
home_data_dir="$(realpath -m -- "$HOME/.local/share/console-ciel")"
for protected_dir in "$normal_data_dir" "$home_data_dir"; do
  if [[ "$demo_runtime_dir" == "$protected_dir" || "$demo_runtime_dir" == "$protected_dir"/* || "$protected_dir" == "$demo_runtime_dir"/* ]]; then
    printf '%s\n' 'La racine choisie recouvre les sauvegardes normales. Elles sont conservées.' >&2
    exit 2
  fi
done
# -s garde la forme lexicale ; chaque maillon est vérifié ci-dessous.
for candidate_dir in "$demo_runtime_dir" "$demo_runtime_dir/data/console-ciel" "$demo_runtime_dir/config" "$demo_runtime_dir/cache"; do
  checked_dir="$candidate_dir"
  while [[ "$checked_dir" != / && "$checked_dir" != . ]]; do
    if [[ -L "$checked_dir" ]]; then
      printf 'Lien symbolique refusé : %s\n' "$checked_dir" >&2
      exit 2
    fi
    checked_dir="$(dirname -- "$checked_dir")"
  done
done
if [[ -d "$demo_runtime_dir" ]]; then
  symbolic_link="$(find "$demo_runtime_dir" -type l -print -quit)"
  if [[ -n "$symbolic_link" ]]; then
    printf 'Lien symbolique refusé : %s\n' "$symbolic_link" >&2
    exit 2
  fi
fi

engine_version="$("$godot_bin" --version)"
if [[ "$engine_version" != 4.6.3.stable.* ]]; then
  printf 'Godot 4.6.3 stable requis ; version reçue : %s\n' "$engine_version" >&2
  exit 1
fi
export XDG_DATA_HOME="$demo_runtime_dir/data"
export XDG_CONFIG_HOME="$demo_runtime_dir/config"
export XDG_CACHE_HOME="$demo_runtime_dir/cache"
mkdir -p -- "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
# The descriptor survives exec so one demo cannot overwrite another session.
if ! command -v flock >/dev/null 2>&1; then
  printf '%s\n' 'flock (util-linux) est requis pour protéger la session de démonstration.' >&2
  exit 1
fi
exec {demo_lock_fd}>"$demo_runtime_dir/.launch.lock"
if ! flock -n "$demo_lock_fd"; then
  printf '%s\n' 'Une démonstration utilise déjà cette racine. Fermez-la avant de préparer ou relancer.' >&2
  exit 1
fi
run_godot_checked "$godot_bin" --headless --path "$project_dir" --script res://tools/prepare_demo.gd -- --output "$demo_runtime_dir" "${prepare_args[@]}"
if "$prepare_only"; then
  exit 0
fi
exec "$godot_bin" --path "$project_dir" "${game_args[@]}"
