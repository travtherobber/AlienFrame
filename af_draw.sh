#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_draw.sh
#  drawing layer — boxes (minimal smoke-test version)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=draw
#@AF:name=af_draw.sh
#@AF:desc=Drawing and text rendering layer (af_io / af_core native, box-only)
#@AF:version=2.2.0
#@AF:type=core
#@AF:uuid=af_core_draw_boxonly_001

# --- DEPENDENCIES ------------------------------------------------------------
# We rely on: af_layout_geometry, af_layout_color, af_core_cursor, af_core_color_*
# and af_io_* already being available in a normal AF session.
# But we also include safe fallbacks so this file can be sourced directly.

# path + layout + core are normally provided by af_af/af_bootstrap
source "$(af_path_resolve module layout 2>/dev/null)" 2>/dev/null || true
source "$(af_path_resolve module core   2>/dev/null)" 2>/dev/null || true

# --- I/O FALLBACKS -----------------------------------------------------------
declare -F af_io_write   >/dev/null || af_io_write()   { builtin echo -n -- "$*"; }
declare -F af_io_writeln >/dev/null || af_io_writeln() { builtin echo -- "$*"; }
declare -F af_io_repeat  >/dev/null || af_io_repeat()  {
    local n="${1:-0}" ch="${2:- }"
    (( n > 0 )) || return 0
    while (( n-- > 0 )); do builtin echo -n "$ch"; done
}

# --- CORE SHIMS (if core not yet loaded) ------------------------------------
declare -F af_core_color_fg    >/dev/null || af_core_color_fg()    { af_io_write $'\033[38;5;'"$1"'m'; }
declare -F af_core_color_bg    >/dev/null || af_core_color_bg()    { af_io_write $'\033[48;5;'"$1"'m'; }
declare -F af_core_color_reset >/dev/null || af_core_color_reset() { af_io_write $'\033[0m'; }

# cursor shim (no printf, no stty)
declare -F af_core_cursor >/dev/null || af_core_cursor() {
    local row="${1:-1}" col="${2:-1}"
    (( row < 1 )) && row=1
    (( col < 1 )) && col=1
    echo -ne "\033[${row};${col}H" >/dev/tty 2>/dev/null || \
    af_io_write $'\033['"$row"';'"$col"'H'
}

# small wrapper so draw can depend on a repeat primitive name
af_draw_repeat() { af_io_repeat "$@"; }

# ─────────────────────────────────────────────────────────────────────────────
# BOX DRAWING
# ─────────────────────────────────────────────────────────────────────────────
# usage: af_draw_box REGION TITLE [THEME]
#   REGION: full | left-half | right-half | top-half | bottom-half | center-box | percent | custom:...
#   TITLE : optional string drawn in top border
#   THEME : theme name; defaults to $AF_THEME or "default"
# ─────────────────────────────────────────────────────────────────────────────
af_draw_box() {
    local region="${1:-center-box}"
    local title="${2:-}"
    local theme="${3:-${AF_THEME:-default}}"

    # geometry + colors
    local cols rows w h x y fg bg border accent text
    read cols rows w h x y fg bg border accent text <<<"$(af_layout_color "$region" "$theme" 2>/dev/null)"

    # sanity
    (( w < 4 || h < 3 )) && return 0

    local tl="┌" tr="┐" bl="└" br="┘" hz="─" vt="│"

    # apply border color
    af_core_color_fg "$border"

    # ── top border ───────────────────────────────────────────────────────────
    af_core_cursor "$y" "$x"
    af_io_write "$tl"
    af_draw_repeat $(( w - 2 )) "$hz"
    af_io_write "$tr"

    # ── vertical sides ───────────────────────────────────────────────────────
    local yy
    for (( yy = y + 1; yy < y + h - 1; yy++ )); do
        # left side
        af_core_cursor "$yy" "$x"
        af_io_write "$vt"

        # right side
        af_core_cursor "$yy" $(( x + w - 1 ))
        af_io_write "$vt"
    done

    # ── bottom border ────────────────────────────────────────────────────────
    af_core_cursor $(( y + h - 1 )) "$x"
    af_io_write "$bl"
    af_draw_repeat $(( w - 2 )) "$hz"
    af_io_write "$br"

    # ── optional title ───────────────────────────────────────────────────────
    if [[ -n "$title" ]]; then
        local maxlen=$(( w - 4 ))
        (( maxlen > 0 )) || maxlen=1
        af_core_cursor "$y" $(( x + 2 ))
        af_core_color_fg "$accent"
        af_io_write "${title:0:maxlen}"
        af_core_color_fg "$border"
    fi

    af_core_color_reset
}

# ─────────────────────────────────────────────────────────────────────────────
# END MODULE
