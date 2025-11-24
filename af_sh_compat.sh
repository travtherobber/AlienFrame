#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_sh_compat.sh
#  cross-shell compatibility bridge — bash / zsh / dash / sh
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=compat
#@AF:name=af_sh_compat.sh
#@AF:desc=Cross-shell compatibility layer (adaptive, zero-dep)
#@AF:version=1.2.0
#@AF:type=core
#@AF:uuid=af_core_compat_003

# --- shell detection --------------------------------------------------------
AF_SHELL_RAW="${ZSH_NAME:-${BASH:-$(ps -p $$ -o comm= 2>/dev/null | tr -d '-')}}"
AF_SHELL_TYPE="unknown"

case "$AF_SHELL_RAW" in
  *zsh*)  AF_SHELL_TYPE="zsh" ;;
  *bash*) AF_SHELL_TYPE="bash" ;;
  *dash*) AF_SHELL_TYPE="dash" ;;
  *sh)    AF_SHELL_TYPE="sh" ;;
esac

# refine detection when ps misreports
if [[ "$AF_SHELL_TYPE" == "sh" && -L /bin/dash && "$(readlink /bin/sh 2>/dev/null)" == *dash* ]]; then
  AF_SHELL_TYPE="dash"
fi

AF_SHELL_VERSION="${BASH_VERSION:-${ZSH_VERSION:-unknown}}"
export AF_SHELL_TYPE AF_SHELL_VERSION

# --- associative array compatibility ---------------------------------------
if [[ "$AF_SHELL_TYPE" == "zsh" ]]; then
  emulate -LR bash 2>/dev/null || true
  setopt KSH_ARRAYS 2>/dev/null || true

  if typeset -A _af_assoc_test 2>/dev/null; then
    af_assoc_set()  { builtin eval "${1}[\"$2\"]=\"\$3\""; }
    af_assoc_get()  { builtin eval "printf '%s\n' \"\${${1}[\"$2\"]:-}\""; }
    af_assoc_keys() { builtin eval "printf '%s\n' \"\${(k)${1}}\""; }
  else
    af_assoc_set()  { builtin eval "__AF_ASSOC_${1}_${2}=\"\$3\""; }
    af_assoc_get()  { builtin eval "printf '%s\n' \"\${__AF_ASSOC_${1}_${2}:-}\""; }
    af_assoc_keys() { set | sed -n "s/^__AF_ASSOC_${1}_\\([^=]*\\)=.*/\\1/p"; }
  fi

elif [[ "$AF_SHELL_TYPE" == "bash" ]]; then
  if ((BASH_VERSINFO[0] >= 4)); then
    af_assoc_set()  { builtin eval "${1}[\"$2\"]=\"\$3\""; }
    af_assoc_get()  { builtin eval "printf '%s\n' \"\${${1}[\"$2\"]:-}\""; }
    af_assoc_keys() { builtin eval "printf '%s\n' \"\${!${1}[@]}\""; }
  else
    af_assoc_set()  { builtin eval "__AF_ASSOC_${1}_${2}=\"\$3\""; }
    af_assoc_get()  { builtin eval "printf '%s\n' \"\${__AF_ASSOC_${1}_${2}:-}\""; }
    af_assoc_keys() { set | sed -n "s/^__AF_ASSOC_${1}_\\([^=]*\\)=.*/\\1/p"; }
  fi

else
  # dash / sh fallback — key/value pseudo-assoc
  af_assoc_set()  { builtin eval "__AF_ASSOC_${1}_${2}=\"\$3\""; }
  af_assoc_get()  { builtin eval "printf '%s\n' \"\${__AF_ASSOC_${1}_${2}:-}\""; }
  af_assoc_keys() { set | sed -n "s/^__AF_ASSOC_${1}_\\([^=]*\\)=.*/\\1/p"; }
fi

# --- informational output ---------------------------------------------------
af_compat_info() {
  builtin echo "[AF:compat] shell=${AF_SHELL_TYPE} version=${AF_SHELL_VERSION}"
}

# --- ensure exports exist ---------------------------------------------------
: "${AF_SHELL_TYPE:=unknown}"
: "${AF_SHELL_VERSION:=unknown}"

# --- optional banner --------------------------------------------------------
if [[ -z "${AF_COMPAT_SILENT:-}" ]]; then
  af_compat_info
fi
