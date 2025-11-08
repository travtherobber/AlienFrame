#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_draw.sh
#  drawing + text rendering — boxes, text blocks, progress bars, separators
#  pure af_io / af_core or af_term_*, auto-adaptive, no external deps
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=draw
#@AF:name=af_draw.sh
#@AF:desc=Drawing and text rendering layer (auto-adaptive to term modules)
#@AF:version=2.0.0
#@AF:type=core
#@AF:uuid=af_core_draw_003

# --- DEPENDENCIES ------------------------------------------------------------
# shellcheck source=/dev/null
source "$(af_path_resolve module layout 2>/dev/null)" 2>/dev/null || true

# --- auto-adapt to core / term modules --------------------------------------
if declare -F af_term_color_fg >/dev/null; then
  alias af_core_color_fg=af_term_color_fg
  alias af_core_color_bg=af_term_color_bg
  alias af_core_color_reset=af_term_color_reset
  alias af_core_cursor=af_term_cursor
  alias af_core_repeat=af_io_repeat
fi

# ensure IO available
declare -F af_io_write >/dev/null || {
  af_io_write()   { builtin echo -n -- "$*"; }
  af_io_writeln() { builtin echo -- "$*"; }
  af_io_repeat()  { local n="$1" ch="${2:- }"; while ((n-- > 0)); do builtin echo -n "$ch"; done; }
  af_io_cut()     { builtin echo -n -- "${1:0:${2:-0}}"; }
  af_io_rpad()    { local s="$1" w="$2" ch="${3:- }"; local pad=$((w-${#s})); ((pad>0)) && s+=$(printf "%${pad}s" | tr ' ' "$ch"); builtin echo -n -- "$s"; }
}

# ─────────────────────────────────────────────────────────────────────────────
#  BOX DRAWING
# ─────────────────────────────────────────────────────────────────────────────
af_draw_box() {
  local mode="${1:-center-box}" title="${2:-}" theme="${3:-${AF_THEME:-default}}"
  read _ _ w h x y _ bg border accent _ <<<"$(af_layout_color "$mode" "$theme" 2>/dev/null)"
  ((w < 3 || h < 3)) && return

  af_core_color_fg "$border"
  af_core_cursor "$y" "$x"; af_io_write "+"
  af_core_repeat $((w-2)) "-"
  af_io_write "+"

  local i
  for ((i=1; i<h-1; i++)); do
    af_core_cursor $((y+i)) "$x"; af_io_write "|"
    af_core_color_bg "$bg"
    af_core_repeat $((w-2)) " "
    af_core_color_reset
    af_core_color_fg "$border"
    af_core_cursor $((y+i)) $((x+w-1)); af_io_write "|"
  done

  af_core_cursor $((y+h-1)) "$x"; af_io_write "+"
  af_core_repeat $((w-2)) "-"
  af_io_write "+"

  if [[ -n "$title" ]]; then
    local maxlen=$((w-4))
    af_core_cursor "$y" $((x+2))
    af_core_color_fg "$accent"
    af_io_cut "$title" "$maxlen"
  fi

  af_core_color_reset
}

# ─────────────────────────────────────────────────────────────────────────────
#  TEXT BLOCK RENDERING
# ─────────────────────────────────────────────────────────────────────────────
af_draw_text() {
  local mode="${1:-center-box}"; shift
  local content="${1:-}"; shift || true
  local align="auto" pad=1
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --align) align="$2"; shift 2 ;;
      --pad)   pad="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  read _ _ w h x y _ bg _ _ textc <<<"$(af_layout_color "$mode" 2>/dev/null)"
  local inner_w=$((w - 2 * pad))
  local inner_h=$((h - 2 * pad))
  ((inner_w < 1)) && inner_w=1
  ((inner_h < 1)) && inner_h=1

  local -a lines=()
  while IFS= read -r wrapped; do
    lines+=("$wrapped")
  done < <(af_core_wrap_text "$content" "$inner_w")

  (( ${#lines[@]} == 0 )) && return

  if [[ "$align" == "auto" ]]; then
    (( ${#lines[@]} == 1 )) && align="center" || align="left"
  fi

  af_core_color_fg "$textc"
  af_core_color_bg "$bg"

  local i line off
  for ((i=0; i<inner_h && i<${#lines[@]}; i++)); do
    line="${lines[$i]}"
    case "$align" in
      left)   off=0 ;;
      right)  off=$((inner_w - ${#line})) ;;
      center) off=$(( (inner_w - ${#line}) / 2 )) ;;
      *)      off=0 ;;
    esac
    ((off < 0)) && off=0
    af_core_cursor $((y + pad + i)) $((x + pad + off))
    af_io_rpad "${line:0:inner_w}" "$inner_w" " "
  done

  af_core_color_reset
}

# ─────────────────────────────────────────────────────────────────────────────
#  PROGRESS BAR
# ─────────────────────────────────────────────────────────────────────────────
af_draw_progress() {
  local mode="$1" label="$2" cur="$3" total="$4" theme="${5:-${AF_THEME:-default}}"
  read _ _ w _ x y _ _ border accent text <<<"$(af_layout_color "$mode" "$theme" 2>/dev/null)"
  local bar_w=$((w - ${#label} - 8))
  ((bar_w < 1)) && bar_w=1

  local pct=0
  (( total > 0 )) && pct=$(( (cur * 100) / total ))
  (( pct > 100 )) && pct=100
  local fill=$((bar_w * pct / 100))
  local empty=$((bar_w - fill))

  af_core_cursor "$y" "$x"
  af_core_color_fg "$text"
  af_io_write "$label ["
  af_core_color_fg "$accent"; af_core_repeat "$fill" "█"
  af_core_color_fg "$border"; af_core_repeat "$empty" "░"
  af_core_color_reset
  af_io_write "] "
  af_io_rpad "$pct%" 4 " "
}

# ─────────────────────────────────────────────────────────────────────────────
#  SEPARATOR LINE
# ─────────────────────────────────────────────────────────────────────────────
af_draw_hr() {
  local mode="${1:-full}" char="${2:--}"
  read _ _ w _ x y _ _ border _ _ <<<"$(af_layout_color "$mode" 2>/dev/null)"
  ((w <= 0)) && return
  af_core_color_fg "$border"
  af_core_cursor "$y" "$x"
  af_core_repeat "$w" "$char"
  af_core_color_reset
}

# ─────────────────────────────────────────────────────────────────────────────
# END MODULE
