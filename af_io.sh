#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_io.sh
#  internal I/O primitives — NO printf, NO external binaries
#  (uses only Bash builtins like `echo` and arithmetic/string ops)
# ─────────────────────────────────────────────────────────────────────────────

#@AF:module=io
#@AF:name=af_io.sh
#@AF:desc=Builtin-only I/O primitives (no printf or external binaries)
#@AF:version=1.0.0
#@AF:type=core
#@AF:uuid=af_core_io_001

# --- feature flags ----------------------------------------------------------
AF_IO_VERSION="${AF_IO_VERSION:-v0.2.0}"
: "${AF_IO_STRICT:=0}"   # if set to 1, avoids any echo escapes (keeps raw text)

# Detect whether builtin echo supports -n and -e reliably.
# We avoid -e when AF_IO_STRICT=1.
_af_io_echo_supports_n=1
_af_io_echo_supports_e=1

# shellcheck disable=SC2034
if [[ "$(builtin echo -n x 2>/dev/null; builtin echo .)" != "x." ]]; then
  _af_io_echo_supports_n=0
fi

# shellcheck disable=SC2034
if (( AF_IO_STRICT )); then
  _af_io_echo_supports_e=0
else
  # Best-effort probe: if -e changes “\a” to a bell, it likely works.
  # We don’t actually care about the output; just don’t error.
  if ! builtin echo -e "" >/dev/null 2>&1; then
    _af_io_echo_supports_e=0
  fi
fi

# --- core writers -----------------------------------------------------------

# af_io_write [parts...]
#   Writes text without a trailing newline.
af_io_write() {
  local out=""
  local part
  for part in "$@"; do out+="$part"; done

  if ((_af_io_echo_supports_n)); then
    builtin echo -n -- "$out"
  else
    # Fallback: print then move cursor left one char to hide newline (crude).
    # We avoid this by default; kept for completeness.
    builtin echo -- "$out"
    # If terminal, attempt carriage return to simulate no-NL (imperfect).
    [[ -t 1 ]] && builtin echo -n $'\r'
  fi
}

# af_io_writeln [parts...]
#   Writes text with a trailing newline.
af_io_writeln() {
  local out=""
  local part
  for part in "$@"; do out+="$part"; done
  builtin echo -- "$out"
}

# af_io_nl
#   Writes a single newline.
af_io_nl() { builtin echo; }

# --- escape / control sequence emission ------------------------------------

# af_io_esc <seq>
#   Emits ESC + <seq>. Example: af_io_esc "[2J" (clear screen)
af_io_esc() {
  # Use ANSI C quoting to avoid needing -e
  af_io_write $'\033'"$1"
}

# af_io_csi <seq>
#   Emits Control Sequence Introducer (CSI) "\x1b[" + seq
af_io_csi() {
  af_io_write $'\033['"$1"
}

# --- string helpers ---------------------------------------------------------

# af_io_repeat <count> [char]
#   Emits <char> repeated <count> times (default char: space).
af_io_repeat() {
  local n="${1:-0}" ch="${2:- }"
  (( n <= 0 )) && return 0
  local i out=""
  for ((i=0;i<n;i++)); do out+="$ch"; done
  af_io_write "$out"
}

# af_io_cut <string> <maxlen>
#   Prints at most <maxlen> characters of <string> (no newline).
af_io_cut() {
  local s="${1:-}" max="${2:-0}"
  (( max <= 0 )) && return 0
  af_io_write "${s:0:max}"
}

# af_io_rpad <string> <width> [pad_char]
#   Right-pad string to width with pad_char (default space). No newline.
af_io_rpad() {
  local s="${1:-}" w="${2:-0}" ch="${3:- }"
  local len=${#s}
  (( len >= w )) && { af_io_write "$s"; return 0; }
  local pad=$((w - len))
  af_io_write "$s"
  af_io_repeat "$pad" "$ch"
}

# af_io_lpad <string> <width> [pad_char]
#   Left-pad string to width with pad_char (default space). No newline.
af_io_lpad() {
  local s="${1:-}" w="${2:-0}" ch="${3:- }"
  local len=${#s}
  (( len >= w )) && { af_io_write "$s"; return 0; }
  local pad=$((w - len))
  af_io_repeat "$pad" "$ch"
  af_io_write "$s"
}

# --- tiny formatter ---------------------------------------------------------
# Supports only %s tokens; intentionally minimal to avoid printf.
# Usage: af_io_fmt "Hello %s, id=%s" "$name" "$id"
af_io_fmt() {
  local fmt="$1"; shift
  local out="$fmt" arg
  while [[ "$out" == *"%s"* && $# -gt 0 ]]; do
    arg="$1"; shift
    out="${out/%s/$arg}"
  done
  af_io_write "$out"
}

# --- cursor / screen convenience (wrap CSI) ---------------------------------

# af_io_cursor <row> <col>
af_io_cursor() {
  local r="$1" c="$2"
  af_io_csi "${r};${c}H"
}

af_io_clear_screen()   { af_io_csi "2J"; af_io_csi "H"; }
af_io_hide_cursor()    { af_io_csi "?25l"; }
af_io_show_cursor()    { af_io_csi "?25h"; }

# Colors (256-color mode)
# af_io_fg <idx>  /  af_io_bg <idx>  /  af_io_reset
af_io_fg()           { [[ $1 =~ ^[0-9]+$ ]] && af_io_csi "38;5;${1}m"; }
af_io_bg()           { [[ $1 =~ ^[0-9]+$ ]] && af_io_csi "48;5;${1}m"; }
af_io_bold()         { af_io_csi "1m"; }
af_io_dim()          { af_io_csi "2m"; }
af_io_underline()    { af_io_csi "4m"; }
af_io_reset()        { af_io_csi "0m"; }

# --- file / fd helpers ------------------------------------------------------

# af_io_to <fd> -- <text...>
#   Write to a given numeric file descriptor using builtins only.
#   Example: af_io_to 2 -- "error: " "oops\n"
af_io_to() {
  local fd="$1"; shift
  [[ "$1" == "--" ]] && shift
  local out=""
  local part
  for part in "$@"; do out+="$part"; done
  # Use eval+redirection with builtin echo to avoid external tools.
  if ((_af_io_echo_supports_n)); then
    eval "builtin echo -n -- \"\$out\" >&$fd"
  else
    eval "builtin echo -- \"\$out\" >&$fd"
  fi
}

# af_io_log <message...>   (to stderr)
af_io_log() { af_io_to 2 -- "$*"; af_io_to 2 -- $'\n'; }

# --- no-op flush hook (kept for symmetry) -----------------------------------
af_io_flush() { :; }

# --- export convenience (optional) ------------------------------------------
# If you want to quickly bind these to af_core_* without editing core yet:
if [[ -z "${AF_IO_NO_SHIMS:-}" ]]; then
  # Only define if target isn’t already present
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
