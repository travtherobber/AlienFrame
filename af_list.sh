#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_list.sh (v1.1.0 - Spill Protection)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=list
#@AF:name=af_list.sh
#@AF:desc=Renders scrollable lists inside panels (Safe Clipping)
#@AF:version=1.1.0
#@AF:type=widget
#@AF:uuid=af_widget_list_110

source "$(af_path_resolve module core 2>/dev/null)"   2>/dev/null || true
source "$(af_path_resolve module layout 2>/dev/null)" 2>/dev/null || true

# ─────────────────────────────────────────────────────────────────────────────
# RENDER LIST
# usage: af_list_render DATA_STRING SELECTED_INDEX WIDTH HEIGHT X Y TEXT_COLOR ACCENT_COLOR
# ─────────────────────────────────────────────────────────────────────────────
af_list_render() {
  local data="$1"
  local sel="$2"
  local w="$3"
  local h="$4"
  local x="$5"
  local y="$6"
  local color="$7"
  local accent="$8"

  # Sanity check
  (( w < 1 )) && return

  # 1. Calculate Scroll Offset
  # If selection is below the visible area, shift start_idx down
  local start_idx=0
  if (( sel >= h )); then
    (( start_idx = sel - h + 1 ))
  fi

  local current_idx=0
  local render_idx=0
  local line

  # 2. Define Safe Width
  # We clip text to Width-1 to ensure it NEVER overwrites the right border
  local safe_w=$(( w - 1 ))
  (( safe_w < 1 )) && safe_w=1

  # 3. Iterate Data
  while IFS= read -r line; do
    # Skip items above the scroll window
    if (( current_idx < start_idx )); then
      ((current_idx++))
      continue
    fi

    # Stop if we filled the height
    (( render_idx >= h )) && break

    # Move cursor to start of line
    af_core_cursor $(( y + render_idx )) "$x"
    
    # 4. Sanitize Content
    # Replace Tabs with 2 spaces (fixes alignment glitches)
    line="${line//$'\t'/  }"

    # Clip Content
    local content="${line:0:$safe_w}"

    # Calculate Padding (Fill the rest of the row with spaces)
    local pad_len=$(( w - ${#content} ))
    local padding=""
    if (( pad_len > 0 )); then
       # Simple loop to generate spaces (Pure Bash)
       for ((p=0;p<pad_len;p++)); do padding+=" "; done
    fi

    # 5. Draw Line
    if (( current_idx == sel )); then
      # SELECTED: Highlight Background (Accent Color), Black Text
      af_core_color_bg "$accent"
      af_core_color_fg "0" 
      af_io_write "${content}${padding}"
    else
      # NORMAL: Transparent Background, Theme Text
      af_core_color_bg "0" 
      af_core_color_fg "$color"
      af_io_write "${content}${padding}"
    fi

    ((current_idx++))
    ((render_idx++))
  done <<< "$data"
  
  af_core_color_reset
}