#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame API :: alienframe.sh
#  The single-file include for building TUI apps
# ─────────────────────────────────────────────────────────────────────────────

# 1. Auto-Detect Framework Directory
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  AF_LIB_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  AF_LIB_DIR="$(pwd)"
fi
export AF_BASE_DIR="$AF_LIB_DIR"

# 2. Load Core Modules (Bulletproof Mode)
source "$AF_LIB_DIR/af_io.sh"
source "$AF_LIB_DIR/af_sh_compat.sh"
source "$AF_LIB_DIR/af_term_size.sh"
source "$AF_LIB_DIR/af_term_color.sh"
source "$AF_LIB_DIR/af_term_input.sh"
source "$AF_LIB_DIR/af_path.sh"
source "$AF_LIB_DIR/af_core.sh"
source "$AF_LIB_DIR/af_layout.sh"
source "$AF_LIB_DIR/af_draw.sh"
source "$AF_LIB_DIR/af_list.sh"
source "$AF_LIB_DIR/af_splash.sh"
source "$AF_LIB_DIR/af_engine.sh"

# ─────────────────────────────────────────────────────────────────────────────
# PUBLIC API FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────

# Initialize the App (Theme & Screen)
# Usage: af_api_init [theme_name]
af_api_init() {
  local theme="${1:-default}"
  af_core_clear
  af_core_hide_cursor
  
  if [[ -f "$AF_LIB_DIR/themes/$theme.theme" ]]; then
    export AF_THEME="$theme"
    af_layout_load_theme "$theme"
  else
    # Auto-generate cyber if missing
    if [[ "$theme" == "cyber" ]]; then
       mkdir -p "$AF_LIB_DIR/themes"
       printf "FG=15\nBG=0\nBORDER=24\nACCENT=46\nTEXT=51\n" > "$AF_LIB_DIR/themes/cyber.theme"
       export AF_THEME="cyber"
       af_layout_load_theme "cyber"
    else
       af_init default
    fi
  fi
}

# Create a Panel
# Usage: af_api_panel NAME REGION TITLE CONTENT [TYPE]
af_api_panel() {
  local name="$1"
  local region="$2"
  local title="$3"
  local content="$4"
  local type="${5:-text}"
  local theme="${AF_THEME:-default}"
  
  af_engine_panel_add "$name" "$region" "$title" "$content" "$theme" "$type"
}

# Update Panel Content
# Usage: af_api_update NAME NEW_CONTENT
af_api_update() {
  af_engine_panel_update "$1" "$2"
}

# Register Callback for Selection (List Enter)
# Usage: af_api_on_select FUNCTION_NAME
af_api_on_select() {
  AF_CALLBACK_SELECT="$1"
}

# Register Callback for Raw Keys
# Usage: af_api_on_key FUNCTION_NAME
af_api_on_key() {
  AF_CALLBACK_KEY="$1"
}

# Run the App (With Safety Toggles)
af_api_run() {
  local splash="${1:-0}"
  
  # 1. DISABLE TERMINAL ECHO (Fixes ^[[B artifacts)
  if command -v stty >/dev/null; then
      stty -echo
  fi
  
  # 2. Splash (Optional)
  if (( splash )); then
    af_splash_show
    sleep 0.5
  fi
  
  # 3. Run Engine
  af_engine_run
  
  # 4. Cleanup & Restore Echo
  af_core_show_cursor
  af_core_clear
  
  if command -v stty >/dev/null; then
      stty echo
  fi
}

# Helper: Get safe screen geometry variables
# Usage: eval $(af_api_geometry)
af_api_geometry() {
  local cols rows
  read cols rows <<<"$(af_core_size)"
  (( cols < 20 )) && cols=80
  (( rows < 10 )) && rows=24
  
  # Standard Layout Helpers
  local half_w=$(( cols / 2 ))
  local half_h=$(( rows / 2 ))
  
  echo "COLS=$cols ROWS=$rows HALF_W=$half_w HALF_H=$half_h"
}