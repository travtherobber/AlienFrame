#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_term_size.sh (v3.1 — paste-safe)
#  Universal terminal size detection, no printf, no stty
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=term_size
#@AF:name=af_term_size.sh
#@AF:desc=Universal terminal size detection (triple fallback)
#@AF:version=3.1.0
#@AF:type=core
#@AF:uuid=af_core_term_size_003

af_term_size() {
    local cols="" rows="" resp=""

    # ── Save cursor
    echo -ne "\033[s" >/dev/tty 2>/dev/null
    # ── Move far bottom-right
    echo -ne "\033[999;999H" >/dev/tty 2>/dev/null
    # ── Request cursor position
    echo -ne "\033[6n" >/dev/tty 2>/dev/null

    # Expected: ESC [ rows ; cols R
    IFS='[;' read -t 0.05 -sdR resp rows cols 2>/dev/null

    # ── Restore cursor
    echo -ne "\033[u" >/dev/tty 2>/dev/null

    # ── If valid integers → success
    if [[ "$rows" =~ ^[0-9]+$ ]] && [[ "$cols" =~ ^[0-9]+$ ]]; then
        echo "$cols $rows"
        return 0
    fi

    # ── Fallback 2: environment variables
    if [[ "$COLUMNS" =~ ^[0-9]+$ ]] && [[ "$LINES" =~ ^[0-9]+$ ]]; then
        echo "$COLUMNS $LINES"
        return 0
    fi

    # ── Fallback 3: tput
    if command -v tput >/dev/null 2>&1; then
        cols="$(tput cols 2>/dev/null)"
        rows="$(tput lines 2>/dev/null)"
        if [[ "$cols" =~ ^[0-9]+$ ]] && [[ "$rows" =~ ^[0-9]+$ ]]; then
            echo "$cols $rows"
            return 0
        fi
    fi

    # ── Final fallback: safe defaults
    echo "80 24"
    return 0
}
