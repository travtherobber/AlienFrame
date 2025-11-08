#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_theme.sh
#  adaptive color theme registry / loader / preview
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=theme
#@AF:name=af_theme.sh
#@AF:desc=Color-profile and theme manager (adaptive + user layer)
#@AF:version=1.2.0
#@AF:type=core
#@AF:uuid=af_core_theme_003

# --- deps -------------------------------------------------------------------
source "$(af_path_resolve module io)"      2>/dev/null || true
source "$(af_path_resolve module layout)"  2>/dev/null || true
source "$(af_path_resolve module path)"    2>/dev/null || true

# --- globals ----------------------------------------------------------------
AF_THEME="${AF_THEME:-default}"
AF_THEME_LAST=""
AF_THEME_DIR="${AF_THEME_DIR:-$AF_BASE_DIR/themes}"
AF_USER_THEME_DIR="${AF_USER_THEME_DIR:-$HOME/.alienframe/themes}"

# --- ensure dirs exist ------------------------------------------------------
mkdir -p "$AF_THEME_DIR" "$AF_USER_THEME_DIR"

# --- internal helpers -------------------------------------------------------
_af_theme_ensure_default() {
  local def="$AF_THEME_DIR/default.theme"
  [[ -f "$def" ]] && return 0
  cat >"$def" <<'EOF'
# Default AlienFrame Theme
FG=15
BG=0
BORDER=240
ACCENT=118
TEXT=250
EOF
}

# --- color registry ---------------------------------------------------------
af_theme_register_globals() {
  AF_COLOR_FG="${AF_FG:-15}"
  AF_COLOR_BG="${AF_BG:-0}"
  AF_COLOR_BORDER="${AF_BORDER:-240}"
  AF_COLOR_ACCENT="${AF_ACCENT:-118}"
  AF_COLOR_TEXT="${AF_TEXT:-250}"
  export AF_COLOR_FG AF_COLOR_BG AF_COLOR_BORDER AF_COLOR_ACCENT AF_COLOR_TEXT
}

# --- theme switcher ---------------------------------------------------------
af_theme_use() {
  local name="$1" opt="${2:-}" path=""
  _af_theme_ensure_default

  # resolve through user layer first
  if [[ -f "$AF_USER_THEME_DIR/${name%.theme}.theme" ]]; then
    path="$AF_USER_THEME_DIR/${name%.theme}.theme"
  else
    path="$(af_path_resolve theme "$name")"
  fi

  # fuzzy fallback
  if [[ ! -f "$path" ]]; then
    local fallback
    fallback="$(find "$AF_THEME_DIR" "$AF_USER_THEME_DIR" -type f -name "*${name}*.theme" 2>/dev/null | head -n1)"
    [[ -n "$fallback" ]] && path="$fallback"
  fi

  [[ -f "$path" ]] || { af_io_writeln "theme not found: $name"; return 1; }

  AF_THEME_LAST="$AF_THEME"
  AF_THEME="$(basename "${path%.theme}")"
  af_layout_load_theme "$AF_THEME"
  af_theme_register_globals

  [[ "$opt" == "--quiet" ]] || af_io_writeln "🎨 theme switched → $AF_THEME"
}

# --- list -------------------------------------------------------------------
af_theme_list() {
  _af_theme_ensure_default
  local dirs=("$AF_THEME_DIR" "$AF_USER_THEME_DIR")
  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] || continue
    for f in "$d"/*.theme; do
      [[ -f "$f" ]] && af_io_writeln "• $(basename "${f%.theme}")"
    done
  done | sort -u
}

# --- preview ----------------------------------------------------------------
af_theme_preview() {
  local name="${1:-$AF_THEME}" path
  path="$(af_path_resolve theme "$name")"
  [[ -f "$path" ]] || { af_io_writeln "no theme: $name"; return 1; }

  af_io_writeln "┌──────────────────────────────────┐"
  af_io_writeln "│  AlienFrame Theme Preview        │"
  af_io_writeln "│──────────────────────────────────│"
  af_io_writeln "│ name: $name"
  af_io_writeln "│──────────────────────────────────│"

  local k v
  while IFS='=' read -r k v; do
    [[ -z "$k" || "$k" =~ ^# ]] && continue
    v="${v//[[:space:]]/}"
    local pad="$(printf '%-8s' "$k")"
    af_io_write "│ $pad "
    af_io_fg "$v"; af_io_write "████"
    af_io_reset; af_io_writeln "  ($v)"
  done <"$path"

  af_io_writeln "└──────────────────────────────────┘"
}

# --- reload / restore -------------------------------------------------------
af_theme_reload() {
  [[ -z "$AF_THEME" ]] && AF_THEME="default"
  af_layout_load_theme "$AF_THEME"
  af_theme_register_globals
  af_io_writeln "🔁 reloaded theme → $AF_THEME"
}

af_theme_restore() {
  [[ -n "$AF_THEME_LAST" ]] || { af_io_writeln "no previous theme"; return 1; }
  af_theme_use "$AF_THEME_LAST"
}

# --- init -------------------------------------------------------------------
_af_theme_ensure_default
af_layout_load_theme "$AF_THEME"
af_theme_register_globals
