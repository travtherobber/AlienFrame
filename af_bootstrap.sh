#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_bootstrap.sh
#  universal loader — auto-detects framework path, pulls af_af, ensures I/O
# ─────────────────────────────────────────────────────────────────────────────
#@AF:uuid=af_core_boot_001
#@AF:module=bootstrap
#@AF:name=af_bootstrap.sh
#@AF:desc=Primary entry bootstrapper for AlienFrame
#@AF:version=1.1.0
#@AF:type=core

# --- establish base path -----------------------------------------------------
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  AF_BASE_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [ -n "${(%):-%N}" ]; then
  AF_BASE_DIR="$(cd -- "$(dirname "${(%):-%N}")" && pwd)"
else
  AF_BASE_DIR="$(pwd)"
fi
AF_BASE_DIR="${AF_BASE_DIR//#!/}"
export AF_BASE_DIR

# define tty output channel early for IO-safe functions
AF_IO_TTY="/dev/tty"

# --- locate framework nucleus ------------------------------------------------
AF_MAIN="$AF_BASE_DIR/af_af.sh"
if [[ -f "$AF_MAIN" ]]; then
  # shellcheck source=/dev/null
  source "$AF_MAIN"
else
  builtin echo "[AF:ERR] missing af_af.sh at $AF_BASE_DIR" >&2
  exit 1
fi

# --- fallback mini-I/O -------------------------------------------------------
if ! declare -F af_io_write >/dev/null 2>&1; then
  af_io_write()   { builtin echo -n "$*"; }
  af_io_writeln() { builtin echo "$*"; }
  af_io_repeat()  { local n="$1" ch="${2:- }"; local o=""; for((i=0;i<n;i++));do o+="$ch";done;builtin echo -n "$o"; }
  af_io_esc()     { builtin echo -n $'\033'"$1"; }
  af_io_fmt()     { local fmt="$1";shift;local out="$fmt";for a in "$@";do out="${out/%s/$a}";done;builtin echo -n "$out"; }
fi

# --- bootstrap initialization ------------------------------------------------
af_bootstrap_init() {
  local profile="${1:-default}"
  af_init "$profile"
  af_io_writeln "[AF:boot] profile → $profile"
}

# --- run optional splash + engine demo ---------------------------------------
af_bootstrap_run() {
  local use_demo="${1:-1}"

  # Clear and hide cursor if core loaded
  declare -F af_core_clear >/dev/null  && af_core_clear
  declare -F af_core_hide_cursor >/dev/null && af_core_hide_cursor

  # Splash screen
  if declare -F af_splash_show >/dev/null; then
    af_splash_show
  else
    af_io_writeln "[AF:boot] no splash available"
  fi

  # Demo panels (optional)
  if (( use_demo )); then
    local left="AlienFrame left pane\nUse J/K or arrows to scroll.\nTAB to switch focus.\nQ to quit."
    local right="Right pane.\nAdd your own content here.\nPage/line toggle with 'p'."

    declare -F af_engine_panel_add >/dev/null && {
      af_engine_panel_add "left"  "left-half"  "AlienFrame • Left"  "$left"  "default"
      af_engine_panel_add "right" "right-half" "AlienFrame • Right" "$right" "default"
    }
  fi

  # Start engine
  if declare -F af_engine_run >/dev/null; then
    af_engine_run
  else
    af_io_writeln "[AF:boot] no engine detected"
  fi

  # Restore cursor and exit banner
  declare -F af_core_show_cursor >/dev/null && af_core_show_cursor
  af_io_writeln "[AF:boot] Engine stopped cleanly."
}

# --- entrypoint when executed directly ---------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  af_bootstrap_init default
  af_bootstrap_run 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# END MODULE
