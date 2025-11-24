#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_bootstrap.sh (v1.8.0 - With Splash)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=bootstrap
#@AF:type=core

# --- 1. Setup Environment ---
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  AF_BASE_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  AF_BASE_DIR="$(pwd)"
fi
export AF_BASE_DIR
AF_IO_TTY="/dev/tty"

# --- 2. Manual Loading (Force Load All Modules) ---
source "$AF_BASE_DIR/af_io.sh"
source "$AF_BASE_DIR/af_sh_compat.sh"
source "$AF_BASE_DIR/af_term_size.sh"
source "$AF_BASE_DIR/af_term_color.sh"
source "$AF_BASE_DIR/af_term_input.sh"
source "$AF_BASE_DIR/af_path.sh"
source "$AF_BASE_DIR/af_core.sh"
source "$AF_BASE_DIR/af_layout.sh"
source "$AF_BASE_DIR/af_draw.sh"
source "$AF_BASE_DIR/af_list.sh"
source "$AF_BASE_DIR/af_splash.sh" # <--- Added Splash Module
source "$AF_BASE_DIR/af_engine.sh"

# --- 3. User Logic (File Viewer) ---
af_user_on_select() {
  local panel="$1"
  local item="$2"

  # Clean Filename
  item="$(echo "$item" | sed 's/\x1b\[[0-9;]*m//g')"
  item="${item#"${item%%[![:space:]]*}"}"
  item="${item%"${item##*[![:space:]]}"}"

  if [[ "$panel" == "inventory" ]]; then
     local content=""
     local fpath="$AF_BASE_DIR/$item"
     
     af_engine_panel_update "header" "OPENING: $item"

     if [[ -d "$fpath" ]]; then
         content="[DIRECTORY]\n$(ls -1 "$fpath" 2>/dev/null | head -n 20)"
     elif [[ -f "$fpath" ]]; then
         if grep -qI . "$fpath" 2>/dev/null; then
             # Text
             content="$(head -n 30 "$fpath" | cut -c 1-50)"
         else
             # Binary
             if command -v xxd >/dev/null; then
                content="$(head -n 20 "$fpath" | xxd -g 1 | cut -c1-34)"
             else
                content="[BINARY FILE]"
             fi
         fi
     else
         content="[ERROR] File not found:\n$fpath"
     fi
     
     af_engine_panel_update "data" "$content"
  fi
}

af_bootstrap_run() {
  # Screen Setup
  af_core_clear
  af_core_hide_cursor
  
  # Theme Setup
  local theme_file="$AF_BASE_DIR/themes/cyber.theme"
  if [[ ! -f "$theme_file" ]]; then
     mkdir -p "$AF_BASE_DIR/themes"
     printf "FG=15\nBG=0\nBORDER=24\nACCENT=46\nTEXT=51\n" > "$theme_file"
  fi
  export AF_THEME="cyber"
  af_layout_load_theme "cyber"

  # Geometry
  local cols rows
  read cols rows <<<"$(af_core_size)"
  (( cols < 20 )) && cols=80
  (( rows < 10 )) && rows=24

  local head_h=3
  local body_h=$(( rows - 3 ))
  local left_w=$(( cols / 2 ))
  local right_w=$(( cols - left_w ))
  local right_x=$(( left_w + 1 ))

  # Initial Data
  local sys_info="SYSTEM READY | $USER"
  local files="$(ls -1p | head -n 50)"
  local intro="STATUS: IDLE\n\nSelect a file and press ENTER."

  # Init Panels
  af_engine_panel_add "header"    "custom:1,1,${cols},${head_h}"        "SYSTEM"    "$sys_info" "cyber" "text"
  af_engine_panel_add "inventory" "custom:1,4,${left_w},${body_h}"      "INVENTORY"     "$files"    "cyber" "list"
  af_engine_panel_add "data"      "custom:${right_x},4,${right_w},${body_h}" "VIEWER"   "$intro"    "cyber" "text"

  # --- SPLASH SEQUENCE ---
  # Only run if splash function exists
  if declare -F af_splash_show >/dev/null; then
      af_splash_show
      # Small delay to let the user admire the logo
      sleep 0.5
  fi
  # -----------------------

  # START ENGINE
  af_engine_run

  # Cleanup
  af_core_show_cursor
  echo "[AF] Exited."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  af_bootstrap_run
fi