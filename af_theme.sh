#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_theme.sh
#  theme registry / loader / switcher
#  (simple palette logic + I/O-safe theme access)
# ─────────────────────────────────────────────────────────────────────────────

# --- deps -------------------------------------------------------------------
source "$(af_path_resolve module io)" 2>/dev/null || true
source "$(af_path_resolve module layout)" 2>/dev/null || true

# --- THEME REGISTRY ---------------------------------------------------------
AF_THEME="${AF_THEME:-default}"
AF_THEME_LAST=""

# af_theme_use <name>
# Switch to a theme (loads ./themes/<name>.theme)
af_theme_use() {
  local name="${1:-default}" path
  path="$(af_path_resolve theme "$name")"

  if [[ ! -f "$path" ]]; then
    af_io_log "theme not found: $name ($path)"
    return 1
  fi

  AF_THEME_LAST="$AF_THEME"
  AF_THEME="$name"
  af_layout_load_theme "$name"
  af_io_writeln "🎨 theme switched → $AF_THEME"
}

# af_theme_list
# Lists available themes by name
af_theme_list() {
  local d="$AF_THEME_DIR"
  [[ -d "$d" ]] || { af_io_writeln "no themes directory ($d)"; return 1; }
  local f
  for f in "$d"/*.theme; do
    [[ -f "$f" ]] || continue
    af_io_writeln "$(basename "${f%.theme}")"
  done
}

# af_theme_preview [name]
# Preview a theme's colors (border/accent/text swatches)
af_theme_preview() {
  local name="${1:-$AF_THEME}"
  local path; path="$(af_path_resolve theme "$name")"
  [[ -f "$path" ]] || { af_io_writeln "no theme: $name"; return 1; }

  af_io_writeln "┌──────────────────────────────┐"
  af_io_writeln "│  AlienFrame Theme Preview    │"
  af_io_writeln "│──────────────────────────────│"
  af_io_writeln "│ name: $name"
  af_io_writeln "│──────────────────────────────│"
  local k v
  while IFS='=' read -r k v; do
    [[ -z "$k" || "$k" =~ ^# ]] && continue
    af_io_write "│ "
    case "$k" in
      FG) af_io_write "FG     "; af_io_fg "$v" ;;
      BG) af_io_write "BG     "; af_io_bg "$v" ;;
      BORDER) af_io_write "BORDER "; af_io_fg "$v" ;;
      ACCENT) af_io_write "ACCENT "; af_io_fg "$v" ;;
      TEXT) af_io_write "TEXT   "; af_io_fg "$v" ;;
    esac
    af_io_write "█▓▒░"
    af_io_reset
    af_io_writeln "  ($v)"
  done < "$path"
  af_io_writeln "└──────────────────────────────┘"
}

# af_theme_reload
# Reloads the current theme (for runtime updates)
af_theme_reload() {
  [[ -z "$AF_THEME" ]] && AF_THEME="default"
  af_layout_load_theme "$AF_THEME"
  af_io_writeln "🔁 reloaded theme → $AF_THEME"
}

# --- default initialization -------------------------------------------------
[[ -z "$AF_THEME" ]] && AF_THEME="default"
af_layout_load_theme "$AF_THEME"

# --- END MODULE -------------------------------------------------------------
