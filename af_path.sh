#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_path.sh
#  dynamic path + tag-aware resolver for modules, plugins, and themes
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=path
#@AF:name=af_path.sh
#@AF:desc=Dynamic path resolver with tag indexing and caching
#@AF:version=1.2.0
#@AF:type=core
#@AF:uuid=af_core_path_003

# --- resolve real base dir ---------------------------------------------------
if [[ -z "${AF_BASE_DIR:-}" || ! -d "$AF_BASE_DIR" ]]; then
  if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    AF_BASE_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  elif [[ -n "${(%):-%N}" ]]; then
    AF_BASE_DIR="$(cd -- "$(dirname "${(%):-%N}")" && pwd)"
  else
    AF_BASE_DIR="$(pwd)"
  fi
fi
export AF_BASE_DIR

# --- subdirs -----------------------------------------------------------------
AF_PLUGIN_DIR="${AF_PLUGIN_DIR:-$AF_BASE_DIR/plugins}"
AF_THEME_DIR="${AF_THEME_DIR:-$AF_BASE_DIR/themes}"
AF_CACHE_DIR="${AF_CACHE_DIR:-$AF_BASE_DIR/.cache}"
AF_LOG_DIR="${AF_LOG_DIR:-$AF_BASE_DIR/.logs}"
AF_TMP_DIR="${AF_TMP_DIR:-/tmp/alienframe}"
mkdir -p "$AF_PLUGIN_DIR" "$AF_THEME_DIR" "$AF_CACHE_DIR" "$AF_LOG_DIR" "$AF_TMP_DIR"

AF_TAG_CACHE_FILE="$AF_CACHE_DIR/af_tags.index"

# --- helper: absolute path ---------------------------------------------------
_af_path_abs() {
  local p="$1"
  [[ "$p" == /* ]] && echo "$p" && return
  echo "$PWD/${p#./}"
}

# --- tag scan ---------------------------------------------------------------
af_path_scan_tags() {
  : >"$AF_TAG_CACHE_FILE"
  local f mod name desc type ver uuid
  while IFS= read -r f; do
    mod=""; name=""; desc=""; type=""; ver=""; uuid=""
    while IFS= read -r line; do
      [[ "$line" =~ ^#@AF:module= ]]  && mod="${line#*=}"
      [[ "$line" =~ ^#@AF:name= ]]    && name="${line#*=}"
      [[ "$line" =~ ^#@AF:desc= ]]    && desc="${line#*=}"
      [[ "$line" =~ ^#@AF:type= ]]    && type="${line#*=}"
      [[ "$line" =~ ^#@AF:version= ]] && ver="${line#*=}"
      [[ "$line" =~ ^#@AF:uuid= ]]    && uuid="${line#*=}"
    done < <(head -n 15 "$f")
    [[ -n "$mod" ]] && printf "%s|%s|%s|%s|%s|%s|%s\n" "${mod,,}" "$name" "$desc" "$type" "$ver" "$uuid" "$f" >>"$AF_TAG_CACHE_FILE"
  done < <(find "$AF_BASE_DIR" -type f -name 'af_*.sh' 2>/dev/null)
}

# --- freshness check --------------------------------------------------------
_af_path_cache_stale() {
  [[ ! -f "$AF_TAG_CACHE_FILE" ]] && return 0
  local latest
  latest=$(find "$AF_BASE_DIR" -type f -name 'af_*.sh' -newer "$AF_TAG_CACHE_FILE" -print -quit 2>/dev/null)
  [[ -n "$latest" ]]
}

# --- lookup helpers ---------------------------------------------------------
af_path_lookup() {
  local mod="${1,,}"
  if _af_path_cache_stale; then
    af_path_scan_tags
  elif [[ ! -s "$AF_TAG_CACHE_FILE" ]]; then
    af_path_scan_tags
  fi
  awk -F'|' -v m="$mod" '$1==m {print $7; exit}' "$AF_TAG_CACHE_FILE"
}

# --- resolver ---------------------------------------------------------------
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
  _af_path_abs "$file"
}

# --- listings ---------------------------------------------------------------
af_path_list_modules() {
  _af_path_cache_stale && af_path_scan_tags
  awk -F'|' '$4=="core"{print $1}' "$AF_TAG_CACHE_FILE" | sort
}

af_path_list_plugins() {
  _af_path_cache_stale && af_path_scan_tags
  awk -F'|' '$4=="plugin"{print $1}' "$AF_TAG_CACHE_FILE" | sort
}

af_path_list_themes() {
  [[ -d "$AF_THEME_DIR" ]] || return
  find "$AF_THEME_DIR" -type f -name '*.theme' -exec basename {} .theme \; 2>/dev/null | sort
}

# --- utility short-cuts -----------------------------------------------------
af_path_cache_file() { printf '%s/%s.cache' "$AF_CACHE_DIR" "${1:-general}"; }
af_path_log_file()   { printf '%s/%s.log'   "$AF_LOG_DIR"   "${1:-session}"; }
af_path_tmp_file()   { printf '%s/%s.tmp'   "$AF_TMP_DIR"   "${1:-temp}"; }

# --- debug ------------------------------------------------------------------
af_path_debug() {
  echo "[AF:path] base = $AF_BASE_DIR"
  echo "[AF:path] plugins dir = $AF_PLUGIN_DIR"
  echo "[AF:path] themes dir  = $AF_THEME_DIR"
  echo "[AF:path] cached tags:"
  [[ -f "$AF_TAG_CACHE_FILE" ]] && head -n 10 "$AF_TAG_CACHE_FILE" || echo "  (no cache)"
}

# --- auto init --------------------------------------------------------------
if _af_path_cache_stale || [[ ! -s "$AF_TAG_CACHE_FILE" ]]; then
  af_path_scan_tags
fi
