#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_layout.sh
#  geometry + theme management (adaptive, no external deps)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=layout
#@AF:name=af_layout.sh
#@AF:desc=Geometry, theming, and layout manager (auto-adaptive)
#@AF:version=1.2.0
#@AF:type=core
#@AF:uuid=af_core_layout_003

# --- DEPENDENCIES -----------------------------------------------------------
# shellcheck source=/dev/null
source "$(af_path_resolve module io 2>/dev/null)" 2>/dev/null || true
source "$(af_path_resolve module core 2>/dev/null)" 2>/dev/null || true

# --- FALLBACKS --------------------------------------------------------------
declare -g AF_NO_COLOR="${AF_NO_COLOR:-0}"

[[ "$(declare -F af_io_writeln)" ]] || af_io_writeln() { builtin echo "$*"; }
[[ "$(declare -F af_io_write)" ]]   || af_io_write()   { builtin echo -n "$*"; }

# --- THEME HANDLING ---------------------------------------------------------
__AF_THEME_LAST=""
__AF_THEME_FILE=""

af_layout_load_theme() {
  local theme="${1:-default}"
  [[ "$theme" == "$__AF_THEME_LAST" ]] && return 0
  __AF_THEME_LAST="$theme"

  # prefer external theme loader if present
  if declare -F af_theme_load >/dev/null; then
    af_theme_load "$theme"
    return
  fi

  __AF_THEME_FILE="$(af_path_resolve theme "$theme" 2>/dev/null)"
  af_core_apply_default_theme

  ((AF_NO_COLOR)) && return 0
  [[ ! -f "$__AF_THEME_FILE" ]] && return 0

  local k v
  while IFS='=' read -r k v; do
    k="${k//[[:space:]]/}" v="${v//[[:space:]]/}" v="${v//$'\r'/}"
    [[ -z "$k" || "$k" =~ ^# ]] && continue
    case "$k" in
      FG)     AF_FG="$v" ;;
      BG)     AF_BG="$v" ;;
      BORDER) AF_BORDER="$v" ;;
      ACCENT) AF_ACCENT="$v" ;;
      TEXT)   AF_TEXT="$v" ;;
      *)      AF_EXTRA_THEME["$k"]="$v" ;;
    esac
  done < "$__AF_THEME_FILE"
}

# --- GEOMETRY HANDLING ------------------------------------------------------
# returns: cols rows width height x y   (x,y are 1-based)
af_layout_geometry() {
  local mode="${1:-full}" wp="${2:-100}" hp="${3:-100}"
  local cols rows
  read cols rows <<<"$(af_core_size)"
  ((cols<=0)) && cols=80
  ((rows<=0)) && rows=24

  # defaults (full screen, 1-based origin)
  local w="$cols" h="$rows" x=1 y=1

  case "$mode" in
    full)
      : ;;
    left-half)
      (( w = cols/2, h = rows, x = 1, y = 1 ))
      ;;
    right-half)
      (( w = cols/2, h = rows, x = cols - w + 1, y = 1 ))
      ;;
    top-half)
      (( w = cols, h = rows/2, x = 1, y = 1 ))
      ;;
    bottom-half)
      (( w = cols, h = rows/2, x = 1, y = rows - h + 1 ))
      ;;
    center-box)
      (( w = cols/2, h = rows/2 ))
      (( x = (cols - w)/2 + 1, y = (rows - h)/2 + 1 ))
      ;;
    percent)
      (( w = (cols * wp) / 100, h = (rows * hp) / 100 ))
      (( x = (cols - w)/2 + 1, y = (rows - h)/2 + 1 ))
      ;;
    custom:*)
      # custom:x,y,w,h  (accept either 0- or 1-based user input; normalize to 1-based)
      local geo="${mode#custom:}"
      IFS=',' read -r x y w h <<<"$geo"
      (( x<1 )) && (( x+=1 ))   # if someone passed 0, shift to 1
      (( y<1 )) && (( y+=1 ))
      ;;
  esac

  # sanity clamps
  (( w<1 )) && w=1
  (( h<1 )) && h=1
  (( x<1 )) && x=1
  (( y<1 )) && y=1
  (( x+w-1 > cols )) && (( w = cols - x + 1 ))
  (( y+h-1 > rows )) && (( h = rows - y + 1 ))

  af_io_writeln "$cols $rows $w $h $x $y"
}

# --- COLORIZED LAYOUT EXPORT ------------------------------------------------
# returns: cols rows w h x y FG BG BORDER ACCENT TEXT
af_layout_color() {
  local mode="${1:-full}" theme="${2:-${AF_THEME:-default}}"
  af_layout_load_theme "$theme"
  local c r w h x y
  read c r w h x y <<<"$(af_layout_geometry "$mode")"
  af_io_writeln "$c $r $w $h $x $y ${AF_FG:-250} ${AF_BG:-0} ${AF_BORDER:-240} ${AF_ACCENT:-118} ${AF_TEXT:-250}"
}

# --- INNER BOX CALCULATION --------------------------------------------------
# input: cols rows width height x y pad
# output: x_in y_in w_in h_in
af_layout_inner_box() {
  local _c="$1" _r="$2" _w="$3" _h="$4" _x="$5" _y="$6" pad="${7:-1}"
  ((pad<0)) && pad=0
  local x2=$((_x + pad))
  local y2=$((_y + pad))
  local w2=$((_w - pad*2))
  local h2=$((_h - pad*2))
  ((w2<1)) && w2=1
  ((h2<1)) && h2=1
  af_io_writeln "$x2 $y2 $w2 $h2"
}

# --- TEXT CENTERING ---------------------------------------------------------
af_layout_center_text() {
  local text="$1" mode="${2:-full}"
  local c r w h x y
  read c r w h x y <<<"$(af_layout_geometry "$mode")"
  local tx=$((x + (w - ${#text}) / 2))
  local ty=$((y + h / 2))
  ((tx<1)) && tx=1
  ((ty<1)) && ty=1
  af_core_cursor "$ty" "$tx"
  af_io_write "$text"
}

# ─────────────────────────────────────────────────────────────────────────────
# END MODULE
