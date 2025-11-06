#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_sh_compat.sh
#  shell compatibility bridge — cross-shell (bash, zsh, dash)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=compat
#@AF:name=af_sh_compat.sh
#@AF:desc=Cross-shell compatibility layer (bash, zsh, dash)
#@AF:version=1.1.0
#@AF:type=core
#@AF:uuid=af_core_compat_002

# --- shell detection --------------------------------------------------------
AF_SHELL_RAW="${ZSH_NAME:-${BASH:-$(ps -p $$ -o comm= 2>/dev/null)}}"
AF_SHELL_TYPE="unknown"

case "$AF_SHELL_RAW" in
  *zsh*)  AF_SHELL_TYPE="zsh" ;;
  *bash*) AF_SHELL_TYPE="bash" ;;
  *dash*) AF_SHELL_TYPE="dash" ;;
  *sh)    AF_SHELL_TYPE="sh" ;;
esac

# --- global info ------------------------------------------------------------
AF_SHELL_VERSION="${BASH_VERSION:-${ZSH_VERSION:-unknown}}"
export AF_SHELL_TYPE AF_SHELL_VERSION

# --- array emulation helpers ------------------------------------------------
# define generic fallbacks so that modules depending on assoc arrays won’t break
if [[ "$AF_SHELL_TYPE" == "zsh" ]]; then
  emulate -LR bash 2>/dev/null || true
  setopt KSH_ARRAYS 2>/dev/null || true

  if typeset -A _af_assoc_test 2>/dev/null; then
    af_assoc_set()  { eval "${1}[\"$2\"]=\"\$3\""; }
    af_assoc_get()  { eval "echo \${${1}[\"$2\"]:-}"; }
    af_assoc_keys() { eval "echo \${(k)${1}}"; }
  else
    af_assoc_set()  { eval "__AF_ASSOC_${1}_${2}=\"\$3\""; }
    af_assoc_get()  { eval "echo \${__AF_ASSOC_${1}_${2}:-}"; }
    af_assoc_keys() {
      set | sed -n "s/^__AF_ASSOC_${1}_\([^=]*\)=.*/\1/p"
    }
  fi

elif [[ "$AF_SHELL_TYPE" == "bash" ]]; then
  # ensure bash >= 4 for associative arrays
  if ((BASH_VERSINFO[0] >= 4)); then
    af_assoc_set()  { eval "${1}[\"$2\"]=\"\$3\""; }
    af_assoc_get()  { eval "echo \${${1}[\"$2\"]:-}"; }
    af_assoc_keys() { eval "echo \${!${1}[@]}"; }
  else
    af_assoc_set()  { eval "__AF_ASSOC_${1}_${2}=\"\$3\""; }
    af_assoc_get()  { eval "echo \${__AF_ASSOC_${1}_${2}:-}"; }
    af_assoc_keys() {
      set | sed -n "s/^__AF_ASSOC_${1}_\([^=]*\)=.*/\1/p"
    }
  fi

else
  # dash / plain sh — no arrays at all
  af_assoc_set()  { eval "__AF_ASSOC_${1}_${2}=\"\$3\""; }
  af_assoc_get()  { eval "echo \${__AF_ASSOC_${1}_${2}:-}"; }
  af_assoc_keys() {
    set | sed -n "s/^__AF_ASSOC_${1}_\([^=]*\)=.*/\1/p"
  }
fi

# --- minimal compatibility helpers -----------------------------------------
af_compat_info() {
  echo "[AF:compat] shell=$AF_SHELL_TYPE version=$AF_SHELL_VERSION"
}

# --- export safe variable fallback -----------------------------------------
# ensures even plain sh shells have these envs
: "${AF_SHELL_TYPE:=unknown}"
: "${AF_SHELL_VERSION:=unknown}"

# --- optional banner --------------------------------------------------------
[[ -z "${AF_COMPAT_SILENT:-}" ]] && af_compat_info
