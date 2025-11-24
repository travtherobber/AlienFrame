#!/usr/bin/env bash
source "./alienframe.sh"

# ─── 1. LOGIC (What happens when you press keys?) ──────
app_on_select() {
  local panel="$1"
  local item="$2"

  # Example: If they pressed Enter in the "list" panel
  if [[ "$panel" == "my_list" ]]; then
      # Update the other panel with details
      af_api_update "my_details" "You selected:\n$item"
  fi
}

app_on_key() {
  local focus="$1"
  local key="$2"

  # Example: Press 'D' to delete something
  if [[ "$key" == "d" || "$key" == "D" ]]; then
     af_api_update "my_details" "Delete command received!"
  fi
}

# ─── 2. SETUP (How does it look?) ──────────────────────
main() {
  # Load Theme (defaults to cyber, or whatever you pass)
  af_api_init "${1:-cyber}"
  eval $(af_api_geometry)  # Gives you COLS, ROWS, HALF_W, etc.

  # Define Data
  local list_data="Item 1
Item 2
Item 3"
  local info_text="Welcome to your new app."

  # Create Panels (Name, Geometry, Title, Content, Type)
  af_api_panel "my_list"    "custom:1,1,${HALF_W},${ROWS}"      "MENU"    "$list_data" "list"
  af_api_panel "my_details" "custom:$((HALF_W+1)),1,${HALF_W},${ROWS}" "DETAILS" "$info_text" "text"

  # Hook up the Logic
  af_api_on_select "app_on_select"
  af_api_on_key    "app_on_key"

  # Run
  af_api_run 1
}

main "$@"