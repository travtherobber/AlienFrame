#!/usr/bin/env bash
#@AF:module=splash
source "${AF_BASE_DIR}/src/af_core.sh" 2>/dev/null || true
source "${AF_BASE_DIR}/src/af_io.sh" 2>/dev/null || true
_af_splash_logo_full() { mapfile -t LINES <<'IMG'
 ░▒▓██████▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓████████▓▒░▒▓███████▓▒░
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░
░▒▓████████▓▒░▒▓█▓▒░      ░▒▓█▓▒░▒▓██████▓▒░ ░▒▓█▓▒░░▒▓█▓▒░
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░
░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓█▓▒░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░
IMG
}
_af_splash_logo_mini() { mapfile -t LINES <<'IMG'
 ░▒▓████▓▒░  AlienFrame
   ░▒▓█▓▒░   booting...
     ░▒▓▒░
IMG
}
af_splash_show() {
  local cols rows; read cols rows <<<"$(af_core_size)"
  local total=16; if (( rows < 20 )); then _af_splash_logo_mini; total=3; else _af_splash_logo_full; fi
  local top=$((rows/2 - total/2)); ((top<1)) && top=1
  af_core_clear; af_core_hide_cursor; af_core_color_fg 118 
  for line in "${LINES[@]}"; do
    local left=$(( (cols - ${#line}) / 2 )); ((left<0)) && left=0
    af_core_cursor "$top" "$left"; af_io_writeln "$line"; ((top++))
  done
  local steps=20
  af_core_cursor $((top+2)) $(( (cols/2) - 12 )); af_io_write "Loading modules..."
  af_core_cursor $((top+3)) $(( (cols/2) - (steps/2) ))
  af_core_color_fg 240; af_io_write "["; af_core_color_fg 46
  for ((i=0;i<steps;i++)); do af_io_write "▓"; sleep 0.01; done
  af_core_color_fg 240; af_io_write "]"; af_core_color_reset
}
