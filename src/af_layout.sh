#!/usr/bin/env bash
#@AF:module=layout
af_layout_geometry() {
  local mode="$1"; local cols=80; local rows=24
  local s; s=$(af_core_size); read cols rows <<<"$s"
  local w=$cols h=$rows x=1 y=1
  if [[ "$mode" == custom:* ]]; then
     local geo="${mode#custom:}"
     IFS=',' read -r x y w h <<<"$geo"
  fi
  echo "$cols $rows $w $h $x $y"
}
af_layout_load_theme() { :; } 
af_layout_color() { :; }
