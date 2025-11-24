#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_core.sh (v3.1 - Fixes)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=core
#@AF:name=af_core.sh
#@AF:desc=Unified terminal core layer (color, cursor, size, screen)
#@AF:version=3.1.0
#@AF:type=core
#@AF:uuid=af_core_facade_310

# Ensure path + IO are present -----------------------------------------------
if ! declare -F af_io_write >/dev/null 2>&1; then
  if declare -F af_path_resolve >/dev/null 2>&1; then
    src="$(af_path_resolve module io 2>/dev/null)"
    [[ -f "$src" ]] && source "$src"
  fi
fi

# Fallback minimal I/O (in case path/IO not yet loaded)
declare -F af_io_write >/dev/null || {
  af_io_write()   { builtin echo -n -- "$*"; }
  af_io_writeln() { builtin echo -- "$*"; }
  af_io_repeat()  { local n="$1" ch="${2:- }"; while ((n-- > 0)); do builtin echo -n "$ch"; done; }
  af_io_csi()     { af_io_write $'\033['"$1"; }
  af_io_esc()     { af_io_write $'\033'"$1"; }
}

# Load terminal submodules (color / size / input) ----------------------------
for mod in term_color term_size term_input; do
  if declare -F af_path_resolve >/dev/null 2>&1; then
    path="$(af_path_resolve module "$mod" 2>/dev/null)"
    [[ -f "$path" ]] && source "$path"
  fi
done

# Fallback color implementation ----------------------------------------------
if ! declare -F af_term_color_fg >/dev/null 2>&1; then
  af_term_color_reset() { af_io_write $'\033[0m'; }
  af_term_color_fg()    { af_io_write $'\033[38;5;'"$1"'m'; }
  af_term_color_bg()    { af_io_write $'\033[48;5;'"$1"'m'; }
  af_term_bold()        { af_io_write $'\033[1m'; }
  af_term_dim()         { af_io_write $'\033[2m'; }
  af_term_underline()   { af_io_write $'\033[4m'; }
fi

# Fallback size implementation -----------------------------------------------
if ! declare -F af_term_size >/dev/null 2>&1; then
  af_term_size() { af_io_writeln "${COLUMNS:-80} ${LINES:-24}"; }
fi

# PUBLIC API — color ---------------------------------------------------------
af_core_color_reset() { af_term_color_reset "$@"; }
af_core_color_fg()    { af_term_color_fg "$@"; }
af_core_color_bg()    { af_term_color_bg "$@"; }
af_core_bold()        { af_term_bold "$@"; }
af_core_dim()         { af_term_dim "$@"; }
af_core_underline()   { af_term_underline "$@"; }

# PUBLIC API — screen + cursor -----------------------------------------------
af_core_clear()       { af_io_csi "2J"; af_io_csi "H"; }
af_core_hide_cursor() { af_io_csi "?25l"; }
af_core_show_cursor() { af_io_csi "?25h"; }
# FIX: Expose repeat function
af_core_repeat()      { af_io_repeat "$@"; }

af_core_cursor() {
  local row="$1" col="$2"
  (( row < 1 )) && row=1
  (( col < 1 )) && col=1
  af_io_csi "${row};${col}H"
}

# PUBLIC API — size -----------------------------------------------------------
af_core_size() { af_term_size "$@"; }

# THEME defaults --------------------------------------------------------------
af_core_apply_default_theme() {
  AF_FG=250
  AF_BG=0
  AF_BORDER=240
  AF_ACCENT=118
  AF_TEXT=250
}

# Debug info ------------------------------------------------------------------
af_core_info() {
  af_io_writeln "[AF:core] io=$([[ $(declare -F af_io_write) ]] && echo ok), color=$([[ $(declare -F af_term_color_fg) ]] && echo ok), repeat=$([[ $(declare -F af_core_repeat) ]] && echo ok)"
}