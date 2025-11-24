#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_io.sh (v3.1 - Compat Fix)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=io
#@AF:name=af_io.sh
#@AF:desc=Pure built-in I/O primitives (removed risky double-dash)
#@AF:version=3.1.0
#@AF:type=core
#@AF:uuid=af_core_io_310

AF_IO_VERSION="v3.1.0"

# Detect whether echo supports -n sanely
_af_io_echo_supports_n=1
[[ "$(builtin echo -n x 2>/dev/null; builtin echo .)" == "x." ]] || _af_io_echo_supports_n=0

# Base writers ---------------------------------------------------------------
af_io_write() {
  (( $# == 0 )) && return
  if ((_af_io_echo_supports_n)); then
    # Removed -- to prevent it from being printed on some systems
    builtin echo -n "$*"
  else
    builtin echo "$*"
    [[ -t 1 ]] && builtin echo -n $'\r'
  fi
}

af_io_writeln() { builtin echo "$*"; }
af_io_nl()      { builtin echo; }

# Repeaters / padding --------------------------------------------------------
af_io_repeat() {
  local n="${1:-0}" ch="${2:- }"
  (( n > 0 )) || return
  while (( n-- > 0 )); do
    af_io_write "$ch"
  done
}

af_io_rpad() {
  local s="$1" w="$2" ch="${3:- }"
  local pad=$(( w - ${#s} ))
  if (( pad > 0 )); then
    local fill=""
    while (( pad-- > 0 )); do fill+="$ch"; done
    af_io_write "$s$fill"
  else
    af_io_write "$s"
  fi
}

# CSI / ESC utilities --------------------------------------------------------
af_io_esc() { af_io_write $'\033'"$1"; }
af_io_csi() { af_io_write $'\033['"$1"; }

# Cursor & screen ------------------------------------------------------------
af_io_cursor()       { af_io_csi "${1:-1};${2:-1}H"; }
af_io_clear_screen() { af_io_csi "2J"; af_io_csi "H"; }
af_io_hide_cursor()  { af_io_csi "?25l"; }
af_io_show_cursor()  { af_io_csi "?25h"; }

# Logging / fd helpers -------------------------------------------------------
af_io_to() {
  local fd="$1"; shift
  if ((_af_io_echo_supports_n)); then
    eval "builtin echo -n \"\$*\" >&$fd"
  else
    eval "builtin echo \"\$*\" >&$fd"
  fi
}

af_io_log() { af_io_to 2 "[LOG] $*"; af_io_to 2 $'\n'; }

# END MODULE -----------------------------------------------------------------