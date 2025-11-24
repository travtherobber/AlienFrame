#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_path.sh
#  dynamic path + tag-aware resolver for modules, plugins, and themes
#  adaptive version — supports multi-profile and user-layer overrides
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=path
#@AF:name=af_path.sh
#@AF:desc=Dynamic path resolver with tag indexing, caching, and layering
#@AF:version=1.3.0
#@AF:type=core
#@AF:uuid=af_core_path_004

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

# --- subdirs (repo + user layers) -------------------------------------------
AF_PLUGIN_DIR="${AF_PLUGIN_DIR:-$AF_BASE_DIR/plugins}"
AF_THEME_DIR="${AF_THEME_DIR:-$AF_BASE_DIR/themes}"
AF_CACHE_DIR="${AF_CACHE_DIR:-$AF_BASE_DIR/.cache}"
AF_LOG_DIR="${AF_LOG_DIR:-$AF_BASE_DIR/.logs}"
AF_TMP_DIR="${AF_TMP_DIR:-/tmp/alienframe}"

# optional user-layer
AF_USER_DIR="${AF_USER_DIR:-$HOME/.alienframe}"
AF_USER_PLUGIN_DIR="$AF_USER_DIR/plugins"
AF_USER_THEME_DIR="$AF_USER_DIR/themes"

mkdir -p "$AF_PLUGIN_DIR" "$AF_THEME_DIR" "$AF_CACHE_DIR" "$AF_LOG_DIR" "$AF_TMP_DIR"
mkdir -p "$AF_USER_PLUGIN_DIR" "$AF_USER_THEME_DIR" 2>/dev/null || true

AF_TAG_CACHE_FILE="$AF_CACHE_DIR/af_tags.index"

# --- helper: absolute path ---------------------------------------------------
_af_path_abs() {
  local p="$1"
  [[ "$p" == /* ]] && printf '%s\n' "$p" && return
  printf '%s/%s\n' "$PWD" "${p#./}"
}

# --- tag scan ---------------------------------------------------------------
af_path_scan_tags() {
  local tmp="$AF_TAG_CACHE_FILE.tmp"
  : >"$tmp"
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
    done < <(head -n 15 "$f" 2>/dev/null)
    [[ -n "$mod" && -n "$f" ]] && printf "%s|%s|%s|%s|%s|%s|%s\n" "${mod,,}" "$name" "$desc" "$type" "$ver" "$uuid" "$f" >>"$tmp"
  done < <(find "$AF_BASE_DIR" -type f -name 'af_*.sh' 2>/dev/null)
  mv -f "$tmp" "$AF_TAG_CACHE_FILE"
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
  (_af_path_cache_stale || [[ ! -s "$AF_TAG_CACHE_FILE" ]]) && af_path_scan_tags
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
      if [[ -f "$AF_USER_PLUGIN_DIR/$name/af_${name}.sh" ]]; then
        file="$AF_USER_PLUGIN_DIR/$name/af_${name}.sh"
      else
        file="$AF_PLUGIN_DIR/$name/af_${name}.sh"
      fi
      ;;
    theme)
      if [[ -f "$AF_USER_THEME_DIR/${name%.theme}.theme" ]]; then
        file="$AF_USER_THEME_DIR/${name%.theme}.theme"
      else
        file="$AF_THEME_DIR/${name%.theme}.theme"
      fi
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
  find "$AF_THEME_DIR" "$AF_USER_THEME_DIR" -type f -name '*.theme' -exec basename {} .theme \; 2>/dev/null | sort -u
}

# --- utility short-cuts -----------------------------------------------------
af_path_cache_file() { printf '%s/%s.cache\n' "$AF_CACHE_DIR" "${1:-general}"; }
af_path_log_file()   { printf '%s/%s.log\n'   "$AF_LOG_DIR"   "${1:-session}"; }
af_path_tmp_file()   { printf '%s/%s.tmp\n'   "$AF_TMP_DIR"   "${1:-temp}"; }

# --- debug ------------------------------------------------------------------
af_path_debug() {
  {
    echo "[AF:path] base = $AF_BASE_DIR"
    echo "[AF:path] plugins = $AF_PLUGIN_DIR"
    echo "[AF:path] themes  = $AF_THEME_DIR"
    echo "[AF:path] user-layer = $AF_USER_DIR"
    echo "[AF:path] cached tags:"
    [[ -f "$AF_TAG_CACHE_FILE" ]] && head -n 10 "$AF_TAG_CACHE_FILE" || echo "  (no cache)"
  } >&2
}

# --- auto init --------------------------------------------------------------
if _af_path_cache_stale || [[ ! -s "$AF_TAG_CACHE_FILE" ]]; then
  af_path_scan_tags
fi
