#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_draw.sh
#  drawing + text rendering — boxes, bars, separators
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=draw
#@AF:name=af_draw.sh
#@AF:desc=Drawing and text rendering layer (af_io / af_core native)
#@AF:version=2.1.4
#@AF:type=core
#@AF:uuid=af_core_draw_005

# --- DEPENDENCIES ------------------------------------------------------------
source "$(af_path_resolve module layout 2>/dev/null)" 2>/dev/null || true

# fallback I/O primitives -----------------------------------------------------
declare -F af_io_write >/dev/null || {
  af_io_write()   { printf '%s' "$*"; }
  af_io_writeln() { printf '%s\n' "$*"; }
  af_io_repeat()  { local n="$1" ch="${2:- }"; while (( n-- > 0 )); do printf '%s' "$ch"; done; }
}

# ensure repeat + cursor primitives ------------------------------------------
declare -F af_core_repeat >/dev/null || af_core_repeat() { af_io_repeat "$@"; }
declare -F af_core_cursor >/dev/null || af_core_cursor() { printf '\033[%s;%sH' "${1:-1}" "${2:-1}"; }

# ─────────────────────────────────────────────────────────────────────────────
# BOX DRAWING
# ─────────────────────────────────────────────────────────────────────────────
af_draw_box() {
  local region="${1:-center-box}" title="${2:-}" theme="${3:-${AF_THEME:-default}}"

  read _ _ w h x y <<<"$(af_layout_geometry "$region")"
  read _ _ _ _ _ _ FG BG BORDER ACCENT TEXT <<<"$(af_layout_color "$region" "$theme")"
  (( w < 4 || h < 3 )) && return 0

  local tl="┌" tr="┐" bl="└" br="┘" hz="─" vt="│"
  af_core_color_fg "$BORDER"

  # top border
  af_core_cursor "$y" "$x"
  af_io_write "$tl"
  af_core_repeat $(( w - 2 )) "$hz"
  af_io_write "$tr"

  # sides
  local i
  for (( i=1; i<h-1; i++ )); do
      af_core_cursor "$(( y + i ))" "$x"
af_io_write "$vt"
af_core_cursor "$(( y + i ))" "$(( x + w - 1 ))"
af_io_write "$vt"
  done

  # bottom border
  af_core_cursor $((y + h - 1)) "$x"
  af_io_write "$bl"
  af_core_repeat $(( w - 2 )) "$hz"
  af_io_write "$br"

  # title
  if [[ -n "$title" ]]; then
    local maxlen=$(( w - 4 ))
    af_core_cursor "$y" $((x + 2))
    af_core_color_fg "$ACCENT"
    af_io_write "[${title:0:$maxlen}]"
  fi

  af_core_color_reset
}

# ─────────────────────────────────────────────────────────────────────────────
# HORIZONTAL RULE
# ─────────────────────────────────────────────────────────────────────────────
af_draw_hr() {
  local region="${1:-full}" char="${2:--}"
  read _ _ w _ x y _ _ border _ _ <<<"$(af_layout_color "$region" 2>/dev/null)"
  (( w <= 0 )) && return
  af_core_color_fg "$border"
  af_core_cursor "$y" "$x"
  af_core_repeat "$w" "$char"
  af_core_color_reset
}

# ─────────────────────────────────────────────────────────────────────────────
# PROGRESS BAR
# ─────────────────────────────────────────────────────────────────────────────
af_draw_progress() {
  local region="${1:-center-box}" label="${2:-Progress}" cur="${3:-0}" total="${4:-100}" theme="${5:-${AF_THEME:-default}}"
  read _ _ w _ x y _ _ border accent text <<<"$(af_layout_color "$region" "$theme" 2>/dev/null)"
  local bar_w=$(( w - ${#label} - 8 ))
  (( bar_w < 1 )) && bar_w=1

  local pct=0
  (( total > 0 )) && pct=$(( (cur * 100) / total ))
  (( pct > 100 )) && pct=100

  local fill=$(( bar_w * pct / 100 ))
  local empty=$(( bar_w - fill ))

  af_core_cursor "$y" "$x"
  af_core_color_fg "$text"
  af_io_write "$label ["
  af_core_color_fg "$accent"; af_core_repeat "$fill" "█"
  af_core_color_fg "$border"; af_core_repeat "$empty" "░"
  af_core_color_reset
  af_io_write "] ${pct}%"
}

# ─────────────────────────────────────────────────────────────────────────────
# END MODULE
