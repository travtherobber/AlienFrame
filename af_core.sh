#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_core.sh
#  terminal primitives — colors, cursor, input, and screen utilities (af_io-based)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=core
#@AF:name=af_core.sh
#@AF:desc=Terminal primitives (color, cursor, input, and screen utilities)
#@AF:version=1.2.0
#@AF:type=core
#@AF:uuid=af_core_term_002

# --- DEPENDENCY -------------------------------------------------------------
# shellcheck source=/dev/null
source "$(af_path_resolve module io)" || {
  echo "[AF:core] missing io layer — activating fallback I/O" >&2
  af_io_write()   { builtin echo -n "$*"; }
  af_io_writeln() { builtin echo "$*"; }
  af_io_repeat()  { local n="$1" ch="${2:- }"; for((i=0;i<n;i++));do builtin echo -n "$ch";done; }
}

# --- COLOR UTILITIES --------------------------------------------------------
af_core_color_reset() { af_io_reset; }
af_core_color_fg()    { [[ $1 =~ ^[0-9]+$ ]] && af_io_fg "$1"; }
af_core_color_bg()    { [[ $1 =~ ^[0-9]+$ ]] && af_io_bg "$1"; }

af_core_bold()       { af_io_bold; }
af_core_dim()        { af_io_dim; }
af_core_underline()  { af_io_underline; }

af_core_apply_default_theme() {
  AF_FG=250 AF_BG=0 AF_BORDER=240 AF_ACCENT=118 AF_TEXT=250
}

# --- CURSOR + SCREEN --------------------------------------------------------
af_core_cursor()      { local r="$1" c="$2"; af_io_cursor "$r" "$c"; }
af_core_clear()       { af_io_clear_screen; }
af_core_hide_cursor() { af_io_hide_cursor; }
af_core_show_cursor() { af_io_show_cursor; }

# --- TEXT + WRAP ------------------------------------------------------------
af_core_repeat() {
  local n="$1" ch="${2:- }"
  (( n <= 0 )) && return
  af_io_repeat "$n" "$ch"
}

af_core_wrap_text() {
  local text="$1" width="${2:-80}" line=""
  for word in $text; do
    if (( ${#line} + ${#word} + 1 > width )); then
      af_io_writeln "$line"
      line="$word"
    else
      line="${line:+$line }$word"
    fi
  done
  [[ -n $line ]] && af_io_writeln "$line"
}

# --- INTERNAL SIZE PROBE (no stty, no printf) -------------------------------
# uses pure cursor queries + ANSI responses
af_core_size() {
  local resp row col
  if [[ -t 1 ]]; then
    # save cursor, move far corner, query
    af_io_esc "7"
    af_io_csi "9999;9999H"
    af_io_csi "6n" > /dev/tty
    IFS=R read -r -t 0.05 resp 2>/dev/null
    af_io_esc "8"
    resp="${resp##*[}"
    row="${resp%%;*}"
    col="${resp##*;}"
  fi

  # fallback if unreadable
  if [[ -z $row || -z $col || ! $row =~ ^[0-9]+$ || ! $col =~ ^[0-9]+$ ]]; then
    row=24 col=80
  fi

  af_io_writeln "$col $row"
}

# --- INPUT HANDLING ---------------------------------------------------------
af_core_read_key() {
  local k seq
  IFS= read -rsn1 k 2>/dev/null || return
  case "$k" in
    $'\e')
      read -rsn2 -t 0.001 seq 2>/dev/null
      case "$seq" in
        '[A') af_io_writeln UP ;;
        '[B') af_io_writeln DOWN ;;
        '[C') af_io_writeln RIGHT ;;
        '[D') af_io_writeln LEFT ;;
        '[Z') af_io_writeln SHIFT_TAB ;;
        *)    af_io_writeln ESC ;;
      esac ;;
    $'\t') af_io_writeln TAB ;;
    [qQ])  af_io_writeln Q ;;
    [jJ])  af_io_writeln J ;;
    [kK])  af_io_writeln K ;;
    [pP])  af_io_writeln P ;;
    *)     af_io_writeln "$k" ;;
  esac
}

# --- COLOR SUPPORT DETECTION ------------------------------------------------
af_core_supports_color() {
  [[ -t 1 ]] || return 1
  [[ "$TERM" =~ (color|xterm|screen|tmux|foot|alacritty) ]] && return 0
  return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# END MODULE
