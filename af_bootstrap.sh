#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_bootstrap.sh
#  unified loader / runtime bootstrap (plugin-ready, af_io integrated)
# ─────────────────────────────────────────────────────────────────────────────

#@AF:module=bootstrap
#@AF:name=af_bootstrap.sh
#@AF:desc=AlienFrame unified bootstrap and runtime entrypoint
#@AF:version=1.0.0
#@AF:type=core
#@AF:uuid=af_core_boot_001

# --- locate framework brain -------------------------------------------------
AF_BASE_DIR="${AF_BASE_DIR:-$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# shellcheck source=/dev/null
if [[ -f "$AF_BASE_DIR/af_af.sh" ]]; then
  source "$AF_BASE_DIR/af_af.sh"
else
  builtin echo "[AF:ERR] missing af_af.sh at $AF_BASE_DIR" >&2
  exit 1
fi

# --- ensure af_io is available ----------------------------------------------
# This should be redundant, but ensures bootstrap works standalone.
if ! declare -F af_io_write >/dev/null; then
  af_io_write()   { builtin echo -n "$*"; }
  af_io_writeln() { builtin echo "$*"; }
  af_io_repeat()  { local n="$1" ch="${2:- }"; local o=""; for((i=0;i<n;i++));do o+="$ch";done;af_io_write "$o"; }
  af_io_esc()     { af_io_write $'\033'"$1"; }
  af_io_fmt()     { local fmt="$1";shift;local out="$fmt";for a in "$@";do out="${out/%s/$a}";done;af_io_write "$out"; }
fi

# --- initialize default module set ------------------------------------------
af_bootstrap_init() {
  local profile="${1:-default}"
  af_init "$profile"
  af_io_writeln "[AF] Initialized profile: $profile"
}

# --- optional splash then run demo layout -----------------------------------
af_bootstrap_run() {
  local use_demo="${1:-1}"

  # Clear + hide cursor via core (if loaded)
  declare -F af_core_clear >/dev/null       && af_core_clear
  declare -F af_core_hide_cursor >/dev/null && af_core_hide_cursor

  # Splash if available
  if declare -F af_splash_show >/dev/null; then
    af_splash_show
  fi

  # Optional demo setup
  if (( use_demo )); then
    local left="AlienFrame left pane\nUse J/K or arrows to scroll.\nTAB to switch focus.\nQ to quit."
    local right="Right pane.\nAdd your own content here.\nPage/line toggle with 'p'."

    af_engine_panel_add "left"  "left-half"  "AlienFrame • Left"  "$left"  "default"
    af_engine_panel_add "right" "right-half" "AlienFrame • Right" "$right" "default"
  fi

  af_engine_run

  # Restore cursor after exit
  declare -F af_core_show_cursor >/dev/null && af_core_show_cursor
  af_io_writeln "[AF] Engine stopped cleanly."
}

# --- entrypoint when executed directly --------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  af_bootstrap_init default
  af_bootstrap_run 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# END MODULE
