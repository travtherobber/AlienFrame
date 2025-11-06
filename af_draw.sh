=#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_draw.sh
#  drawing and text rendering layer — boxes, text, progress bars, separators
#  (af_io integrated, printf-free)
# ─────────────────────────────────────────────────────────────────────────────

#@AF:module=draw
#@AF:name=af_draw.sh
#@AF:desc=Drawing and text rendering layer (boxes, bars, separators)
#@AF:version=1.0.0
#@AF:type=core
#@AF:uuid=af_core_draw_001

# --- DEPENDENCIES -----------------------------------------------------------
# shellcheck source=/dev/null
source "$(af_path_resolve module core)"
source "$(af_path_resolve module layout)"

# --- BOX DRAWING ------------------------------------------------------------

# af_draw_box <layout_mode> [title] [theme]
af_draw_box() {
  local mode="${1:-center-box}" title="${2:-}" theme="${3:-${AF_THEME:-default}}"
  read _ _ w h x y _ bg border accent _ <<<"$(af_layout_color "$mode" "$theme")"
  ((w < 3 || h < 3)) && return

  # top border
  af_core_color_fg "$border"
  af_core_cursor "$y" "$x"; af_io_write "+"
  af_core_repeat $((w-2)) "-"
  af_io_write "+"

  # sides + fill
  local i
  for ((i=1; i<h-1; i++)); do
    af_core_cursor $((y+i)) "$x"; af_io_write "|"
    af_core_color_bg "$bg"
    af_core_repeat $((w-2)) " "
    af_core_color_reset
    af_core_color_fg "$border"
    af_core_cursor $((y+i)) $((x+w-1)); af_io_write "|"
  done

  # bottom border
  af_core_cursor $((y+h-1)) "$x"; af_io_write "+"
  af_core_repeat $((w-2)) "-"
  af_io_write "+"

  # title
  if [[ -n "$title" ]]; then
    local maxlen=$((w-4))
    af_core_cursor "$y" $((x+2))
    af_core_color_fg "$accent"
    af_io_cut "$title" "$maxlen"
  fi

  af_core_color_reset
}

# --- TEXT BLOCK RENDERING ---------------------------------------------------

# af_draw_text <layout_mode> <text> [--align left|center|right] [--pad N]
af_draw_text() {
  local mode="${1:-center-box}"; shift
  local content="${1:-}"; shift || true
  local align="auto" pad=1
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --align) align="$2"; shift 2 ;;
      --pad) pad="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  read _ _ w h x y _ bg _ _ textc <<<"$(af_layout_color "$mode")"
  local inner_w=$((w - 2 * pad))
  local inner_h=$((h - 2 * pad))
  ((inner_w < 1)) && inner_w=1
  ((inner_h < 1)) && inner_h=1

  # wrap text into lines
  local -a lines=()
  while IFS= read -r l; do
    while IFS= read -r wrapped; do
      lines+=("$wrapped")
    done < <(af_core_wrap_text "$l" "$inner_w")
  done <<< "$content"

  # pick alignment
  if [[ "$align" == "auto" ]]; then
    (( ${#lines[@]} <= 1 )) && align="center" || align="left"
  fi

  af_core_color_fg "$textc"
  af_core_color_bg "$bg"

  local i line off
  for ((i=0; i<inner_h && i<${#lines[@]}; i++)); do
    line="${lines[$i]}"
    case "$align" in
      left) off=0 ;;
      right) off=$((inner_w - ${#line})) ;;
      center) off=$(( (inner_w - ${#line}) / 2 )) ;;
    esac
    ((off < 0)) && off=0
    af_core_cursor $((y + pad + i)) $((x + pad + off))
    af_io_rpad "${line:0:inner_w}" "$inner_w" " "
  done

  af_core_color_reset
}

# --- PROGRESS BAR -----------------------------------------------------------

# af_draw_progress <layout_mode> <label> <current> <total> [theme]
af_draw_progress() {
  local mode="$1" label="$2" cur="$3" total="$4" theme="${5:-${AF_THEME:-default}}"
  read _ _ w _ x y _ _ border accent text <<<"$(af_layout_color "$mode" "$theme")"
  local bar_w=$((w - ${#label} - 10))
  ((bar_w < 10)) && bar_w=10

  local pct=0
  (( total > 0 )) && pct=$(( (cur * 100) / total ))
  local fill=$((bar_w * pct / 100))
  local empty=$((bar_w - fill))

  af_core_cursor "$y" "$x"
  af_core_color_fg "$text"
  af_io_write "$label ["
  af_core_color_fg "$accent"
  af_core_repeat "$fill" "#"
  af_core_color_fg "$border"
  af_core_repeat "$empty" "-"
  af_core_color_reset
  af_io_write "] "
  af_io_rpad "$pct%" 4 " "
}

# --- SEPARATOR LINE ---------------------------------------------------------

# af_draw_hr <layout_mode> [char]
af_draw_hr() {
  local mode="${1:-full}" char="${2:--}"
  read _ _ w _ x y _ _ border _ _ <<<"$(af_layout_color "$mode")"
  af_core_color_fg "$border"
  af_core_cursor "$y" "$x"
  af_core_repeat "$w" "$char"
  af_core_color_reset
}

# --- END MODULE -------------------------------------------------------------
