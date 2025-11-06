#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_af.sh
#  meta-controller / loader / registry / namespace manager (af_io integrated)
# ─────────────────────────────────────────────────────────────────────────────

#@AF:module=af
#@AF:name=af_af.sh
#@AF:desc=AlienFrame meta-controller, loader, and registry
#@AF:version=1.0.0
#@AF:type=core
#@AF:uuid=af_core_meta_001

# --- ENVIRONMENT GUARD ------------------------------------------------------
if ((BASH_VERSINFO[0] < 4)); then
  builtin echo "AlienFrame requires bash >= 4.0" >&2
  return 1 2>/dev/null || exit 1
fi

# --- CORE METADATA ----------------------------------------------------------
AF_VERSION="v1.0.0"
AF_BASE_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AF_DEBUG=0
AF_LAZY=0

# --- I/O LAYER --------------------------------------------------------------
# shellcheck source=/dev/null
if [[ -f "$AF_BASE_DIR/af_io.sh" ]]; then
  source "$AF_BASE_DIR/af_io.sh"
else
  # fallback mini I/O (if af_io not yet booted)
  af_io_write()   { builtin echo -n "$*"; }
  af_io_writeln() { builtin echo "$*"; }
  af_io_to()      { local fd="$1"; shift; builtin echo "$*" >&"$fd"; }
fi

# --- BASIC LOGGING ----------------------------------------------------------
af_log() { af_io_writeln "$*"; }
af_dbg() { ((AF_DEBUG)) && af_io_to 2 "[AF:DBG] $*\n"; }
af_err() { af_io_to 2 "[AF:ERR] $*\n"; }

# --- PATH LAYER -------------------------------------------------------------
# shellcheck source=/dev/null
if [[ ! -f "$AF_BASE_DIR/af_path.sh" ]]; then
  af_err "missing core dependency: af_path.sh"
  return 1 2>/dev/null || exit 1
fi
source "$AF_BASE_DIR/af_path.sh"

# --- REGISTRIES -------------------------------------------------------------
declare -Ag AF_MODULES=()   # module_name -> file
declare -Ag AF_PLUGINS=()   # plugin_name -> file
declare -Ag AF_FEATURES=()  # misc feature flags

# --- INTERNAL SOURCE HELPER -------------------------------------------------
_af_source() {
  local file="$1"
  [[ -f "$file" ]] || { af_err "cannot source $file"; return 1; }
  # shellcheck source=/dev/null
  source "$file"
}

# --- MODULE / PLUGIN LOADING ------------------------------------------------
af_load() {
  local type="$1" name="$2" path
  case "$type" in
    module)
      [[ -n "${AF_MODULES[$name]:-}" ]] && { af_dbg "module $name already loaded"; return 0; }
      path="$(af_path_resolve module "$name")"
      [[ -f "$path" ]] || { af_err "module not found: $name ($path)"; return 1; }
      _af_source "$path" && AF_MODULES["$name"]="$path"
      af_dbg "module loaded: $name"
      ;;
    plugin)
      [[ -n "${AF_PLUGINS[$name]:-}" ]] && { af_dbg "plugin $name already loaded"; return 0; }
      path="$(af_path_resolve plugin "$name")"
      [[ -f "$path" ]] || { af_err "plugin not found: $name ($path)"; return 1; }
      _af_source "$path" && AF_PLUGINS["$name"]="$path"
      af_dbg "plugin loaded: $name"
      ;;
    *)
      af_err "invalid type: $type"; return 1 ;;
  esac
}

af_require()     { af_load module "$1"; }
af_plugin_load() { af_load plugin "$1"; }

# --- PLUGIN REGISTRATION & CALLS -------------------------------------------
af_plugin_register() {
  local name="$1" desc="${2:-}"
  AF_FEATURES["plugin:$name"]="$desc"
  af_dbg "plugin registered: $name - $desc"
}

af_plugin_call() {
  local plug="$1" fn="$2"; shift 2
  local try1="afp_${plug}_${fn}"
  local try2="${plug}_${fn}"
  if declare -F "$try1" >/dev/null; then
    "$try1" "$@"
  elif declare -F "$try2" >/dev/null; then
    "$try2" "$@"
  else
    af_err "plugin '$plug' has no function '$fn'"
    return 1
  fi
}

# --- INTROSPECTION ----------------------------------------------------------
af_list_modules() { for m in "${!AF_MODULES[@]}"; do af_io_writeln "$m"; done | sort; }
af_list_plugins() { for p in "${!AF_PLUGINS[@]}"; do af_io_writeln "$p"; done | sort; }
af_where_module() { [[ ${AF_MODULES[$1]:-} ]] && af_io_writeln "${AF_MODULES[$1]}"; }
af_where_plugin() { [[ ${AF_PLUGINS[$1]:-} ]] && af_io_writeln "${AF_PLUGINS[$1]}"; }

# --- PROFILES / PRESETS -----------------------------------------------------
af_init() {
  local profile="${1:-default}"
  case "$profile" in
    minimal)
      af_require core
      af_require draw
      ;;
    default|*)
      af_require io
      af_require core
      af_require draw
      af_require layout
      af_require engine
      [[ -f "$(af_path_resolve module splash)" ]] && af_require splash
      ;;
  esac
}

# --- FRAMEWORK BANNER -------------------------------------------------------
af_banner() {
  af_io_writeln "AlienFrame ${AF_VERSION} — base: ${AF_BASE_DIR}"
}

# --- AUTO-BANNER WHEN EXECUTED DIRECTLY -------------------------------------
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && af_banner

# ─────────────────────────────────────────────────────────────────────────────
# END MODULE
