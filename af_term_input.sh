#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_term_input.sh
#  Keyboard input / key decoding layer (non-blocking, pure bash builtins)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=term_input
#@AF:name=af_term_input.sh
#@AF:desc=Keyboard input / key decoding layer (non-blocking, pure bash builtins)
#@AF:version=3.0.0
#@AF:type=core
#@AF:uuid=af_core_term_input_300

af_term_read_key() {
  local key rest
  IFS= read -rsn1 -t 0.05 key 2>/dev/null || return 0

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

  case "$key" in
    $'\t') echo TAB ;;
    $'\n') echo ENTER ;;
    *)     echo "$key" ;;
  esac
}

af_core_read_key() { af_term_read_key "$@"; }
