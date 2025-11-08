#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_engine.sh
#  runtime engine — panes, scrolling, input loop
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=engine
#@AF:name=af_engine.sh
#@AF:desc=Runtime engine (panes, scrolling, input loop)
#@AF:version=1.2.0
#@AF:type=core
#@AF:uuid=af_core_engine_003

# --- dependencies ------------------------------------------------------------
source "$(af_path_resolve module layout)"
source "$(af_path_resolve module draw)"
source "$(af_path_resolve module term_size)"
source "$(af_path_resolve module term_color)"

# --- io fallback -------------------------------------------------------------
declare -F af_io_write >/dev/null || {
  af_io_write()   { builtin echo -n -- "$*"; }
  af_io_writeln() { builtin echo -- "$*"; }
  af_io_repeat()  { local n="$1" ch="${2:- }"; while ((n-- > 0)); do builtin echo -n "$ch"; done; }
}

# --- state -------------------------------------------------------------------
declare -Ag AF_PANE_CONTENT=()
declare -Ag AF_PANE_SCROLL=()
declare -Ag AF_PANE_LAYOUT=()
declare -Ag AF_PANE_THEME=()
declare -Ag AF_PANE_TITLE=()
declare -a  AF_PANE_ORDER=()

AF_ACTIVE_PANE=""
AF_SCROLL_MODE="page"
__AF_DIRTY=1
__AF_LAST_COLS=0 __AF_LAST_ROWS=0

# --- helpers -----------------------------------------------------------------
af_engine_line_count() {
  local text="$1" count=0
  [[ -z "$text" ]] && { af_io_writeln 0; return; }
  if declare -F mapfile >/dev/null; then
    local -a arr; mapfile -t arr <<<"$text"; count="${#arr[@]}"
  else
    while IFS= read -r _; do ((count++)); done <<<"$text"
  fi
  af_io_writeln "$count"
}

_af_term_size_changed() {
  local cols rows
  read cols rows <<<"$(af_term_size)"
  if (( cols != __AF_LAST_COLS || rows != __AF_LAST_ROWS )); then
    __AF_LAST_COLS="$cols"; __AF_LAST_ROWS="$rows"
    return 0
  fi
  return 1
}

_af_set_dirty() { __AF_DIRTY=1; }

# --- panel registration ------------------------------------------------------
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

af_engine_panel_set_content() {
  local name="$1" content="$2"
  AF_PANE_CONTENT["$name"]="$content"
  local total; total=$(af_engine_line_count "$content")
  local v="${AF_PANE_SCROLL[$name]:-0}"
  (( v >= total )) && AF_PANE_SCROLL["$name"]=$(( total>0 ? total-1 : 0 ))
  _af_set_dirty
}

# --- focus / scrolling -------------------------------------------------------
af_engine_focus_next() {
  local i n="${#AF_PANE_ORDER[@]}"
  for ((i=0;i<n;i++)); do [[ "${AF_PANE_ORDER[$i]}" == "$AF_ACTIVE_PANE" ]] && break; done
  AF_ACTIVE_PANE="${AF_PANE_ORDER[$(((i+1)%n))]}"
  _af_set_dirty
}

af_engine_focus_prev() {
  local i n="${#AF_PANE_ORDER[@]}"
  for ((i=0;i<n;i++)); do [[ "${AF_PANE_ORDER[$i]}" == "$AF_ACTIVE_PANE" ]] && break; done
  AF_ACTIVE_PANE="${AF_PANE_ORDER[$(((i-1+n)%n))]}"
  _af_set_dirty
}

af_engine_toggle_scroll_mode() {
  AF_SCROLL_MODE=$([[ "$AF_SCROLL_MODE" == "page" ]] && echo "line" || echo "page")
}

