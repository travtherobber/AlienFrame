#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_engine.sh
#  minimal panel engine — layout, redraw loop, input dispatch
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=engine
#@AF:name=af_engine.sh
#@AF:desc=Panel engine with redraw loop + input routing (clean v3 base)
#@AF:version=3.0.0
#@AF:type=core
#@AF:uuid=af_core_engine_300

# ─────────────────────────────────────────────────────────────────────────────
# DEPENDENCIES
# ─────────────────────────────────────────────────────────────────────────────
source "$(af_path_resolve module core 2>/dev/null)"   2>/dev/null || true
source "$(af_path_resolve module layout 2>/dev/null)" 2>/dev/null || true
source "$(af_path_resolve module draw 2>/dev/null)"   2>/dev/null || true
source "$(af_path_resolve module term_input 2>/dev/null)" 2>/dev/null || true

# fallback I/O
declare -F af_io_write >/dev/null || af_io_write() { echo -n -- "$*"; }
declare -F af_io_writeln >/dev/null || af_io_writeln() { echo -- "$*"; }

# ─────────────────────────────────────────────────────────────────────────────
# PANEL REGISTRY
# ─────────────────────────────────────────────────────────────────────────────
declare -A AF_PANELS_BODY      # AF_PANELS_BODY[name]   = panel text
declare -A AF_PANELS_REGION    # AF_PANELS_REGION[name] = layout region (e.g. left-half)
declare -A AF_PANELS_TITLE     # title string
declare -A AF_PANELS_THEME     # theme name

AF_ENGINE_FOCUS=""              # currently focused panel

af_engine_panel_add() {
  local name="$1" region="$2" title="$3" body="$4" theme="$5"

  AF_PANELS_REGION["$name"]="$region"
  AF_PANELS_TITLE["$name"]="$title"
  AF_PANELS_BODY["$name"]="$body"
  AF_PANELS_THEME["$name"]="$theme"

  [[ -z "$AF_ENGINE_FOCUS" ]] && AF_ENGINE_FOCUS="$name"
}

# ─────────────────────────────────────────────────────────────────────────────
# RENDER A SINGLE PANEL
# ─────────────────────────────────────────────────────────────────────────────
_af_engine_render_panel() {
  local name="$1"
  local region="${AF_PANELS_REGION[$name]}"
  local title="${AF_PANELS_TITLE[$name]}"
  local theme="${AF_PANELS_THEME[$name]}"
  local text="${AF_PANELS_BODY[$name]}"

  # draw outer box
  af_draw_box "$region" "$title" "$theme"

  # draw text inside
  # inner area calc
  local C R W H X Y
  read C R W H X Y FG BG BORDER ACCENT TEXTCOLOR <<<"$(af_layout_color "$region" "$theme")"

  local inner
  read inner <<<"$(af_layout_inner_box "$C" "$R" "$W" "$H" "$X" "$Y" 1)"
  local IX IY IW IH
  read IX IY IW IH <<<"$inner"

  # render line-by-line, clipped
  local line y="$IY"
  while IFS= read -r line; do
    (( y > IY + IH - 1 )) && break
    af_core_cursor "$y" "$IX"
    af_core_color_fg "$TEXTCOLOR"
    af_io_repeat "$IW" " "     # clear line
    af_core_cursor "$y" "$IX"  # rewrite
    af_io_write "${line:0:$IW}"
    ((y++))
  done <<<"$text"

  af_core_color_reset
}

# ─────────────────────────────────────────────────────────────────────────────
# REDRAW ALL PANELS
# ─────────────────────────────────────────────────────────────────────────────
af_engine_redraw() {
  af_core_clear
  for name in "${!AF_PANELS_REGION[@]}"; do
    _af_engine_render_panel "$name"
  done
}

# ─────────────────────────────────────────────────────────────────────────────
# INPUT HANDLER
# ─────────────────────────────────────────────────────────────────────────────
af_engine_input() {
  local k="$1"

  case "$k" in
    q|Q|ESC)
      AF_ENGINE_RUNNING=0
      return
      ;;
    TAB)
      # cycle focus
      local keys=("${!AF_PANELS_REGION[@]}")
      local count="${#keys[@]}"
      local i
      for ((i=0;i<count;i++)); do
        if [[ "${keys[$i]}" == "$AF_ENGINE_FOCUS" ]]; then
          AF_ENGINE_FOCUS="${keys[$(((i+1)%count))]}"
          break
        fi
      done
      ;;
    UP|DOWN|LEFT|RIGHT)
      # navigation could be added later
      ;;
    *)
      ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN ENGINE LOOP
# ─────────────────────────────────────────────────────────────────────────────
af_engine_run() {
  AF_ENGINE_RUNNING=1
  af_core_hide_cursor

  af_engine_redraw

  while ((AF_ENGINE_RUNNING)); do
    local key
    key="$(af_core_read_key)"
    [[ -n "$key" ]] && af_engine_input "$key"
    sleep 0.016   # ~60 FPS idle
  done

  af_core_show_cursor
  af_io_writeln "[AF:engine] exited."
}

# ─────────────────────────────────────────────────────────────────────────────
# END MODULE
