#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_path.sh
#  dynamic path + tag-aware resolver for modules, plugins, and themes
# ─────────────────────────────────────────────────────────────────────────────

#@AF:module=path
#@AF:name=af_path.sh
#@AF:desc=Dynamic path resolver with tag indexing and caching
#@AF:version=1.1.0
#@AF:type=core
#@AF:uuid=af_core_path_002

# --- BASE DETECTION ---------------------------------------------------------
if [[ -z "${AF_BASE_DIR:-}" ]]; then
  if [[ -d "./AlienFrame" ]]; then
    AF_BASE_DIR="$(cd ./AlienFrame && pwd)"
  else
    AF_BASE_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi
fi
export AF_BASE_DIR

AF_PLUGIN_DIR="${AF_PLUGIN_DIR:-$AF_BASE_DIR/plugins}"
AF_THEME_DIR="${AF_THEME_DIR:-$AF_BASE_DIR/themes}"
AF_CACHE_DIR="${AF_CACHE_DIR:-$AF_BASE_DIR/.cache}"
AF_LOG_DIR="${AF_LOG_DIR:-$AF_BASE_DIR/.logs}"
AF_TMP_DIR="${AF_TMP_DIR:-/tmp/alienframe}"

mkdir -p "$AF_PLUGIN_DIR" "$AF_THEME_DIR" "$AF_CACHE_DIR" "$AF_LOG_DIR" "$AF_TMP_DIR"

# --- CACHE PATHS ------------------------------------------------------------
AF_TAG_CACHE_FILE="$AF_CACHE_DIR/af_tags.index"

# --- TAG SCAN ---------------------------------------------------------------
# Scans for all af_*.sh files and indexes #@AF: headers
af_path_scan_tags() {
  local f key val
  : > "$AF_TAG_CACHE_FILE" # clear cache
  while IFS= read -r -d '' f; do
    local mod name desc type ver uuid
    while IFS= read -r line; do
      [[ "$line" =~ ^#@AF:module= ]]   && mod="${line#*=}"
      [[ "$line" =~ ^#@AF:name= ]]     && name="${line#*=}"
      [[ "$line" =~ ^#@AF:desc= ]]     && desc="${line#*=}"
      [[ "$line" =~ ^#@AF:type= ]]     && type="${line#*=}"
      [[ "$line" =~ ^#@AF:version= ]]  && ver="${line#*=}"
      [[ "$line" =~ ^#@AF:uuid= ]]     && uuid="${line#*=}"
    done < <(head -n 15 "$f")
    [[ -n "$mod" ]] && printf "%s|%s|%s|%s|%s|%s|%s\n" "$mod" "$name" "$desc" "$type" "$ver" "$uuid" "$f" >>"$AF_TAG_CACHE_FILE"
  done < <(find "$AF_BASE_DIR" -type f -name 'af_*.sh' -print0 2>/dev/null)
}

# --- LOOKUP HELPERS ---------------------------------------------------------
# af_path_lookup <module_name>
af_path_lookup() {
  local mod="$1"
  [[ -f "$AF_TAG_CACHE_FILE" ]] || af_path_scan_tags
  awk -F'|' -v m="$mod" '$1==m {print $7; exit}' "$AF_TAG_CACHE_FILE"
}

# --- MAIN RESOLVER ----------------------------------------------------------
# af_path_resolve <category> <name>
af_path_resolve() {
  local cat="$1" name="$2" file=""
  case "$cat" in
    module)
      file="$(af_path_lookup "$name")"
      [[ -z "$file" ]] && file="$AF_BASE_DIR/af_${name}.sh"
      ;;
    plugin)
      file="$AF_PLUGIN_DIR/$name/af_${name}.sh"
      ;;
    theme)
      file="$AF_THEME_DIR/${name%.theme}.theme"
      ;;
    raw|*)
      file="$AF_BASE_DIR/$name"
      ;;
  esac
  echo "$file"
}

# --- ENUMERATIONS -----------------------------------------------------------
af_path_list_modules() {
  [[ -f "$AF_TAG_CACHE_FILE" ]] || af_path_scan_tags
  awk -F'|' '$4=="core"{print $1}' "$AF_TAG_CACHE_FILE" | sort
}

af_path_list_plugins() {
  [[ -f "$AF_TAG_CACHE_FILE" ]] || af_path_scan_tags
  awk -F'|' '$4=="plugin"{print $1}' "$AF_TAG_CACHE_FILE" | sort
}

af_path_list_themes() {
  [[ -d "$AF_THEME_DIR" ]] || return
  find "$AF_THEME_DIR" -type f -name '*.theme' -exec basename {} .theme \;
}

# --- UTIL SHORTCUTS ---------------------------------------------------------
af_path_cache_file() { printf '%s/%s.cache' "$AF_CACHE_DIR" "${1:-general}"; }
af_path_log_file()   { printf '%s/%s.log' "$AF_LOG_DIR"   "${1:-session}"; }
af_path_tmp_file()   { printf '%s/%s.tmp' "$AF_TMP_DIR"   "${1:-temp}"; }

# --- AUTO INIT --------------------------------------------------------------
if [[ ! -s "$AF_TAG_CACHE_FILE" ]]; then
  af_path_scan_tags
fi
