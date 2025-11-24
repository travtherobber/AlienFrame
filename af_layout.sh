#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_layout.sh (v3.2 - Percent Support)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=layout
#@AF:name=af_layout.sh
#@AF:desc=Geometry with smart percentage support in custom layouts
#@AF:version=3.2.0
#@AF:type=core
#@AF:uuid=af_core_layout_320

source "$(af_path_resolve module io   2>/dev/null)" 2>/dev/null || true
source "$(af_path_resolve module core 2>/dev/null)" 2>/dev/null || true

declare -g AF_NO_COLOR="${AF_NO_COLOR:-0}"

# THEME handling -------------------------------------------------------------
__AF_THEME_LAST=""
__AF_THEME_FILE=""

af_layout_load_theme() {
  local theme="${1:-default}"
  [[ "$theme" == "$__AF_THEME_LAST" ]] && return 0
  __AF_THEME_LAST="$theme"
  __AF_THEME_FILE="$(af_path_resolve theme "$theme" 2>/dev/null)"
  af_core_apply_default_theme
  ((AF_NO_COLOR)) && return 0
  [[ ! -f "$__AF_THEME_FILE" ]] && return 0

  local k v
  while IFS='=' read -r k v; do
    k="${k//[[:space:]]/}"; v="${v//[[:space:]]/}"; v="${v//$'\r'/}"
    [[ -z "$k" || "$k" =~ ^# ]] && continue
    case "$k" in
      FG)     AF_FG="$v" ;;
      BG)     AF_BG="$v" ;;
      BORDER) AF_BORDER="$v" ;;
      ACCENT) AF_ACCENT="$v" ;;
      TEXT)   AF_TEXT="$v" ;;
    esac
  done < "$__AF_THEME_FILE"
}

# Helper: Resolve value (10, 50%, or -5)
# $1 = value string, $2 = total dimension (for %)
_af_layout_calc() {
  local val="$1" total="$2"
  if [[ "$val" == *"%" ]]; then
    val="${val%\%}"
    echo $(( (total * val) / 100 ))
  else
    echo "$val"
  fi
}

# GEOMETRY handling ----------------------------------------------------------
af_layout_geometry() {
  local mode="${1:-full}"
  local cols rows
  read cols rows <<<"$(af_core_size)"
  ((cols<=0)) && cols=80
  ((rows<=0)) && rows=24

  local w="$cols" h="$rows" x=1 y=1

  case "$mode" in
    left-half)   (( w = cols / 2, h = rows, x = 1, y = 1 )) ;;
    right-half)  (( w = cols / 2, h = rows, x = cols - w + 1, y = 1 )) ;;
    top-half)    (( w = cols, h = rows / 2, x = 1, y = 1 )) ;;
    bottom-half) (( w = cols, h = rows / 2, x = 1, y = rows - h + 1 )) ;;
    center-box)  (( w = cols / 2, h = rows / 2 )); (( x = (cols - w) / 2 + 1, y = (rows - h) / 2 + 1 )) ;;
    
    custom:*)
      local geo="${mode#custom:}"
      local raw_x raw_y raw_w raw_h
      IFS=',' read -r raw_x raw_y raw_w raw_h <<<"$geo"
      
      # Resolve X and W against Columns
      w="$(_af_layout_calc "$raw_w" "$cols")"
      x="$(_af_layout_calc "$raw_x" "$cols")"
      
      # Resolve Y and H against Rows
      h="$(_af_layout_calc "$raw_h" "$rows")"
      y="$(_af_layout_calc "$raw_y" "$rows")"
      ;;
      
    full|*)      ;;
  esac

  (( w < 1 )) && w=1
  (( h < 1 )) && h=1
  (( x < 1 )) && x=1
  (( y < 1 )) && y=1
  
  # Bounds checking
  (( x > cols )) && x=cols
  (( y > rows )) && y=rows
  (( x + w - 1 > cols )) && (( w = cols - x + 1 ))
  (( y + h - 1 > rows )) && (( h = rows - y + 1 ))

  builtin echo "$cols $rows $w $h $x $y"
}

# COLORIZED layout export ----------------------------------------------------
af_layout_color() {
  local mode="${1:-full}" theme="${2:-${AF_THEME:-default}}"
  af_layout_load_theme "$theme"
  local c r w h x y
  read c r w h x y <<<"$(af_layout_geometry "$mode")"
  builtin echo "$c $r $w $h $x $y ${AF_FG:-250} ${AF_BG:-0} ${AF_BORDER:-240} ${AF_ACCENT:-118} ${AF_TEXT:-250}"
}

# INNER box calc -------------------------------------------------------------
af_layout_inner_box() {
  local _c="$1" _r="$2" _w="$3" _h="$4" _x="$5" _y="$6" pad="${7:-1}"
  ((pad<0)) && pad=0
  local x2=$((_x + pad))
  local y2=$((_y + pad))
  local w2=$((_w - pad*2))
  local h2=$((_h - pad*2))
  ((w2<1)) && w2=1
  ((h2<1)) && h2=1
  builtin echo "$x2 $y2 $w2 $h2"
}

# Center text helper ---------------------------------------------------------
af_layout_center_text() {
  local text="$1" mode="${2:-full}"
  local c r w h x y
  read c r w h x y <<<"$(af_layout_geometry "$mode")"
  local tx=$(( x + (w - ${#text}) / 2 ))
  local ty=$(( y + h / 2 ))
  ((tx<1)) && tx=1
  ((ty<1)) && ty=1
  af_core_cursor "$ty" "$tx"
  af_io_write "$text"
}