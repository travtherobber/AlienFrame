#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_layout.sh
#  geometry + theme management layer (af_io-based)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=layout
#@AF:name=af_layout.sh
#@AF:desc=Geometry, theming, and layout manager
#@AF:version=1.1.0
#@AF:type=core
#@AF:uuid=af_core_layout_002

# --- DEPENDENCIES -----------------------------------------------------------
# shellcheck source=/dev/null
source "$(af_path_resolve module io)"
# shellcheck source=/dev/null
source "$(af_path_resolve module core)"

# --- THEME HANDLING ---------------------------------------------------------
# cache last theme to avoid re-reading file on each af_layout_color()
__AF_THEME_LAST=""
__AF_THEME_FILE=""

af_layout_load_theme() {
  local theme="${1:-default}"
  [[ "$theme" == "$__AF_THEME_LAST" ]] && return 0

  __AF_THEME_LAST="$theme"
  __AF_THEME_FILE="$(af_path_resolve theme "$theme")"
  af_core_apply_default_theme

  ((AF_NO_COLOR)) && return 0
  [[ ! -f "$__AF_THEME_FILE" ]] && return 0

  local k v
  while IFS='=' read -r k v; do
    [[ -z "$k" || "$k" =~ ^# ]] && continue
    v="${v//[[:space:]]/}"
    case "$k" in
      FG)     AF_FG="$v" ;;
      BG)     AF_BG="$v" ;;
      BORDER) AF_BORDER="$v" ;;
      ACCENT) AF_ACCENT="$v" ;;
      TEXT)   AF_TEXT="$v" ;;
    esac
  done < "$__AF_THEME_FILE"
}

# --- GEOMETRY HANDLING ------------------------------------------------------
# returns: cols rows width height x y
af_layout_geometry() {
  local mode="${1:-full}" wp="${2:-100}" hp="${3:-100}"
  local cols rows
  read cols rows <<<"$(af_core_size)"
  ((cols<=0)) && cols=80
  ((rows<=0)) && rows=24

  local w=$cols h=$rows x=0 y=0
  case "$mode" in
    full) ;;
    left-half)   ((w=cols/2)) ;;
    right-half)  ((w=cols/2,x=cols/2)) ;;
    top-half)    ((h=rows/2)) ;;
    bottom-half) ((h=rows/2,y=rows/2)) ;;
    center-box)  ((w=cols/2,h=rows/2,x=cols/4,y=rows/4)) ;;
    percent)     ((w=cols*wp/100,h=rows*hp/100)) ;;
    custom:*)    # custom:x,y,w,h
      local geo="${mode#custom:}"
      IFS=',' read -r x y w h <<<"$geo"
      ;;
    *) ;;
  esac

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
  local c="$1" r="$2" w="$3" h="$4" x="$5" y="$6" pad="${7:-1}"
  ((pad<0)) && pad=0
  local x2=$((x + pad))
  local y2=$((y + pad))
  local w2=$((w - pad*2))
  local h2=$((h - pad*2))
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

# --- END MODULE -------------------------------------------------------------
