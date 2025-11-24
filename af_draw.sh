#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_draw.sh (v3.2 - Tech HUD)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=draw
#@AF:name=af_draw.sh
#@AF:desc=Drawing layer with Tech/HUD borders
#@AF:version=3.2.0
#@AF:type=core
#@AF:uuid=af_core_draw_320

source "$(af_path_resolve module layout 2>/dev/null)" 2>/dev/null || true
source "$(af_path_resolve module core   2>/dev/null)" 2>/dev/null || true

# --- I/O FALLBACKS -----------------------------------------------------------
declare -F af_io_write   >/dev/null || af_io_write()   { builtin echo -n -- "$*"; }
declare -F af_io_repeat  >/dev/null || af_io_repeat()  {
    local n="${1:-0}" ch="${2:- }"
    (( n > 0 )) || return 0
    while (( n-- > 0 )); do builtin echo -n "$ch"; done
}

# --- CORE SHIMS -------------------------------------------------------------
declare -F af_core_color_fg    >/dev/null || af_core_color_fg()    { af_io_write $'\033[38;5;'"$1"'m'; }
declare -F af_core_color_reset >/dev/null || af_core_color_reset() { af_io_write $'\033[0m'; }
declare -F af_core_cursor      >/dev/null || af_core_cursor()      { af_io_write $'\033['"${1:-1}";'"${2:-1}"H'; }
af_draw_repeat() { af_io_repeat "$@"; }

# ─────────────────────────────────────────────────────────────────────────────
# BOX DRAWING (HUD STYLE)
# ─────────────────────────────────────────────────────────────────────────────
af_draw_box() {
    local region="${1:-center-box}"
    local title="${2:-}"
    local theme="${3:-${AF_THEME:-default}}"
    local override="${4:-}"  # Focus highlight

    local cols rows w h x y fg bg border accent text
    read cols rows w h x y fg bg border accent text <<<"$(af_layout_color "$region" "$theme" 2>/dev/null)"

    (( w < 4 || h < 3 )) && return 0

    # --- HUD LOGIC ---
    local tl tr bl br hz vt l_tee r_tee
    
    if [[ -n "$override" ]]; then
        # FOCUSED: Heavy Lines + Bright Color
        border="$override"
        tl="┏" tr="┓" bl="┗" br="┛" hz="━" vt="┃"
        l_tee="┫" r_tee="┣" # Inverted look for title
    else
        # UNFOCUSED: Thin Lines
        tl="┌" tr="┐" bl="└" br="┘" hz="─" vt="│"
        l_tee="┤" r_tee="├"
    fi

    af_core_color_fg "$border"

    # Top Border
    af_core_cursor "$y" "$x"; af_io_write "$tl"
    af_draw_repeat $(( w - 2 )) "$hz"
    af_io_write "$tr"

    # Sides
    local yy
    for (( yy = y + 1; yy < y + h - 1; yy++ )); do
        af_core_cursor "$yy" "$x"; af_io_write "$vt"
        af_core_cursor "$yy" $(( x + w - 1 )); af_io_write "$vt"
    done

    # Bottom Border
    af_core_cursor $(( y + h - 1 )) "$x"; af_io_write "$bl"
    af_draw_repeat $(( w - 2 )) "$hz"
    af_io_write "$br"

    # Tech Title Bar
    if [[ -n "$title" ]]; then
        local maxlen=$(( w - 6 ))
        (( maxlen > 0 )) || maxlen=1
        
        # Center the title tech-style
        local t_start=$(( x + 2 ))
        
        af_core_cursor "$y" "$t_start"
        af_core_color_fg "$border"
        af_io_write "$l_tee "
        
        if [[ -n "$override" ]]; then
             af_core_color_fg "$override"; af_core_bold
        else
             af_core_color_fg "$accent"
        fi
        
        af_io_write "${title:0:maxlen}"
        af_core_color_reset
        
        af_core_color_fg "$border"
        af_io_write " $r_tee"
    fi

    af_core_color_reset
}