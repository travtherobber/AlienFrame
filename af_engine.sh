#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_engine.sh
#  runtime engine — panes, scrolling, input loop (uses af_core/af_layout/af_draw)
# ─────────────────────────────────────────────────────────────────────────────

# --- dependencies -----------------------------------------------------------
# shellcheck source=/dev/null
source "$(af_path_resolve module core)"
# shellcheck source=/dev/null
source "$(af_path_resolve module layout)"
# shellcheck source=/dev/null
source "$(af_path_resolve module draw)"

# optional IO layer shim (fallback for standalone testing)
if ! declare -F af_io_write >/dev/null; then
  af_io_write()   { builtin echo -n "$*"; }
  af_io_writeln() { builtin echo "$*"; }
  af_io_repeat()  { local n="$1" ch="${2:- }"; local out=""; for((i=0;i<n;i++));do out+="$ch";done; af_io_write "$out"; }
fi

# --- state ------------------------------------------------------------------
declare -Ag AF_PANE_CONTENT=()  # name -> text blob
declare -Ag AF_PANE_SCROLL=()   # name -> offset
declare -Ag AF_PANE_LAYOUT=()   # name -> layout token
declare -Ag AF_PANE_THEME=()    # name -> theme token

AF_ACTIVE_PANE=""
AF_SCROLL_MODE="page"           # page | line

# --- pane registration ------------------------------------------------------

# af_engine_panel_add <name> <layout_mode> <title> <content> [theme]
af_engine_panel_add() {
  local name="$1" layout="$2" title="$3" content="$4" theme="${5:-${AF_THEME:-default}}"

  AF_PANE_CONTENT["$name"]="$content"
  AF_PANE_SCROLL["$name"]=0
  AF_PANE_LAYOUT["$name"]="$layout"
  AF_PANE_THEME["$name"]="$theme"

  [[ -z "$AF_ACTIVE_PANE" ]] && AF_ACTIVE_PANE="$name"

  af_draw_box "$layout" "$title" "$theme"
  af_engine_pane_draw "$name"
}

# --- helpers ----------------------------------------------------------------

_af_line_count() {
  local text="$1" count=0
  while IFS= read -r _; do ((count++)); done <<<"$text"
  af_io_writeln "$count"
}

# af_engine_pane_draw <name> [active_name]
af_engine_pane_draw() {
  local n="$1" active="${2:-$AF_ACTIVE_PANE}"
  local c="${AF_PANE_CONTENT[$n]}" l="${AF_PANE_LAYOUT[$n]}" th="${AF_PANE_THEME[$n]}"
  local v="${AF_PANE_SCROLL[$n]}"

  # geometry + colors
  read _ _ w h x y _ bg border accent text <<<"$(af_layout_color "$l" "$th")"
  local inner_h=$((h-2)) inner_w=$((w-2))
  ((inner_h<=0 || inner_w<=0)) && return

  # border color by focus
  local border_color="$border"
  [[ "$active" == "$n" ]] && border_color="$accent"

  # border + background
  af_core_color_fg "$border_color"
  af_core_cursor "$y" "$x"; af_io_write "+"
  af_core_repeat $((w-2)) "-"
  af_io_write "+"

  local i
  for ((i=1;i<h-1;i++)); do
    af_core_cursor $((y+i)) "$x"; af_io_write "|"
    af_core_color_bg "$bg"
    af_core_repeat $((w-2)) " "
    af_core_color_reset
    af_core_color_fg "$border_color"
    af_core_cursor $((y+i)) $((x+w-1)); af_io_write "|"
  done

  af_core_cursor $((y+h-1)) "$x"; af_io_write "+"
  af_core_repeat $((w-2)) "-"
  af_io_write "+"

  # content lines (no printf, pure bash split)
  IFS=$'\n' read -r -a lines <<<"$c"
  local total="${#lines[@]}"
  ((v > total)) && v=0

  local row=0
  af_core_color_fg "$text"; af_core_color_bg "$bg"
  for ((i=v; i<total && row<inner_h; i++)); do
    af_core_cursor $((y+1+row)) $((x+1))
    local line="${lines[$i]:0:inner_w}"
    local pad=$((inner_w - ${#line}))
    af_io_write "$line"
    ((pad>0)) && af_core_repeat "$pad" " "
    ((row++))
  done
  af_core_color_reset
}

# af_engine_pane_scroll <name> <up|down>
af_engine_pane_scroll() {
  local n="$1" dir="$2"
  local v="${AF_PANE_SCROLL[$n]}"
  local c="${AF_PANE_CONTENT[$n]}" l="${AF_PANE_LAYOUT[$n]}"
  read _ _ _ h _ _ <<<"$(af_layout_geometry "$l")"
  local step; [[ "$AF_SCROLL_MODE" == "page" ]] && step=$((h-3)) || step=1
  (( step < 1 )) && step=1
  local total; total=$(_af_line_count "$c")

  case "$dir" in
    up)   ((v-step >= 0)) && v=$((v-step)) || v=0 ;;
    down) ((v+step < total)) && v=$((v+step)) ;;
  esac
  AF_PANE_SCROLL["$n"]=$v
}

# --- redraw all -------------------------------------------------------------
af_engine_redraw_all() {
  af_core_clear
  local n
  for n in "${!AF_PANE_CONTENT[@]}"; do
    af_engine_pane_draw "$n" "$AF_ACTIVE_PANE"
  done
}

# --- key handling + main loop ----------------------------------------------
af_engine_run() {
  local key
  while true; do
    af_engine_redraw_all

    # header
    af_core_cursor 1 2
    af_core_color_fg 118
    af_io_write "Active: [${AF_ACTIVE_PANE}]  (j/k scroll, TAB switch, p mode, q quit)"
    af_core_color_reset

    key="$(af_core_read_key)"
    case "$key" in
      Q|ESC) break ;;
      J|DOWN) af_engine_pane_scroll "$AF_ACTIVE_PANE" down ;;
      K|UP)   af_engine_pane_scroll "$AF_ACTIVE_PANE" up ;;
      P) [[ "$AF_SCROLL_MODE" == "page" ]] && AF_SCROLL_MODE="line" || AF_SCROLL_MODE="page" ;;
      TAB|RIGHT)
        if [[ "$AF_ACTIVE_PANE" == left ]]; then AF_ACTIVE_PANE="right"; else AF_ACTIVE_PANE="left"; fi ;;
      SHIFT_TAB|LEFT)
        if [[ "$AF_ACTIVE_PANE" == right ]]; then AF_ACTIVE_PANE="left"; else AF_ACTIVE_PANE="right"; fi ;;
    esac
  done

  af_core_clear
  af_core_show_cursor
}
