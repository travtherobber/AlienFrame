#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_term_input.sh (v3.2 - Robust Input)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=term_input
#@AF:name=af_term_input.sh
#@AF:desc=Keyboard input decoding (Enter key fix)
#@AF:version=3.2.0
#@AF:type=core
#@AF:uuid=af_core_term_input_320

af_term_read_key() {
  local key rest
  # Read 1 byte
  IFS= read -rsn1 -t 0.05 key 2>/dev/null || return 0

  # 1. Handle Escape Sequences (Arrows, Shift-Tab)
  if [[ $key == $'\033' ]]; then
    IFS= read -rsn2 -t 0.001 rest 2>/dev/null
    case "$rest" in
      "[A") echo UP ;;
      "[B") echo DOWN ;;
      "[C") echo RIGHT ;;
      "[D") echo LEFT ;;
      "[Z") echo SHIFT_TAB ;;
      *)    echo ESC ;;
    esac
    return
  fi

  # 2. Handle ENTER (The Fix)
  # Check for Hex 0A (Line Feed), 0D (Carriage Return), or empty (sometimes read behavior)
  if [[ "$key" == $'\x0a' || "$key" == $'\x0d' || "$key" == "" ]]; then
    echo "ENTER"
    return
  fi

  # 3. Handle Other Keys
  case "$key" in
    $'\t') echo TAB ;;
    $'\x7f') echo BACKSPACE ;; # ASCII DEL
    $'\x08') echo BACKSPACE ;; # Ctrl+H
    *)       echo "$key" ;;
  esac
}

af_core_read_key() { af_term_read_key "$@"; }