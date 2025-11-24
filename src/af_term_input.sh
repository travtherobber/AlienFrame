#!/usr/bin/env bash
#@AF:module=term_input
af_term_read_key() {
  local key; IFS= read -rsn1 -t 0.001 key 2>/dev/null
  [[ -z "$key" ]] && return
  if [[ $key == $'\033' ]]; then
    local rest; IFS= read -rsn2 -t 0.001 rest 2>/dev/null
    case "$rest" in "[A") echo "UP";; "[B") echo "DOWN";; "[C") echo "RIGHT";; "[D") echo "LEFT";; *) echo "ESC";; esac
    return
  fi
  if [[ "$key" == $'\x0a' || "$key" == $'\x0d' ]]; then echo "ENTER"; return; fi
  if [[ "$key" == $'\x7f' || "$key" == $'\x08' ]]; then echo "BACKSPACE"; return; fi
  if [[ "$key" == $'\t' ]]; then echo "TAB"; return; fi
  echo "$key"
}
af_core_read_key() { af_term_read_key "$@"; }