# --- drawing ---------------------------------------------------------------
af_engine_pane_draw() {
  local n="$1" active="${2:-$AF_ACTIVE_PANE}"
  local c="${AF_PANE_CONTENT[$n]}" l="${AF_PANE_LAYOUT[$n]}" th="${AF_PANE_THEME[$n]}"
  local v="${AF_PANE_SCROLL[$n]}" title="${AF_PANE_TITLE[$n]}"
  read _ _ w h x y _ bg border accent text <<<"$(af_layout_color "$l" "$th")"
  local inner_h=$((h-2)) inner_w=$((w-2))
  ((inner_h<=0||inner_w<=0)) && return

  local border_color="$([[ "$active" == "$n" ]] && echo "$accent" || echo "$border")"
  af_term_color_fg "$border_color"
  af_term_cursor "$y" "$x"; af_io_write "+"
  af_io_repeat $((w-2)) "-"
  af_io_write "+"

  local i
  for ((i=1;i<h-1;i++)); do
    af_term_cursor $((y+i)) "$x"; af_io_write "|"
    af_term_color_bg "$bg"
    af_io_repeat $((w-2)) " "
    af_term_color_reset
    af_term_color_fg "$border_color"
    af_term_cursor $((y+i)) $((x+w-1)); af_io_write "|"
  done

  af_term_cursor $((y+h-1)) "$x"; af_io_write "+"
  af_io_repeat $((w-2)) "-"
  af_io_write "+"

  [[ -n "$title" ]] && {
    local maxlen=$((w-4))
    af_term_cursor "$y" $((x+2))
    af_term_color_fg "$border_color"
    af_io_cut "$title" "$maxlen"
  }

  local -a lines; IFS=$'\n' read -r -a lines <<<"$c"
  local total="${#lines[@]}"
  ((v > total)) && v=0
  local row=0
  af_term_color_fg "$text"; af_term_color_bg "$bg"
  for ((i=v; i<total && row<inner_h; i++)); do
    af_term_cursor $((y+1+row)) $((x+1))
    local line="${lines[$i]:0:inner_w}"
    local pad=$((inner_w - ${#line}))
    af_io_write "$line"
    ((pad>0)) && af_core_repeat "$pad" " "
    ((row++))
  done
  af_term_color_reset
}

af_engine_redraw_all() {
  af_term_clear_screen
  for n in "${AF_PANE_ORDER[@]}"; do af_engine_pane_draw "$n" "$AF_ACTIVE_PANE"; done
  __AF_DIRTY=0
}

# --- scrolling handler -------------------------------------------------------
af_engine_pane_scroll() {
  local n="$1" dir="$2"
  local v="${AF_PANE_SCROLL[$n]}" c="${AF_PANE_CONTENT[$n]}" l="${AF_PANE_LAYOUT[$n]}"
  read _ _ _ h _ _ <<<"$(af_layout_geometry "$l")"
  local step=$(( [[ "$AF_SCROLL_MODE" == "page" ]] && (h-3) || 1 ))
  ((step<1)) && step=1
  local total; total=$(af_engine_line_count "$c")

  case "$dir" in
    up)   ((v-step >= 0)) && v=$((v-step)) || v=0 ;;
    down) ((v+step < total)) && v=$((v+step)) ;;
  esac
  AF_PANE_SCROLL["$n"]=$v
  _af_set_dirty
}

# --- main loop ---------------------------------------------------------------
af_engine_run() {
  local key
  read __AF_LAST_COLS __AF_LAST_ROWS <<<"$(af_term_size)"

  while :; do
    if (( __AF_DIRTY )) || _af_term_size_changed; then
      af_engine_redraw_all
      af_term_cursor 1 2
      af_term_color_fg "${AF_ACCENT:-118}"
      af_io_write "Active: [${AF_ACTIVE_PANE}]  (j/k scroll, TAB switch, p mode, q quit)"
      af_term_color_reset
    fi

    key="$(af_core_read_key)"
    case "$key" in
      "") sleep 0.05 ;;
      Q|ESC) break ;;
      J|DOWN) af_engine_pane_scroll "$AF_ACTIVE_PANE" down ;;
      K|UP) af_engine_pane_scroll "$AF_ACTIVE_PANE" up ;;
      P) af_engine_toggle_scroll_mode; _af_set_dirty ;;
      TAB|RIGHT) af_engine_focus_next ;;
      SHIFT_TAB|LEFT) af_engine_focus_prev ;;
    esac
  done

  af_term_clear_screen
  af_term_show_cursor
}

# ─────────────────────────────────────────────────────────────────────────────
# END MODULE
