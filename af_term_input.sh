#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_term_input.sh
#  keyboard input / event capture — pure builtins, no stty or external deps
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=term_input
#@AF:name=af_term_input.sh
#@AF:desc=Keyboard input / key decoding layer (pure bash builtins)
#@AF:version=1.0.0
#@AF:type=core
#@AF:uuid=af_core_term_input_001

# --- deps -------------------------------------------------------------------
# shellcheck source=/dev/null
source "$(af_path_resolve module io)" 2>/dev/null || true

# --- read one key -----------------------------------------------------------
# returns canonical symbolic key name: UP, DOWN, LEFT, RIGHT, TAB, SHIFT_TAB, ESC, ENTER, SPACE, <char>
af_term_read_key() {
  local k seq
  # ensure tty open for raw read
  exec 3< /dev/tty 2>/dev/null || return 1
  IFS= read -rsn1 -u3 k 2>/dev/null || { exec 3<&-; return 1; }

  # check escape sequences
  if [[ $k == $'\e' ]]; then
    # try reading rest of sequence quickly
    if IFS= read -rsn2 -t 0.0008 -u3 seq 2>/dev/null; then
      case "$seq" in
        "[A") k="UP" ;;
        "[B") k="DOWN" ;;
        "[C") k="RIGHT" ;;
        "[D") k="LEFT" ;;
        "[Z") k="SHIFT_TAB" ;;
        *)    k="ESC" ;;
      esac
    else
      k="ESC"
    fi
  elif [[ $k == $'\t' ]]; then
    k="TAB"
  elif [[ $k == $'\n' ]]; then
    k="ENTER"
  elif [[ $k == ' ' ]]; then
    k="SPACE"
  fi

  exec 3<&-
  printf '%s' "$k"
}

# --- convenience wrappers ---------------------------------------------------
af_core_read_key()  { af_term_read_key; }
af_core_key_name()  { af_term_read_key; }  # alias
af_core_key_wait()  { af_term_read_key; }

# --- END MODULE -------------------------------------------------------------
