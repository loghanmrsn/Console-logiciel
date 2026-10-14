#!/usr/bin/env bash
# Lanceur portable de Console CIEL pour Raspberry Pi OS 64 bits avec bureau.
set -eu

fail() {
    printf 'Console CIEL : %s\n' "$1" >&2
    exit 1
}

package_directory="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
binary="$package_directory/console-ciel.arm64"

machine="$(uname -m)"
case "$machine" in
    aarch64|arm64) ;;
    *) fail "ce paquet nécessite Linux ARM64 (Raspberry Pi OS 64 bits), pas $machine." ;;
esac

if command -v getconf >/dev/null 2>&1; then
    user_bits="$(getconf LONG_BIT 2>/dev/null || true)"
    if [[ -n "$user_bits" && "$user_bits" != 64 ]]; then
        fail "le système utilisateur est en $user_bits bits ; Raspberry Pi OS 64 bits est nécessaire."
    fi
fi

[[ -f "$binary" && -r "$binary" ]] || fail "console-ciel.arm64 est absent ou illisible. Décompressez tout le ZIP."
if [[ ! -x "$binary" ]]; then
    chmod u+x -- "$binary" || fail "impossible de rendre console-ciel.arm64 exécutable dans ce dossier."
fi
[[ -x "$binary" ]] || fail "ce dossier ne permet pas l’exécution ; déplacez le paquet dans un dossier utilisateur exécutable."

if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    fail "ouvrez une session de bureau sur le Raspberry Pi, puis relancez ce script depuis un terminal de ce bureau."
fi

cd -- "$package_directory"
exec "$binary" --rendering-method gl_compatibility --rendering-driver opengl3_es "$@"
