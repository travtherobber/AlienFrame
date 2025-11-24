#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  My App :: Process Manager (Using AlienFrame API)
# ─────────────────────────────────────────────────────────────────────────────

# 1. Import the Framework
source "./alienframe.sh"

# 2. Define our logic
my_on_select() {
  local panel="$1"
  local item="$2"
  
  # Clean item (strip colors)
  item="$(echo "$item" | sed 's/\x1b\[[0-9;]*m//g')"
  
  if [[ "$panel" == "proc_list" ]]; then
      # Extract PID (first column) and Name (fourth column)
      local pid=$(echo "$item" | awk '{print $1}')
      local name=$(echo "$item" | awk '{print $4}')
      
      # Update info panel
      # Using $'' to ensure newlines render correctly
      local info=$'PROCESS SELECTED\n\nPID:  '"$pid"$'\nNAME: '"$name"$'\n\nPress \'K\' to kill (Simulated)'
      
      af_api_update "details" "$info"
      
      # Store selected PID in a global for key handler
      export SELECTED_PID="$pid"
  fi
}

my_on_key() {
  local focus="$1"
  local key="$2"
  
  # Handle 'k' for kill
  if [[ "$key" == "k" || "$key" == "K" ]]; then
     if [[ -n "$SELECTED_PID" ]]; then
        af_api_update "details" "⚠️  KILL SIGNAL SENT TO $SELECTED_PID ⚠️\n(Simulation Only)"
     fi
  fi
}

# 3. Main Setup
main() {
  # Init with Cyber theme
  af_api_init "cyber"
  
  # Get geometry helpers
  eval $(af_api_geometry)
  
  # Prepare Data
  # Get top 20 processes (pid, user, time, command)
  local procs="$(ps -e -o pid,user,time,comm | head -n 20)"
  
  # FIX: Use $'...' for proper newlines
  local help_text=$'Select a process.\nPress ENTER to view.\nPress K to Kill.'
  
  # Create Panels
  # Left: List
  af_api_panel "proc_list" "custom:1,1,${HALF_W},${ROWS}" "ACTIVE PROCESSES" "$procs" "list"
  
  # Right: Details
  local right_x=$((HALF_W + 1))
  af_api_panel "details"   "custom:${right_x},1,${HALF_W},${ROWS}" "CONTROLS" "$help_text" "text"
  
  # Register Events
  af_api_on_select "my_on_select"
  af_api_on_key    "my_on_key"
  
  # Run!
  af_api_run 1
}

# Start
main