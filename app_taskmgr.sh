#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: Task Manager (v2.2 - Theme Support)
# ─────────────────────────────────────────────────────────────────────────────

source "./alienframe.sh"

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────
get_process_list() {
  ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 50 | awk '
    NR==1 { printf "%-6s %-8s %-5s %-5s %s\n", "PID", "USER", "CPU", "MEM", "COMMAND" }
    NR>1  { printf "%-6s %-8s %-5s %-5s %s\n", $1, $2, $3, $4, $5 }
  '
}

refresh_ui() {
  local procs
  procs="$(get_process_list)"
  af_api_update "proc_list" "$procs"
}

get_state_name() {
  case "$1" in
    R) echo "RUNNING" ;; S) echo "SLEEPING" ;; D) echo "DISK SLEEP" ;;
    Z) echo "ZOMBIE" ;; T) echo "STOPPED" ;; *) echo "UNKNOWN ($1)" ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# EVENT HANDLERS
# ─────────────────────────────────────────────────────────────────────────────
my_on_select() {
  local panel="$1"
  local item="$2"
  item="$(echo "$item" | sed 's/\x1b\[[0-9;]*m//g')" # Strip ANSI
  
  if [[ "$panel" == "proc_list" ]]; then
      local pid=$(echo "$item" | awk '{print $1}')
      if [[ "$pid" == "PID" ]]; then return; fi

      export SELECTED_PID="$pid"

      if ps -p "$pid" > /dev/null 2>&1; then
          local full_cmd=$(ps -p "$pid" -o args=)
          local state_code=$(ps -p "$pid" -o state=)
          local start_time=$(ps -p "$pid" -o lstart=)
          local ppid=$(ps -p "$pid" -o ppid=)
          local rss=$(ps -p "$pid" -o rss=)
          
          local state_human="$(get_state_name "$state_code")"
          local ram_mb=$(( rss / 1024 ))

          local info="TARGET ANALYSIS
──────────────────────────
PID:        $pid
PARENT PID: $ppid
STATE:      $state_human
MEMORY:     $ram_mb MB
STARTED:    $start_time

FULL COMMAND:
${full_cmd:0:40}...

[ ACTIONS ]
[K] Terminate   [F] Force Kill"

          af_api_update "details" "$info"
      else
          af_api_update "details" "❌ Process $pid not found.
Press 'R' to refresh."
      fi
  fi
}

my_on_key() {
  local focus="$1"
  local key="$2"
  
  if [[ "$key" == "r" || "$key" == "R" ]]; then
     refresh_ui
     af_api_update "details" "Data Refreshed."
  fi

  if [[ "$key" == "k" || "$key" == "K" ]]; then
     if [[ -n "$SELECTED_PID" ]]; then
        kill "$SELECTED_PID" 2>/dev/null && { af_api_update "details" "✅ Killed PID $SELECTED_PID"; refresh_ui; }
     fi
  fi
  
  if [[ "$key" == "f" || "$key" == "F" ]]; then
     if [[ -n "$SELECTED_PID" ]]; then
        kill -9 "$SELECTED_PID" 2>/dev/null && { af_api_update "details" "💀 Force Killed $SELECTED_PID"; refresh_ui; }
     fi
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
main() {
  # 1. CAPTURE THEME ARGUMENT
  # Use the first argument ($1), or default to "cyber" if empty
  local target_theme="${1:-cyber}"
  
  # 2. Initialize with that theme
  af_api_init "$target_theme"
  eval $(af_api_geometry)
  
  local help_text="Select a process for Deep Scan.

UP/DOWN : Navigate
ENTER   : View Details
R       : Refresh List"
  
  local list_w=$(( (COLS * 55) / 100 ))
  local list_h=$ROWS
  local detail_x=$(( list_w + 1 ))
  local detail_w=$(( COLS - list_w ))

  local procs="$(get_process_list)"

  af_api_panel "proc_list" "custom:1,1,${list_w},${list_h}" "ACTIVE TASKS" "$procs" "list"
  af_api_panel "details"   "custom:${detail_x},1,${detail_w},${list_h}" "INTELLIGENCE" "$help_text" "text"
  
  af_api_on_select "my_on_select"
  af_api_on_key    "my_on_key"
  
  af_api_run 1
}

# Pass all arguments ($@) to main
main "$@"