#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_term_input.sh
#  Keyboard input / key decoding layer (non-blocking, pure bash builtins)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=term_input
#@AF:name=af_term_input.sh
#@AF:desc=Keyboard input / key decoding layer (non-blocking, pure bash builtins)
#@AF:version=1.1.0
#@AF:type=core
#@AF:uuid=af_core_term_input_001

af_term_read_key() {
  local key rest
  # read a single key, non-blocking 50ms timeout
  IFS= read -rsn1 -t 0.05 key 2>/dev/null || return 0

  if [[ $key == $'\033' ]]; then
    IFS= read -rsn2 -t 0.001 rest 2>/dev/null
    case "$rest" in
      "[A")  echo UP ;;
      "[B")  echo DOWN ;;
      "[C")  echo RIGHT ;;
      "[D")  echo LEFT ;;
      "[Z")  echo SHIFT_TAB ;;
      *)     echo ESC ;;
    esac
    return
  fi

  case "$key" in
    q|Q) echo q ;;
    t|T) echo t ;;
    $'\t') echo TAB ;;
    $'\n') echo ENTER ;;
    "") echo "" ;;
    *) echo "$key" ;;
  esac
}

# compatibility shim for core
af_core_read_key() { af_term_read_key "$@"; }
