#!/usr/bin/env bash
# Alien_Frame quick doctor — non-destructive diagnostics

set -Eeuo pipefail

banner() { printf '\n== %s ==\n' "$*"; }
ok()     { printf '✅ %s\n' "$*"; }
warn()   { printf '⚠️  %s\n' "$*"; }
err()    { printf '❌ %s\n' "$*"; }

# 1) Environment snapshot
banner "env snapshot"
printf 'shell: %s\n' "${SHELL:-unknown}"
printf 'bash : %s\n' "${BASH_VERSION:-unknown}"
printf 'os   : %s %s\n' "$(uname -s)" "$(uname -r)"
printf 'cwd  : %s\n' "$(pwd)"

# 2) Locate repo root (look upward for a marker or known files)
banner "locate repo root"
find_root() {
  local d="$PWD"
  while :; do
    if [[ -e "$d/.af_root" ]] || compgen -G "$d/af_*.sh" >/dev/null; then
      printf '%s\n' "$d"; return 0
    fi
    [[ "$d" == "/" ]] && return 1
    d="$(dirname "$d")"
  done
}
AF_ROOT="$(find_root || true)"
if [[ -z "${AF_ROOT:-}" ]]; then
  err "could not locate Alien_Frame root (no .af_root or af_*.sh found)"
  exit 1
fi
ok "AF_ROOT → $AF_ROOT"

# 3) List top-level AF files
banner "top-level AF files"
FILES=($(ls -1 "$AF_ROOT" | grep -E '^af_.*\.sh$'))
if [ ${#FILES[@]} -eq 0 ]; then
  err "no af_*.sh scripts found in the root directory"
  exit 1
fi
ok "Found ${#FILES[@]} scripts"

# 4) Syntax check for core scripts
banner "syntax check"
shopt -s nullglob
REQ=( "$AF_ROOT"/af_*.sh )
missing=0
for f in "${REQ[@]}"; do
  if [[ -f "$f" ]]; then
    if bash -n "$f"; then ok "bash -n OK → $(basename "$f")"
    else err "syntax error → $f"; missing=1; fi
  else
    warn "missing file → $f"
  fi
done
(( missing )) && { err "fix syntax/missing files above"; exit 1; }

# 5) Ensure the core modules are sourced before testing
banner "source core modules"
source "$AF_ROOT/af_sh_compat.sh"  # Ensure compatibility
source "$AF_ROOT/af_io.sh"         # I/O functions
source "$AF_ROOT/af_layout.sh"     # Layout functions
source "$AF_ROOT/af_draw.sh"       # Drawing functions

# 6) Validate box rendering
banner "Testing Box Rendering"
test_render_box() {
  local region="${1:-center-box}"
  local title="${2:-'Test Box'}"
  local theme="${3:-default}"

  # Get layout geometry
  read _ _ w h x y <<<"$(af_layout_geometry "$region")"

  # Debug the geometry values
  af_io_writeln "Region: $region, Title: $title, Theme: $theme"
  af_io_writeln "Width: $w, Height: $h, X: $x, Y: $y"

  # Ensure these values are valid integers
  if ! [[ "$w" =~ ^[0-9]+$ ]] || ! [[ "$h" =~ ^[0-9]+$ ]] || ! [[ "$x" =~ ^[0-9]+$ ]] || ! [[ "$y" =~ ^[0-9]+$ ]]; then
    af_err "Invalid dimensions: Width=$w, Height=$h, X=$x, Y=$y"
    return 1
  fi

  # Check if the width and height are at least 3 to render a box
  (( w < 4 || h < 3 )) && return 0

  # Render the box
  af_draw_box "$region" "$title" "$theme"
}

# Run the test for rendering a box
test_render_box "center-box" "AlienFrame Test Box" "default"

# 7) Function registry snapshot
banner "function registry (af_*)"
declare -F | awk '{print $3}' | grep '^af_' | sed 's/^/  • /' || warn "no af_* functions found in env"

# 8) Exit code summary
banner "doctor complete"
ok "if anything errored above, paste this entire log for triage"
