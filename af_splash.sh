#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_splash.sh
#  high-fidelity startup banner — centered, animated, 100 % af_io-native
# ─────────────────────────────────────────────────────────────────────────────

#@AF:module=splash
#@AF:name=af_splash.sh
#@AF:desc=Startup splash / intro banner for AlienFrame
#@AF:version=1.0.0
#@AF:type=core
#@AF:uuid=af_core_splash_001

# --- deps -------------------------------------------------------------------
source "$(af_path_resolve module core)" 2>/dev/null || true
declare -F af_io_write >/dev/null || source "$(af_path_resolve module io)" 2>/dev/null || true

# --- logo content -----------------------------------------------------------
_af_splash_logo() {
  mapfile -t LINES <<'EOF'
 ░▒▓██████▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓████████▓▒░▒▓███████▓▒░                
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░               
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░               
░▒▓████████▓▒░▒▓█▓▒░      ░▒▓█▓▒░▒▓██████▓▒░ ░▒▓█▓▒░░▒▓█▓▒░               
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░               
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░               
░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓█▓▒░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░               
                                                                          
                                                                          
░▒▓████████▓▒░▒▓███████▓▒░ ░▒▓██████▓▒░░▒▓██████████████▓▒░░▒▓████████▓▒░ 
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
░▒▓██████▓▒░ ░▒▓███████▓▒░░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓██████▓▒░   
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░ 
EOF

  local cols rows; read cols rows <<<"$(af_core_size)"
  local top=$(( (rows / 2) - (${#LINES[@]} / 2) ))
  local left

  af_core_color_fg 118; af_core_bold
  for line in "${LINES[@]}"; do
    left=$(( (cols - ${#line}) / 2 ))
    ((left < 0)) && left=0
    af_core_cursor "$top" "$left"
    af_io_writeln "$line"
    ((top++))
  done
  af_core_color_reset
}

# --- animated progress bar --------------------------------------------------
_af_splash_progress() {
  local steps=20 delay=0.05 label="boot"
  local i
  af_core_color_fg 118; af_io_write "⟣"; af_io_repeat $((steps+2)) "⟢"; af_io_nl
  for ((i=0;i<=steps;i++)); do
    local pct=$(( (i*100)/steps ))
    local fill=$((i))
    local empty=$((steps-fill))
    af_core_color_fg 240; af_io_write "▕"
    af_core_color_fg 118; af_io_repeat "$fill" "▓"
    af_core_color_fg 236; af_io_repeat "$empty" "░"
    af_core_color_fg 240; af_io_write "▏ "
    af_core_color_fg 250; af_io_write "$label "
    af_core_color_fg 118; af_io_write "$pct%"
    sleep "$delay"
    af_io_csi "1G" ; af_io_csi "1A" ; af_io_clear_line
  done
  af_core_color_reset
  af_io_nl
}

# --- main splash entry ------------------------------------------------------
af_splash_show() {
  ((AF_NO_SPLASH)) && return 0

  local msg="loading AlienFrame ${AF_VERSION:-v1.x}"
  af_core_clear
  af_core_hide_cursor

  _af_splash_logo
  af_io_nl
  af_core_color_fg 118; af_io_writeln "───────────────────────────────────────────────"
  af_core_color_fg 250; af_io_writeln "$msg"
  af_core_color_fg 118; af_io_writeln "───────────────────────────────────────────────"
  af_io_nl
  _af_splash_progress
  af_core_color_fg 118; af_io_writeln "✅ ready."
  af_core_show_cursor
  af_core_color_reset
}

# --- END MODULE -------------------------------------------------------------
