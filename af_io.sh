#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_io.sh (v2)
#  pure built-in I/O layer — foundation for all AlienFrame terminal modules
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=io
#@AF:name=af_io.sh
#@AF:desc=Pure built-in I/O primitives (no printf, no external deps)
#@AF:version=2.0.0
#@AF:type=core
#@AF:uuid=af_core_io_003

AF_IO_VERSION="v2.0.0"

_af_io_echo_supports_n=1
[[ "$(builtin echo -n x 2>/dev/null; builtin echo .)" == "x." ]] || _af_io_echo_supports_n=0

# --- base writers ------------------------------------------------------------
af_io_write() {
  (( $# == 0 )) && return
  if ((_af_io_echo_supports_n)); then
    builtin echo -n -- "$*"
  else
    builtin echo -- "$*"
    [[ -t 1 ]] && builtin echo -n $'\r'
  fi
}

af_io_writeln() { builtin echo -- "$*"; }
af_io_nl()      { builtin echo; }

# --- repeaters / padding -----------------------------------------------------
af_io_repeat() { local n="${1:-0}" ch="${2:- }"; ((n>0)) && while ((n--)); do builtin echo -n "$ch"; done; }
af_io_rpad()   { local s="$1" w="$2" ch="${3:- }"; local pad=$((w-${#s})); ((pad>0)) && af_io_write "$s$(printf "%${pad}s" | tr ' ' "$ch")" || af_io_write "$s"; }

# --- CSI / ESC utilities -----------------------------------------------------
af_io_esc() { af_io_write $'\033'"$1"; }
af_io_csi() { af_io_write $'\033['"$1"; }

# --- cursor & screen ---------------------------------------------------------
af_io_cursor()        { af_io_csi "${1};${2}H"; }
af_io_clear_screen()  { af_io_csi "2J"; af_io_csi "H"; }
af_io_hide_cursor()   { af_io_csi "?25l"; }
af_io_show_cursor()   { af_io_csi "?25h"; }

# --- logging / fd helpers ----------------------------------------------------
af_io_to()   { local fd="$1"; shift; ((_af_io_echo_supports_n)) && eval "builtin echo -n -- \"\$*\" >&$fd" || eval "builtin echo -- \"\$*\" >&$fd"; }
af_io_log()  { af_io_to 2 -- "[LOG] $*$'\n'"; }

# --- END MODULE --------------------------------------------------------------
