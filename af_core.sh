#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_core.sh
#  unified terminal core façade — re-exports color, size, cursor, and screen
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=core
#@AF:name=af_core.sh
#@AF:desc=High-level core interface combining I/O, color, size, and cursor utils
#@AF:version=2.0.0
#@AF:type=core
#@AF:uuid=af_core_fascade_001

# --- ensure IO layer ---------------------------------------------------------
if ! declare -F af_io_write >/dev/null 2>&1; then
  src="$(af_path_resolve module io 2>/dev/null)"
  [[ -f "$src" ]] && source "$src"
fi

# --- load terminal submodules ------------------------------------------------
for mod in term_color term_size term_input; do
  path="$(af_path_resolve module "$mod" 2>/dev/null)"
  [[ -f "$path" ]] && source "$path"
done

# --- FALLBACKS ---------------------------------------------------------------
# if term_color wasn’t found, patch in safe defaults
if ! declare -F af_term_color_fg >/dev/null 2>&1; then
  af_term_color_reset() { af_io_write $'\033[0m'; }
  af_term_color_fg()    { af_io_write $'\033[38;5;'"$1"m; }
  af_term_color_bg()    { af_io_write $'\033[48;5;'"$1"m; }
  af_term_bold()        { af_io_write $'\033[1m'; }
  af_term_dim()         { af_io_write $'\033[2m'; }
  af_term_underline()   { af_io_write $'\033[4m'; }
fi

# if term_size wasn’t found, fallback to env vars
if ! declare -F af_term_size >/dev/null 2>&1; then
  af_term_size() { echo "${COLUMNS:-80} ${LINES:-24}"; }
fi

# --- PUBLIC API (re-exports) -------------------------------------------------
af_core_color_reset() { af_term_color_reset "$@"; }
af_core_color_fg()    { af_term_color_fg "$@"; }
af_core_color_bg()    { af_term_color_bg "$@"; }
af_core_bold()        { af_term_bold "$@"; }
af_core_dim()         { af_term_dim "$@"; }
af_core_underline()   { af_term_underline "$@"; }

af_core_clear()       { af_io_write $'\033[2J'; }
af_core_cursor()      { af_io_write $'\033['"$1"';'"$2"'H'; }
af_core_hide_cursor() { af_io_write $'\033[?25l'; }
af_core_show_cursor() { af_io_write $'\033[?25h'; }

af_core_size()        { af_term_size "$@"; }

# --- color preset defaults ---------------------------------------------------
af_core_apply_default_theme() {
  AF_FG=250 AF_BG=0 AF_BORDER=240 AF_ACCENT=118 AF_TEXT=250
}

# --- info helper -------------------------------------------------------------
af_core_info() {
  echo "[AF:core] modules: io=$([[ $(declare -F af_io_write) ]] && echo ok || echo missing), " \
       "color=$([[ $(declare -F af_term_color_fg) ]] && echo ok || echo missing), " \
       "size=$([[ $(declare -F af_term_size) ]] && echo ok || echo missing)"
}

# --- CURSOR / SCREEN CONTROL -------------------------------------------------
af_core_clear()       { af_io_write $'\033[2J'; }
af_core_hide_cursor() { af_io_write $'\033[?25l'; }
af_core_show_cursor() { af_io_write $'\033[?25h'; }

af_core_cursor() {
  local row="${1:-1}" col="${2:-1}"
  # make sure both are integers
  row=${row//[^0-9]/}
  col=${col//[^0-9]/}
  printf '\033[%s;%sH' "$row" "$col"
}


# ─────────────────────────────────────────────────────────────────────────────
# END MODULE
# 