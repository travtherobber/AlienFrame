#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_path.sh
#  dynamic path + tree resolver for modules, plugins, themes, and cache
#  (pure bash, af_io-based)
# ─────────────────────────────────────────────────────────────────────────────

# --- DEPENDENCIES -----------------------------------------------------------
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/af_io.sh"

# --- BASE DETECTION ---------------------------------------------------------
if [[ -z "${AF_BASE_DIR:-}" ]]; then
  AF_BASE_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# --- DEFAULT SUBPATHS -------------------------------------------------------
AF_PLUGIN_DIR="${AF_PLUGIN_DIR:-$AF_BASE_DIR/plugins}"
AF_THEME_DIR="${AF_THEME_DIR:-$AF_BASE_DIR/themes}"
AF_CACHE_DIR="${AF_CACHE_DIR:-$AF_BASE_DIR/.cache}"
AF_LOG_DIR="${AF_LOG_DIR:-$AF_BASE_DIR/.logs}"
AF_TMP_DIR="${AF_TMP_DIR:-/tmp/alienframe}"

# --- TREE ENSURER -----------------------------------------------------------
af_path_ensure_tree() {
  mkdir -p "$AF_PLUGIN_DIR" "$AF_THEME_DIR" "$AF_CACHE_DIR" "$AF_LOG_DIR" "$AF_TMP_DIR"
}

# --- PATH RESOLUTION --------------------------------------------------------
# af_path_resolve <category> <name>
#   category = module | plugin | theme | raw
af_path_resolve() {
  local category="$1" name="$2" path=""
  case "$category" in
    module) path="$AF_BASE_DIR/af_${name}.sh" ;;
    plugin) path="$AF_PLUGIN_DIR/$name/af_${name}.sh" ;;
    theme)  path="$AF_THEME_DIR/${name%.theme}.theme" ;;
    raw|*)  path="$AF_BASE_DIR/$name" ;;
  esac
  af_io_writeln "$path"
}

# --- EXISTENCE CHECKS -------------------------------------------------------
af_path_module_exists() { local f; f="$(af_path_resolve module "$1")"; [[ -f "$f" ]]; }
af_path_plugin_exists() { local f; f="$(af_path_resolve plugin "$1")"; [[ -f "$f" ]]; }
af_path_theme_exists()  { local f; f="$(af_path_resolve theme "$1")";  [[ -f "$f" ]]; }

# --- ENUMERATIONS -----------------------------------------------------------
af_path_list_plugins() {
  [[ -d "$AF_PLUGIN_DIR" ]] || return 0
  local d n
  for d in "$AF_PLUGIN_DIR"/*; do
    [[ -d "$d" ]] || continue
    n="$(basename "$d")"
    [[ -f "$d/af_${n}.sh" ]] && af_io_writeln "$n"
  done
}

af_path_list_modules() {
  local f
  for f in "$AF_BASE_DIR"/af_*.sh; do
    [[ -f "$f" ]] || continue
    local n="${f##*/}"
    n="${n#af_}"; n="${n%.sh}"
    af_io_writeln "$n"
  done
}

# --- SHORTCUTS --------------------------------------------------------------
af_path_cache_file() { af_io_writeln "$AF_CACHE_DIR/${1:-general}.cache"; }
af_path_log_file()   { af_io_writeln "$AF_LOG_DIR/${1:-session}.log"; }
af_path_tmp_file()   { af_io_writeln "$AF_TMP_DIR/${1:-temp}.tmp"; }

# --- INIT TREE ON LOAD ------------------------------------------------------
af_path_ensure_tree
