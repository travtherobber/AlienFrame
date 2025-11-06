#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_theme.sh
#  theme registry / loader / switcher / preview
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=theme
#@AF:name=af_theme.sh
#@AF:desc=Color-profile and theme manager for AlienFrame
#@AF:version=1.1.0
#@AF:type=core
#@AF:uuid=af_core_theme_002

# --- deps -------------------------------------------------------------------
source "$(af_path_resolve module io)"      2>/dev/null || true
source "$(af_path_resolve module layout)"  2>/dev/null || true
source "$(af_path_resolve module path)"    2>/dev/null || true

# --- globals ----------------------------------------------------------------
AF_THEME="${AF_THEME:-default}"
AF_THEME_LAST=""
AF_THEME_DIR="${AF_THEME_DIR:-$AF_BASE_DIR/themes}"

# --- internal helpers -------------------------------------------------------
_af_theme_ensure_default() {
  local def="$AF_THEME_DIR/default.theme"
  [[ -f "$def" ]] && return 0
  mkdir -p "$AF_THEME_DIR"
  cat >"$def" <<'EOF'
# Default AlienFrame Theme
FG=15
BG=0
BORDER=240
ACCENT=118
TEXT=250
EOF
}

# --- theme switcher ---------------------------------------------------------
af_theme_use() {
  local name="${1:-default}" path
  _af_theme_ensure_default
  path="$(af_path_resolve theme "$name")"

  if [[ ! -f "$path" ]]; then
    # fuzzy match
    local fallback
    fallback="$(find "$AF_THEME_DIR" -maxdepth 1 -type f -name "*${name}*.theme" | head -n1)"
    if [[ -z "$fallback" ]]; then
      af_io_log "theme not found: $name ($path)"
      return 1
    fi
    path="$fallback"
    name="$(basename "${fallback%.theme}")"
  fi

  AF_THEME_LAST="$AF_THEME"
  AF_THEME="$name"
  af_layout_load_theme "$name"
  [[ -t 1 ]] && af_io_writeln "🎨 theme switched → $AF_THEME"
}

# --- list -------------------------------------------------------------------
af_theme_list() {
  _af_theme_ensure_default
  [[ -d "$AF_THEME_DIR" ]] || { af_io_writeln "no themes directory ($AF_THEME_DIR)"; return 1; }
  local f
  for f in "$AF_THEME_DIR"/*.theme; do
    [[ -f "$f" ]] && af_io_writeln "• $(basename "${f%.theme}")"
  done
}

# --- preview ----------------------------------------------------------------
af_theme_preview() {
  local name="${1:-$AF_THEME}" path
  path="$(af_path_resolve theme "$name")"
  [[ -f "$path" ]] || { af_io_writeln "no theme: $name"; return 1; }

  af_io_writeln "┌────────────────────────────────┐"
  af_io_writeln "│  AlienFrame Theme Preview      │"
  af_io_writeln "│────────────────────────────────│"
  af_io_writeln "│ name: $name"
  af_io_writeln "│────────────────────────────────│"
  local k v
  while IFS='=' read -r k v; do
    [[ -z "$k" || "$k" =~ ^# ]] && continue
    local pad="$(printf '%-8s' "$k")"
    af_io_write "│ $pad "
    case "$k" in
      FG)     af_io_fg "$v" ;;
      BG)     af_io_bg "$v" ;;
      BORDER) af_io_fg "$v" ;;
      ACCENT) af_io_fg "$v" ;;
      TEXT)   af_io_fg "$v" ;;
    esac
    af_io_write "█▓▒░"
    af_io_reset
    af_io_writeln "  ($v)"
  done <"$path"
  af_io_writeln "└────────────────────────────────┘"
}

# --- reload / restore -------------------------------------------------------
af_theme_reload() {
  [[ -z "$AF_THEME" ]] && AF_THEME="default"
  af_layout_load_theme "$AF_THEME"
  [[ -t 1 ]] && af_io_writeln "🔁 reloaded theme → $AF_THEME"
}

af_theme_restore() {
  [[ -n "$AF_THEME_LAST" ]] || { af_io_writeln "no previous theme"; return 1; }
  af_theme_use "$AF_THEME_LAST"
}

# --- init -------------------------------------------------------------------
_af_theme_ensure_default
af_layout_load_theme "$AF_THEME"

# ─────────────────────────────────────────────────────────────────────────────

