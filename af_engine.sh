#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_engine.sh (v4.1 - Fast Scroll Fix)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=engine
#@AF:desc=Panel engine with Content-Only Redraw optimization
#@AF:version=4.1.0
#@AF:type=core

declare -F af_io_write >/dev/null || af_io_write() { echo -n -- "$*"; }

# ─────────────────────────────────────────────────────────────────────────────
# STATE & REGISTRY
# ─────────────────────────────────────────────────────────────────────────────
declare -gA AF_PANELS_BODY AF_PANELS_REGION AF_PANELS_TITLE AF_PANELS_THEME AF_PANELS_TYPE AF_PANELS_SELECT
AF_ENGINE_FOCUS=""
AF_ENGINE_RUNNING=0

# Event Callbacks
AF_CALLBACK_SELECT=""
AF_CALLBACK_KEY=""

# ─────────────────────────────────────────────────────────────────────────────
# PANEL MANAGEMENT
# ─────────────────────────────────────────────────────────────────────────────
af_engine_panel_add() {
  local name="$1" region="$2" title="$3" body="$4" theme="$5" type="${6:-text}"
  AF_PANELS_REGION["$name"]="$region"
  AF_PANELS_TITLE["$name"]="$title"
  AF_PANELS_BODY["$name"]="$body"
  AF_PANELS_THEME["$name"]="$theme"
  AF_PANELS_TYPE["$name"]="$type"
  AF_PANELS_SELECT["$name"]="0"
  [[ -z "$AF_ENGINE_FOCUS" ]] && AF_ENGINE_FOCUS="$name"
}

af_engine_panel_update() {
  local name="$1"
  local new_body="$2"
  AF_PANELS_BODY["$name"]="$new_body"
  if (( AF_ENGINE_RUNNING )); then _af_engine_render_panel "$name"; fi
}

# ─────────────────────────────────────────────────────────────────────────────
# RENDER LOGIC
# ─────────────────────────────────────────────────────────────────────────────
# 1. Full Render (Box + Content) - Used for init and focus change
_af_engine_render_panel() {
  local name="$1"
  local region="${AF_PANELS_REGION[$name]}"
  local title="${AF_PANELS_TITLE[$name]}"
  local theme="${AF_PANELS_THEME[$name]}"
  local highlight=""
  [[ "$name" == "$AF_ENGINE_FOCUS" ]] && highlight="15"

  # Draw Box
  af_draw_box "$region" "$title" "$theme" "$highlight"

  # Draw Content
  _af_engine_render_content_only "$name"
}

# 2. Content Only Render (Optimization) - Used for scrolling
_af_engine_render_content_only() {
  local name="$1"
  local region="${AF_PANELS_REGION[$name]}"
  local theme="${AF_PANELS_THEME[$name]}"
  local text="${AF_PANELS_BODY[$name]}"
  local type="${AF_PANELS_TYPE[$name]}"
  local sel="${AF_PANELS_SELECT[$name]}"

  local C R W H X Y FG BG BORDER ACCENT TEXTCOLOR
  read C R W H X Y FG BG BORDER ACCENT TEXTCOLOR <<<"$(af_layout_color "$region" "$theme")"
  [[ -z "$C" || "$C" == "0" ]] && return

  local inner
  read inner <<<"$(af_layout_inner_box "$C" "$R" "$W" "$H" "$X" "$Y" 1)"
  local IX IY IW IH
  read IX IY IW IH <<<"$inner"

  if [[ "$type" == "list" ]]; then
     af_list_render "$text" "$sel" "$IW" "$IH" "$IX" "$IY" "$TEXTCOLOR" "$ACCENT"
  else
     local line y="$IY"
     while IFS= read -r line; do
       (( y > IY + IH - 1 )) && break
       af_core_cursor "$y" "$IX"
       af_core_color_fg "$TEXTCOLOR"
       af_io_repeat "$IW" " "
       af_core_cursor "$y" "$IX"
       af_io_write "${line:0:$IW}"
       ((y++))
     done <<<"$text"
  fi
  af_core_color_reset
}

af_engine_redraw() {
  af_core_clear
  for name in "${!AF_PANELS_REGION[@]}"; do _af_engine_render_panel "$name"; done
}

# ─────────────────────────────────────────────────────────────────────────────
# INPUT ROUTING
# ─────────────────────────────────────────────────────────────────────────────
af_engine_input() {
  local k="$1"
  local focus="$AF_ENGINE_FOCUS"

  if [[ -n "$AF_CALLBACK_KEY" ]]; then $AF_CALLBACK_KEY "$focus" "$k"; fi

  case "$k" in
    q|Q|ESC) AF_ENGINE_RUNNING=0 ;;
    TAB)
      local keys=("${!AF_PANELS_REGION[@]}")
      local count="${#keys[@]}"
      local i
      for ((i=0;i<count;i++)); do
        if [[ "${keys[$i]}" == "$focus" ]]; then
          AF_ENGINE_FOCUS="${keys[$(((i+1)%count))]}"
          af_engine_redraw # Full redraw needed to move Highlight Border
          break
        fi
      done
      ;;
    UP)
      if [[ "${AF_PANELS_TYPE[$focus]}" == "list" ]]; then
        local curr="${AF_PANELS_SELECT[$focus]}"
        if (( curr > 0 )); then
           AF_PANELS_SELECT[$focus]=$(( curr - 1 ))
           # OPTIMIZATION: Only redraw text, don't touch borders!
           _af_engine_render_content_only "$focus"
        fi
      fi
      ;;
    DOWN)
      if [[ "${AF_PANELS_TYPE[$focus]}" == "list" ]]; then
        local curr="${AF_PANELS_SELECT[$focus]}"
        local max; max=$(echo "${AF_PANELS_BODY[$focus]}" | wc -l)
        if (( curr < max - 1 )); then
           AF_PANELS_SELECT[$focus]=$(( curr + 1 ))
           # OPTIMIZATION: Only redraw text, don't touch borders!
           _af_engine_render_content_only "$focus"
        fi
      fi
      ;;
    ENTER)
      if [[ "${AF_PANELS_TYPE[$focus]}" == "list" && -n "$AF_CALLBACK_SELECT" ]]; then
        local curr="${AF_PANELS_SELECT[$focus]}"
        local item
        item="$(echo "${AF_PANELS_BODY[$focus]}" | sed -n "$((curr + 1))p")"
        $AF_CALLBACK_SELECT "$focus" "$item"
      fi
      ;;
  esac
}

af_engine_run() {
  AF_ENGINE_RUNNING=1
  af_core_hide_cursor
  af_engine_redraw
  while ((AF_ENGINE_RUNNING)); do
    local key
    key="$(af_core_read_key)"
    [[ -n "$key" ]] && af_engine_input "$key"
    sleep 0.016
  done
  af_core_show_cursor
  af_io_writeln "[AF] Exited."
}