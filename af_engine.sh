#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_engine.sh
#  runtime engine — panes, scrolling, input loop (uses af_core/af_layout/af_draw)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=engine
#@AF:name=af_engine.sh
#@AF:desc=Runtime engine — panes, scrolling, and input loop
#@AF:version=1.1.0
#@AF:type=core
#@AF:uuid=af_core_engine_002

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
declare -Ag AF_PANE_TITLE=()    # name -> title text

declare -a  AF_PANE_ORDER=()    # ordered names (for focus cycling)

AF_ACTIVE_PANE=""
AF_SCROLL_MODE="page"           # page | line
__AF_DIRTY=1                    # force initial draw
__AF_LAST_COLS=0 __AF_LAST_ROWS=0

# --- helpers ----------------------------------------------------------------
_af_line_count() {
  # preserves last trailing line; handles empty
  local text="$1" count=0
  if [[ -z "$text" ]]; then
    af_io_writeln 0
    return
  fi
  # use mapfile when available for speed; fallback to while-read
  if declare -F mapfile >/dev/null; then
    local -a __tmp
    mapfile -t __tmp <<<"$text"
    count="${#__tmp[@]}"
  else
    while IFS= read -r _; do ((count++)); done <<<"$text"
  fi
  af_io_writeln "$count"
}

_af_term_size_changed() {
  local cols rows
  read cols rows <<<"$(af_core_size)"
  if (( cols != __AF_LAST_COLS || rows != __AF_LAST_ROWS )); then
    __AF_LAST_COLS="$cols"; __AF_LAST_ROWS="$rows"
    return 0
  fi
  return 1
}

_af_set_dirty() { __AF_DIRTY=1; }

# --- pane registration / updates -------------------------------------------
# af_engine_panel_add <name> <layout_mode> <title> <content> [theme]
af_engine_panel_add() {
  local name="$1" layout="$2" title="$3" content="$4" theme="${5:-${AF_THEME:-default}}"

  AF_PANE_CONTENT["$name"]="$content"
  AF_PANE_SCROLL["$name"]=0
  AF_PANE_LAYOUT["$name"]="$layout"
  AF_PANE_THEME["$name"]="$theme"
  AF_PANE_TITLE["$name"]="$title"

  AF_PANE_ORDER+=("$name")
  [[ -z "$AF_ACTIVE_PANE" ]] && AF_ACTIVE_PANE="$name"
  _af_set_dirty
}

# af_engine_panel_set_content <name> <content>
af_engine_panel_set_content() {
  local name="$1" content="$2"
  AF_PANE_CONTENT["$name"]="$content"
  # clamp scroll to content length
  local total; total=$(_af_line_count "$content")
  local v="${AF_PANE_SCROLL[$name]:-0}"
  (( v >= total )) && AF_PANE_SCROLL["$name"]=$(( total>0 ? total-1 : 0 ))
  _af_set_dirty
}

# --- focus helpers ----------------------------------------------------------
af_engine_focus_next() {
  local i n="${#AF_PANE_ORDER[@]}"
  for ((i=0;i<n;i++)); do
    [[ "${AF_PANE_ORDER[$i]}" == "$AF_ACTIVE_PANE" ]] && break
  done
  AF_ACTIVE_PANE="${AF_PANE_ORDER[$(((i+1)%n))]}"
  _af_set_dirty
}

af_engine_focus_prev() {
  local i n="${#AF_PANE_ORDER[@]}"
  for ((i=0;i<n;i++)); do
    [[ "${AF_PANE_ORDER[$i]}" == "$AF_ACTIVE_PANE" ]] && break
  done
  AF_ACTIVE_PANE="${AF_PANE_ORDER[$(((i-1+n)%n))]}"
  _af_set_dirty
}

af_engine_toggle_scroll_mode() {
  if [[ "$AF_SCROLL_MODE" == "page" ]]; then AF_SCROLL_MODE="line"; else AF_SCROLL_MODE="page"; fi
}

# --- drawing ---------------------------------------------------------------
# af_engine_pane_draw <name> [active_name]
af_engine_pane_draw() {
  local n="$1" active="${2:-$AF_ACTIVE_PANE}"
  local c="${AF_PANE_CONTENT[$n]}" l="${AF_PANE_LAYOUT[$n]}" th="${AF_PANE_THEME[$n]}"
  local v="${AF_PANE_SCROLL[$n]}" title="${AF_PANE_TITLE[$n]}"

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

  # title (store and re-draw every frame for consistency with theme/focus)
  if [[ -n "$title" ]]; then
    local maxlen=$((w-4))
    af_core_cursor "$y" $((x+2))
    af_core_color_fg "$border_color"
    af_io_cut "$title" "$maxlen"
  fi

  # content lines (split without printf)
  local -a lines
  IFS=$'\n' read -r -a lines <<<"$c"
  local total="${#lines[@]}"
  ((v > total)) && v=0

  local row=0
  af_core_color_fg "$text"; af_core_color_bg "$bg"
  for ((i=v; i<total && row<inner_h; i++)); do
    af_core_cursor $((y+1+row)) $((x+1))
    local line="${lines[$i]}"
    # trim + pad
    line="${line:0:inner_w}"
    local pad=$((inner_w - ${#line}))
    af_io_write "$line"
    ((pad>0)) && af_core_repeat "$pad" " "
    ((row++))
  done
  af_core_color_reset
}

af_engine_redraw_all() {
  af_core_clear
  local n
  for n in "${AF_PANE_ORDER[@]}"; do
    af_engine_pane_draw "$n" "$AF_ACTIVE_PANE"
  done
  __AF_DIRTY=0
}

# --- scrolling --------------------------------------------------------------
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
  _af_set_dirty
}

# --- key handling + main loop ----------------------------------------------
af_engine_run() {
  local key

  # snapshot initial size to enable resize detection
  read __AF_LAST_COLS __AF_LAST_ROWS <<<"$(af_core_size)"

  while :; do
    if (( __AF_DIRTY )) || _af_term_size_changed; then
      af_engine_redraw_all
      # header (overlays top line)
      af_core_cursor 1 2
      af_core_color_fg 118
      af_io_write "Active: [${AF_ACTIVE_PANE}]  (j/k scroll, TAB/Shift-TAB switch, p mode, q quit)"
      af_core_color_reset
    fi

    # non-blocking key read
    key="$(af_core_read_key)"
    case "$key" in
      "")   sleep 0.05; continue ;;  # idle tick
      Q|ESC) break ;;
      J|DOWN) af_engine_pane_scroll "$AF_ACTIVE_PANE" down ;;
      K|UP)   af_engine_pane_scroll "$AF_ACTIVE_PANE" up ;;
      P)      af_engine_toggle_scroll_mode; _af_set_dirty ;;
      TAB|RIGHT)       af_engine_focus_next ;;
      SHIFT_TAB|LEFT)  af_engine_focus_prev ;;
      *) : ;;
    esac
  done

  af_core_clear
  af_core_show_cursor
}
