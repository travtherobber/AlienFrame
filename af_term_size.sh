#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_term_size.sh
#  Terminal size detection (pure ANSI, no stty/printf dependencies)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=term_size
#@AF:name=af_term_size.sh
#@AF:desc=Terminal size detection (pure ANSI, no printf/stty)
#@AF:version=1.0.2
#@AF:type=core
#@AF:uuid=af_core_term_size_001

af_term_size() {
  local cols rows savepos
  # Save cursor position quietly
  printf '\033[s' >/dev/tty
  # Move to bottom-right, query position, read silently
  IFS='[;' read -sdR -p $'\033[999;999H\033[6n' _ rows cols
  # Restore original cursor position
  printf '\033[u' >/dev/tty
  # Fallback to sane defaults
  [[ -z "$cols" || -z "$rows" ]] && cols="${COLUMNS:-80}" rows="${LINES:-24}"
  echo "$cols $rows"
}
