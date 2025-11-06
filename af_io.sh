#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_io.sh
#  builtin-only I/O primitives — zero external deps, zero printf
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=io
#@AF:name=af_io.sh
#@AF:desc=Builtin-only I/O primitives (no printf or external binaries)
#@AF:version=1.1.0
#@AF:type=core
#@AF:uuid=af_core_io_002

# --- feature flags ----------------------------------------------------------
AF_IO_VERSION="${AF_IO_VERSION:-v1.1.0}"
: "${AF_IO_STRICT:=0}"

_af_io_echo_supports_n=1
_af_io_echo_supports_e=1
if [[ "$(builtin echo -n x 2>/dev/null; builtin echo .)" != "x." ]]; then
  _af_io_echo_supports_n=0
fi
if ((AF_IO_STRICT)); then
  _af_io_echo_supports_e=0
elif ! builtin echo -e "" >/dev/null 2>&1; then
  _af_io_echo_supports_e=0
fi

# --- writers ----------------------------------------------------------------
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

# --- escape / CSI -----------------------------------------------------------
af_io_esc() { af_io_write $'\033'"$1"; }
af_io_csi() { af_io_write $'\033['"$1"; }

# --- string helpers ---------------------------------------------------------
af_io_repeat() {
  local n="${1:-0}" ch="${2:- }"
  ((n<=0)) && return
  while ((n--)); do builtin echo -n "$ch"; done
}

af_io_cut() {
  local s="${1:-}" max="${2:-0}"
  ((max<=0)) && return
  af_io_write "${s:0:max}"
}

af_io_rpad() {
  local s="${1:-}" w="${2:-0}" ch="${3:- }"
  local len=${#s}
  ((len>=w)) && { af_io_write "$s"; return; }
  af_io_write "$s"
  af_io_repeat $((w-len)) "$ch"
}

af_io_lpad() {
  local s="${1:-}" w="${2:-0}" ch="${3:- }"
  local len=${#s}
  ((len>=w)) && { af_io_write "$s"; return; }
  af_io_repeat $((w-len)) "$ch"
  af_io_write "$s"
}

af_io_fmt() {
  local fmt="$1"; shift
  local out="$fmt"
  while [[ "$out" == *"%s"* && $# -gt 0 ]]; do
    out="${out/%s/$1}"; shift
  done
  af_io_write "$out"
}

# --- cursor / screen --------------------------------------------------------
af_io_cursor()        { af_io_csi "${1};${2}H"; }
af_io_clear_screen()  { af_io_csi "2J"; af_io_csi "H"; }
af_io_hide_cursor()   { af_io_csi "?25l"; }
af_io_show_cursor()   { af_io_csi "?25h"; }

# --- colors / attrs ---------------------------------------------------------
af_io_fg()        { [[ $1 =~ ^[0-9]+$ ]] && af_io_csi "38;5;${1}m"; }
af_io_bg()        { [[ $1 =~ ^[0-9]+$ ]] && af_io_csi "48;5;${1}m"; }
af_io_bold()      { af_io_csi "1m"; }
af_io_dim()       { af_io_csi "2m"; }
af_io_underline() { af_io_csi "4m"; }
af_io_blink()     { af_io_csi "5m"; }
af_io_reverse()   { af_io_csi "7m"; }
af_io_reset()     { af_io_csi "0m"; }

# --- fd helpers -------------------------------------------------------------
af_io_to() {
  local fd="$1"; shift
  [[ "$1" == "--" ]] && shift
  ((_af_io_echo_supports_n)) \
    && eval "builtin echo -n -- \"\$*\" >&$fd" \
    || eval "builtin echo -- \"\$*\" >&$fd"
}

af_io_log() { af_io_to 2 -- "$*"$'\n'; }
af_io_flush() { :; }

# --- optional core shims ----------------------------------------------------
if [[ -z "${AF_IO_NO_SHIMS:-}" ]]; then
  declare -F af_core_color_reset >/dev/null || af_core_color_reset() { af_io_reset; }
  declare -F af_core_color_fg    >/dev/null || af_core_color_fg()    { af_io_fg "$@"; }
  declare -F af_core_color_bg    >/dev/null || af_core_color_bg()    { af_io_bg "$@"; }
  declare -F af_core_bold        >/dev/null || af_core_bold()        { af_io_bold; }
  declare -F af_core_dim         >/dev/null || af_core_dim()         { af_io_dim; }
  declare -F af_core_underline   >/dev/null || af_core_underline()   { af_io_underline; }
  declare -F af_core_cursor      >/dev/null || af_core_cursor()      { af_io_cursor "$@"; }
  declare -F af_core_clear       >/dev/null || af_core_clear()       { af_io_clear_screen; }
  declare -F af_core_hide_cursor >/dev/null || af_core_hide_cursor() { af_io_hide_cursor; }
  declare -F af_core_show_cursor >/dev/null || af_core_show_cursor() { af_io_show_cursor; }
  declare -F af_core_repeat      >/dev/null || af_core_repeat()      { af_io_repeat "$@"; }
fi

# ───────────────────────────────── END MODULE ───────────────────────────────
