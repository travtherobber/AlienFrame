#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame :: af_term_color.sh
#  minimal ANSI color + text style controls (pure built-in)
# ─────────────────────────────────────────────────────────────────────────────
#@AF:module=term_color
#@AF:name=af_term_color.sh
#@AF:desc=ANSI 256-color control and text style utilities
#@AF:version=1.0.0
#@AF:type=core
#@AF:uuid=af_core_term_color_001

# --- BASIC COLOR + STYLE FUNCTIONS -------------------------------------------
af_term_color_reset()    { builtin echo -ne "\033[0m"; }
af_term_color_fg()       { [[ $1 =~ ^[0-9]+$ ]] && builtin echo -ne "\033[38;5;${1}m"; }
af_term_color_bg()       { [[ $1 =~ ^[0-9]+$ ]] && builtin echo -ne "\033[48;5;${1}m"; }

af_term_bold()           { builtin echo -ne "\033[1m"; }
af_term_dim()            { builtin echo -ne "\033[2m"; }
af_term_italic()         { builtin echo -ne "\033[3m"; }
af_term_underline()      { builtin echo -ne "\033[4m"; }
af_term_blink()          { builtin echo -ne "\033[5m"; }
af_term_reverse()        { builtin echo -ne "\033[7m"; }
af_term_hidden()         { builtin echo -ne "\033[8m"; }

# --- CURSOR VISIBILITY / CONTROL ---------------------------------------------
af_term_hide_cursor()    { builtin echo -ne "\033[?25l"; }
af_term_show_cursor()    { builtin echo -ne "\033[?25h"; }
af_term_cursor()         { builtin echo -ne "\033[${1};${2}H"; }

# --- SCREEN / LINE CLEARING --------------------------------------------------
af_term_clear_screen()   { builtin echo -ne "\033[2J"; }
af_term_clear_line()     { builtin echo -ne "\033[2K"; }

# --- UTILITY: color test grid ------------------------------------------------
af_term_palette_demo() {
  echo " AlienFrame 256-Color Grid"
  for ((i=0;i<256;i++)); do
    [[ $((i % 16)) -eq 0 ]] && echo
    printf "\033[48;5;%sm %3s \033[0m" "$i" "$i"
  done
  echo -e "\n"
}

# --- DEFAULT THEME EXPORT ----------------------------------------------------
af_term_apply_default_theme() {
  AF_FG=250 AF_BG=0 AF_BORDER=240 AF_ACCENT=118 AF_TEXT=250
}

# --- END MODULE --------------------------------------------------------------
