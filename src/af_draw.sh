#!/usr/bin/env bash
#@AF:module=draw
af_draw_box() {
  local x="$1" y="$2" w="$3" h="$4" title="$5" color="$6"
  af_core_color_fg "$color"
  af_core_cursor "$y" "$x"; af_io_write "┌"
  for ((i=0;i<w-2;i++)); do af_io_write "─"; done; af_io_write "┐"
  for ((i=1;i<h-1;i++)); do
     af_core_cursor $((y+i)) "$x"; af_io_write "│"
     af_core_cursor $((y+i)) $((x+w-1)); af_io_write "│"
  done
  af_core_cursor $((y+h-1)) "$x"; af_io_write "└"
  for ((i=0;i<w-2;i++)); do af_io_write "─"; done; af_io_write "┘"
  if [[ -n "$title" ]]; then af_core_cursor "$y" $((x+2)); af_io_write " $title "; fi
  af_core_color_reset
}
