#!/usr/bin/env bash
# Ajoute uniquement une entrée au menu du bureau de l’utilisateur courant.
set -eu

fail() {
    printf 'Console CIEL : %s\n' "$1" >&2
    exit 1
}

package_directory="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
launcher="$package_directory/Lancer_Console_CIEL.sh"
icon="$package_directory/assets/console.svg"
[[ -f "$launcher" && -r "$launcher" ]] || fail "Lancer_Console_CIEL.sh est absent ou illisible."
[[ -f "$icon" && -r "$icon" ]] || fail "assets/console.svg est absent ou illisible. Décompressez tout le ZIP."

# Une entrée .desktop tient chaque valeur sur une ligne.
case "$package_directory" in
    *$'\n'*|*$'\r'*) fail "le chemin du paquet ne doit pas contenir de retour à la ligne." ;;
esac

data_directory="${XDG_DATA_HOME:-${HOME:?Le dossier utilisateur HOME est absent.}/.local/share}"
[[ "$data_directory" == /* ]] || fail "XDG_DATA_HOME doit être un chemin absolu."
applications_directory="$data_directory/applications"
mkdir -p -- "$applications_directory" || fail "impossible de créer le dossier des raccourcis utilisateur."
desktop_file="$applications_directory/console-ciel.desktop"
temporary_desktop="$(mktemp "$applications_directory/.console-ciel.desktop.XXXXXX")"
trap 'rm -f -- "$temporary_desktop"' EXIT

# La valeur Exec subit d’abord l’échappement .desktop, puis celui des arguments.
# %% représente un pourcentage littéral, sans code de remplacement du bureau.
desktop_exec_argument() {
    local argument="$1"
    argument="${argument//%/%%}"
    argument="${argument//\\/\\\\}"
    argument="${argument//\"/\\\"}"
    argument="${argument//\`/\\\`}"
    argument="${argument//\$/\\\$}"
    argument="\"$argument\""
    argument="${argument//\\/\\\\}"
    printf '%s' "$argument"
}

desktop_string() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//$'\t'/\\t}"
    value="${value// /\\s}"
    printf '%s' "$value"
}

{
    printf '[Desktop Entry]\n'
    printf 'Type=Application\n'
    printf 'Version=1.0\n'
    printf 'Name=Console CIEL\n'
    printf 'Comment=Enquête éducative et bibliothèque locale\n'
    printf 'Exec=bash %s\n' "$(desktop_exec_argument "$launcher")"
    printf 'TryExec=bash\n'
    printf 'Icon=%s\n' "$(desktop_string "$icon")"
    printf 'Path=%s\n' "$(desktop_string "$package_directory")"
    printf 'Terminal=false\n'
    printf 'Categories=Education;Game;\n'
    printf 'StartupNotify=false\n'
} > "$temporary_desktop"
chmod 0644 -- "$temporary_desktop"
mv -f -- "$temporary_desktop" "$desktop_file"
printf 'Raccourci ajouté au menu du bureau : %s\n' "$desktop_file"
printf 'Gardez ce dossier du programme en place ; relancez ce script après un déplacement.\n'
