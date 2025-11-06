#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_splash.sh
#  startup splash banner — centered, animated, af_io-native
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=splash
#@AF:name=af_splash.sh
#@AF:desc=Animated intro splash for AlienFrame
#@AF:version=1.1.0
#@AF:type=core
#@AF:uuid=af_core_splash_002

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

  local cols rows
  read cols rows <<<"$(af_core_size)"
  local total=${#LINES[@]}
  local top=$((rows/2 - total/2))
  ((top<1)) && top=1

  af_core_color_fg 118; af_core_bold
  local line left
  for line in "${LINES[@]}"; do
    (( ${#line} > cols )) && line="${line:0:cols}"
    left=$(( (cols - ${#line}) / 2 ))
    ((left<0)) && left=0
    af_core_cursor "$top" "$left"; af_io_writeln "$line"
    ((top++))
  done
  af_core_color_reset
}

# --- progress animation -----------------------------------------------------
_af_splash_progress() {
  local steps=24
  local delay="${AF_SPLASH_SPEED:-0.04}"
  local label="boot"
  local i fill empty pct

  af_core_color_fg 240; af_io_write "▕"
  af_core_color_fg 118; af_io_repeat "$steps" "░"
  af_core_color_fg 240; af_io_writeln "▏"
  af_io_csi "1A" ; af_io_csi "1G"

  for ((i=0;i<=steps;i++)); do
    pct=$(( (i*100)/steps ))
    fill=$i; empty=$((steps - fill))
    af_io_csi "1G"
    af_core_color_fg 240; af_io_write "▕"
    af_core_color_fg 118; af_io_repeat "$fill" "▓"
    af_core_color_fg 236; af_io_repeat "$empty" "░"
    af_core_color_fg 240; af_io_write "▏ "
    af_core_color_fg 250; af_io_write "$label "
    af_core_color_fg 118; af_io_write "$pct%"
    sleep "$delay"
  done
  af_io_nl
  af_core_color_reset
}

# --- main entry -------------------------------------------------------------
af_splash_show() {
  ((AF_NO_SPLASH)) && return 0

  local msg="loading AlienFrame ${AF_VERSION:-v1.x}"
  af_core_clear; af_core_hide_cursor

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

# ─────────────────────────────────────────────────────────────────────────────
