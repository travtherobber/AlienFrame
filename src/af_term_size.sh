#!/usr/bin/env bash
#@AF:module=term_size
af_term_size() {
  local cols=80 rows=24
  if command -v tput >/dev/null 2>&1; then
      local t_c=$(tput cols); local t_r=$(tput lines)
      [[ "$t_c" =~ ^[0-9]+$ ]] && cols=$t_c
      [[ "$t_r" =~ ^[0-9]+$ ]] && rows=$t_r
  fi
  echo "$cols $rows"
}
af_core_size() { af_term_size; }
