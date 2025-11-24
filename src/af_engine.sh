#!/usr/bin/env bash
#@AF:module=engine
declare -gA P_BODY P_GEO P_TITLE P_TYPE P_SEL P_CURSOR
AF_ENGINE_FOCUS=""
AF_ENGINE_RUNNING=0
AF_CB_INPUT=""
AF_CB_KEY=""
AF_CB_SELECT=""
AF_CB_CHANGE=""

af_engine_panel_add() {
  local name="$1" region="$2" title="$3" body="$4" theme="$5" type="${6:-text}"
  local C R W H X Y; read C R W H X Y <<<"$(af_layout_geometry "$region")"
  P_GEO["$name"]="$X $Y $W $H"
  P_TITLE["$name"]="$title"; P_BODY["$name"]="$body"; P_TYPE["$name"]="$type"
  P_SEL["$name"]=0; P_CURSOR["$name"]=${#body}
  [[ -z "$AF_ENGINE_FOCUS" ]] && AF_ENGINE_FOCUS="$name"
}

af_engine_panel_update() {
  P_BODY["$1"]="$2"
  if (( AF_ENGINE_RUNNING )); then af_engine_render_one "$1"; fi
}

af_engine_render_one() {
  local name="$1"; local X Y W H; read X Y W H <<<"${P_GEO[$name]}"
  local type="${P_TYPE[$name]}"; local text="${P_BODY[$name]}"
  local color="240"; local focused=0
  if [[ "$name" == "$AF_ENGINE_FOCUS" ]]; then color="15"; focused=1; fi
  
  af_draw_box "$X" "$Y" "$W" "$H" "${P_TITLE[$name]}" "$color"
  local ix=$((X+1)) iy=$((Y+1)) iw=$((W-2)) ih=$((H-2))
  
  if [[ "$type" == "input" ]]; then
     af_input_render "$text" "${P_CURSOR[$name]}" "$iw" "$ix" "$iy" "15" "$focused"
  elif [[ "$type" == "list" ]]; then
     af_list_render "$text" "${P_SEL[$name]}" "$iw" "$ih" "$ix" "$iy" "15"
  else
     af_core_cursor "$iy" "$ix"; af_io_write "${text:0:$iw}"
  fi
}

af_engine_run() {
  # Force Raw Mode
  if command -v stty >/dev/null; then stty -icanon -echo min 0 time 0; fi
  af_core_hide_cursor; af_core_clear
  AF_ENGINE_RUNNING=1
  
  for n in "${!P_BODY[@]}"; do af_engine_render_one "$n"; done
  
  while (( AF_ENGINE_RUNNING )); do
    local key; key=$(af_core_read_key)
    if [[ -n "$key" ]]; then
       if [[ "$key" == "ESC" ]]; then AF_ENGINE_RUNNING=0; fi
       if [[ "$key" == "TAB" ]]; then
          local keys=("${!P_BODY[@]}")
          for i in "${!keys[@]}"; do
             if [[ "${keys[$i]}" == "$AF_ENGINE_FOCUS" ]]; then
                local next=$(( (i+1) % ${#keys[@]} ))
                AF_ENGINE_FOCUS="${keys[$next]}"
                break
             fi
          done
          for n in "${!P_BODY[@]}"; do af_engine_render_one "$n"; done
       fi
       
       local type="${P_TYPE[$AF_ENGINE_FOCUS]}"
       if [[ "$type" == "input" ]]; then
           local text="${P_BODY[$AF_ENGINE_FOCUS]}"
           local cur="${P_CURSOR[$AF_ENGINE_FOCUS]}"
           local changed=0
           if [[ ${#key} -eq 1 ]]; then
              P_BODY[$AF_ENGINE_FOCUS]="${text:0:$cur}${key}${text:$cur}"; (( P_CURSOR[$AF_ENGINE_FOCUS]++ )); changed=1
           elif [[ "$key" == "BACKSPACE" && $cur -gt 0 ]]; then
              P_BODY[$AF_ENGINE_FOCUS]="${text:0:$((cur-1))}${text:$cur}"; (( P_CURSOR[$AF_ENGINE_FOCUS]-- )); changed=1
           elif [[ "$key" == "ENTER" ]]; then
              if [[ -n "$AF_CB_INPUT" ]]; then $AF_CB_INPUT "$AF_ENGINE_FOCUS" "$text"; fi
           fi
           if [[ "$changed" == "1" && -n "$AF_CB_CHANGE" ]]; then $AF_CB_CHANGE "$AF_ENGINE_FOCUS" "${P_BODY[$AF_ENGINE_FOCUS]}"; fi
           af_engine_render_one "$AF_ENGINE_FOCUS"
           
       elif [[ "$type" == "list" ]]; then
           local sel="${P_SEL[$AF_ENGINE_FOCUS]}"
           if [[ "$key" == "UP" && $sel -gt 0 ]]; then (( P_SEL[$AF_ENGINE_FOCUS]-- )); fi
           if [[ "$key" == "DOWN" ]]; then (( P_SEL[$AF_ENGINE_FOCUS]++ )); fi
           
           if [[ "$key" == "ENTER" || "$key" == "UP" || "$key" == "DOWN" ]]; then
               if [[ -n "$AF_CB_SELECT" ]]; then
                   local item="$(echo "${P_BODY[$AF_ENGINE_FOCUS]}" | sed -n "$(( P_SEL[$AF_ENGINE_FOCUS] + 1 ))p")"
                   $AF_CB_SELECT "$AF_ENGINE_FOCUS" "$item"
               fi
           fi
           af_engine_render_one "$AF_ENGINE_FOCUS"
       fi
    fi
    sleep 0.01
  done
  af_core_show_cursor; af_core_clear; stty sane
}
