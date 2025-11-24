#!/usr/bin/env bash
#@AF:module=input
af_input_render() {
  local text="$1" cpos="$2" w="$3" x="$4" y="$5" color="$6" focused="$7"
  local safe_w=$(( w - 2 )); (( safe_w < 1 )) && safe_w=1
  local offset=0; if (( cpos >= safe_w )); then (( offset = cpos - safe_w + 1 )); fi
  local visible="${text:$offset:$safe_w}"
  
  af_core_cursor "$y" "$x"; af_core_color_fg "$color"
  if [[ "$focused" == "1" ]]; then af_io_write "> "; else af_io_write "  "; fi
  af_io_write "$visible"
  
  local rem=$(( safe_w - ${#visible} )); for ((i=0;i<rem;i++)); do af_io_write " "; done
  
  if [[ "$focused" == "1" ]]; then
      local cx=$(( x + 2 + cpos - offset ))
      local char="${text:$cpos:1}"; [[ -z "$char" ]] && char=" "
      af_core_cursor "$y" "$cx"; af_core_color_bg "46"; af_core_color_fg "0"; af_io_write "$char"
  fi
  af_core_color_reset
}
