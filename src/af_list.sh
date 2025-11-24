#!/usr/bin/env bash
#@AF:module=list
af_list_render() {
  local data="$1" sel="$2" w="$3" h="$4" x="$5" y="$6" color="$7"
  local idx=0 render_idx=0 start_idx=0
  if (( sel >= h )); then (( start_idx = sel - h + 1 )); fi
  local safe_w=$(( w - 1 ))
  
  while IFS= read -r line; do
    if (( idx < start_idx )); then ((idx++)); continue; fi
    (( render_idx >= h )) && break
    
    af_core_cursor $((y+render_idx)) "$x"
    local content="${line:0:$safe_w}"
    local pad=$(( safe_w - ${#content} ))
    
    if (( idx == sel )); then af_core_color_bg "46"; af_core_color_fg "0"; else af_core_color_bg "0"; af_core_color_fg "$color"; fi
    
    af_io_write "$content"; for ((p=0;p<pad;p++)); do af_io_write " "; done
    ((idx++)); ((render_idx++))
  done <<< "$data"
  
  # Ghost Fix
  af_core_color_bg "0"; af_core_color_fg "$color"
  while (( render_idx < h )); do
      af_core_cursor $((y+render_idx)) "$x"; for ((p=0;p<safe_w;p++)); do af_io_write " "; done
      ((render_idx++))
  done
  af_core_color_reset
}
