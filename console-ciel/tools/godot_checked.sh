#!/usr/bin/env bash
# Helpers for the project tools, never configuration supplied by a player.
run_godot_checked() {
  local checked_log checked_status=0
  checked_log="$(mktemp -t ciel-godot-check.XXXXXX)" || return 1
  if "$@" >"$checked_log" 2>&1; then
    checked_status=0
  else
    checked_status=$?
  fi
  if grep -Eq 'SCRIPT ERROR:|Parse Error:|^ERROR:' "$checked_log"; then
    if [[ "$checked_status" == 0 ]]; then checked_status=1; fi
  fi
  cat -- "$checked_log"
  rm -f -- "$checked_log"
  return "$checked_status"
}
