#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_af.sh
#  meta-controller / loader / registry / namespace manager (adaptive version)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=af
#@AF:name=af_af.sh
#@AF:desc=Meta-controller / loader / registry / namespace manager
#@AF:version=1.2.0
#@AF:type=core

# --- BASE PATH DETECTION -----------------------------------------------------
if [[ -z "${AF_BASE_DIR:-}" || ! -d "$AF_BASE_DIR" ]]; then
  if [ -n "${BASH_SOURCE[0]:-}" ]; then
    AF_BASE_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  elif [ -n "${(%):-%N}" ]; then
    AF_BASE_DIR="$(cd -- "$(dirname "${(%):-%N}")" && pwd)"
  else
    AF_BASE_DIR="$(pwd)"
  fi
fi
AF_BASE_DIR="${AF_BASE_DIR//#!/}"
export AF_BASE_DIR

# --- SHELL COMPATIBILITY -----------------------------------------------------
[[ -f "$AF_BASE_DIR/af_sh_compat.sh" ]] && source "$AF_BASE_DIR/af_sh_compat.sh" 2>/dev/null \
  || echo "[AF:WARN] missing af_sh_compat.sh — limited features" >&2

# --- METADATA ---------------------------------------------------------------
AF_VERSION="v1.2.0"
AF_DEBUG="${AF_DEBUG:-0}"
AF_LAZY="${AF_LAZY:-0}"

# --- IO LAYER ---------------------------------------------------------------
if [[ -f "$AF_BASE_DIR/af_io.sh" ]]; then
  source "$AF_BASE_DIR/af_io.sh"
else
  af_io_write()   { builtin echo -n -- "$*"; }
  af_io_writeln() { builtin echo -- "$*"; }
  af_io_to()      { local fd="$1"; shift; builtin echo -- "$*" >&"$fd"; }
fi

# --- LOGGING UTILITIES ------------------------------------------------------
_af_stamp() { date +"%H:%M:%S"; }
af_log() { af_io_writeln "[AF $(_af_stamp)] $*"; }
af_dbg() { ((AF_DEBUG)) && af_io_to 2 "[AF:DBG $(_af_stamp)] $*\n"; }
af_err() { af_io_to 2 "[AF:ERR $(_af_stamp)] $*\n"; }
af_warn() { af_io_to 2 "[AF:WARN $(_af_stamp)] $*\n"; }

# --- PATH MANAGEMENT --------------------------------------------------------
if [[ -f "$AF_BASE_DIR/af_path.sh" ]]; then
  source "$AF_BASE_DIR/af_path.sh"
else
  af_err "missing core dependency: af_path.sh"
  return 1 2>/dev/null || exit 1
fi

# --- REGISTRIES -------------------------------------------------------------
declare -Ag AF_MODULES=()
declare -Ag AF_PLUGINS=()
declare -Ag AF_FEATURES=()

# --- INTERNAL SOURCE HELPER -------------------------------------------------
_af_source() {
  local f="$1"
  [[ -f "$f" ]] || { af_err "cannot source: $f"; return 1; }
  # ensure it doesn’t print banners when sourced indirectly
  ( export AF_SILENT=1; source "$f" ) || af_err "error sourcing: $f"
}

# --- MODULE / PLUGIN LOADER -------------------------------------------------
af_load() {
  local type="$1" name="$2" path
  case "$type" in
    module)
      [[ -n "${AF_MODULES[$name]:-}" ]] && return 0
      path="$(af_path_resolve module "$name")"
      if [[ -f "$path" ]]; then
        echo "[AF:load] sourcing $name → $path" >&2
        source "$path"    # ← ensure no $() or pipes here
        AF_MODULES["$name"]="$path"
      else
        af_err "module not found: $name ($path)"
        return 1
      fi
      ;;
    plugin)
      [[ -n "${AF_PLUGINS[$name]:-}" ]] && return 0
      path="$(af_path_resolve plugin "$name")"
      if [[ -f "$path" ]]; then
        echo "[AF:load] sourcing plugin $name → $path" >&2
        source "$path"
        AF_PLUGINS["$name"]="$path"
      else
        af_err "plugin not found: $name ($path)"
        return 1
      fi
      ;;
    *)
      af_err "invalid load type: $type"
      return 1 ;;
  esac
}


af_require()     { af_load module "$1"; }
af_plugin_load() { af_load plugin "$1"; }

# --- PLUGIN MANAGEMENT ------------------------------------------------------
af_plugin_register() {
  local n="$1" d="${2:-}"
  AF_FEATURES["plugin:$n"]="$d"
  af_dbg "plugin registered: $n"
}

af_plugin_call() {
  local p="$1" fn="$2"; shift 2
  local n1="afp_${p}_${fn}" n2="${p}_${fn}"
  if declare -F "$n1" >/dev/null; then
    "$n1" "$@"
  elif declare -F "$n2" >/dev/null; then
    "$n2" "$@"
  else
    af_err "plugin '$p' missing function '$fn'"
    return 1
  fi
}

# --- INTROSPECTION ----------------------------------------------------------
af_list_modules() { for m in "${!AF_MODULES[@]}"; do af_io_writeln "$m"; done | sort; }
af_list_plugins() { for p in "${!AF_PLUGINS[@]}"; do af_io_writeln "$p"; done | sort; }
af_where_module() { [[ ${AF_MODULES[$1]:-} ]] && af_io_writeln "${AF_MODULES[$1]}"; }
af_where_plugin() { [[ ${AF_PLUGINS[$1]:-} ]] && af_io_writeln "${AF_PLUGINS[$1]}"; }

# --- PROFILE LOADER ---------------------------------------------------------
af_init() {
  local profile="${1:-default}"
  case "$profile" in
    minimal)
      af_require io
      af_require core
      af_require draw
      ;;
    default|*)
      af_require io
      af_require core
      af_require layout
      af_require draw
      af_require engine
      [[ -f "$(af_path_resolve module splash 2>/dev/null)" ]] && af_require splash
      ;;
  esac
  af_dbg "profile initialized: $profile"
}

# --- PROFILE FILES (optional external definitions) --------------------------
_af_profile_load() {
  local f="$AF_BASE_DIR/profiles/$1.af"
  [[ -f "$f" ]] && source "$f" && af_dbg "custom profile: $1 loaded"
}

# --- BANNER -----------------------------------------------------------------
af_banner() {
  [[ "${AF_SILENT:-0}" == 1 ]] && return
  af_io_writeln "AlienFrame ${AF_VERSION} — base: ${AF_BASE_DIR}"
}

# --- AUTO-BANNER ------------------------------------------------------------
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && af_banner

# ─────────────────────────────────────────────────────────────────────────────
# END MODULE
