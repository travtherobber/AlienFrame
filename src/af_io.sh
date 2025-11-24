#!/usr/bin/env bash
#@AF:module=io
_af_echo_n=1; [[ "$(builtin echo -n x 2>/dev/null; builtin echo .)" == "x." ]] || _af_echo_n=0
af_io_write() { 
  if ((_af_echo_n)); then builtin echo -n "$*"; else builtin echo "$*"; [[ -t 1 ]] && builtin echo -n $'\r'; fi 
}
af_io_writeln() { builtin echo "$*"; }
af_core_cursor() { af_io_write $'\033['"${1};${2}H"; }
af_core_clear()  { af_io_write $'\033[2J\033[H'; }
af_core_color_fg() { af_io_write $'\033[38;5;'"$1"'m'; }
af_core_color_bg() { af_io_write $'\033[48;5;'"$1"'m'; }
af_core_color_reset() { af_io_write $'\033[0m'; }
af_core_hide_cursor() { af_io_write $'\033[?25l'; }
af_core_show_cursor() { af_io_write $'\033[?25h'; }
# Aliases for compatibility
af_io_csi() { af_io_write $'\033['"$1"; }
af_io_esc() { af_io_write $'\033'"$1"; }
