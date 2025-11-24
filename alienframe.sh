#!/usr/bin/env bash
AF_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AF_BASE_DIR="$AF_ROOT"
AF_SRC="$AF_ROOT/src"

# Load All Modules (Fixed Order)
for m in io sh_compat term_size term_color term_input path core layout draw list input splash engine; do
  source "$AF_SRC/af_${m}.sh"
done

af_api_init() { 
  local theme="${1:-default}"; af_core_clear; af_core_hide_cursor
  if [[ -f "$AF_BASE_DIR/themes/$theme.theme" ]]; then
     export AF_THEME="$theme"; af_layout_load_theme "$theme"
  else
     mkdir -p "$AF_BASE_DIR/themes"
     printf "FG=123\nBG=232\nBORDER=24\nACCENT=46\nTEXT=51\n" > "$AF_BASE_DIR/themes/cyber.theme"
     export AF_THEME="cyber"; af_layout_load_theme "cyber"
  fi
}
af_api_panel() { af_engine_panel_add "$1" "$2" "$3" "$4" "default" "${6:-text}"; }
af_api_update() { af_engine_panel_update "$1" "$2"; }
af_api_focus() { AF_ENGINE_FOCUS="$1"; }
af_api_on_select() { AF_CB_SELECT="$1"; }
af_api_on_key() { AF_CB_KEY="$1"; }
af_api_on_input() { AF_CB_INPUT="$1"; }
af_api_on_change() { AF_CB_CHANGE="$1"; }
af_api_run() {
  local splash="${1:-0}"; local tsave
  if command -v stty >/dev/null; then tsave=$(stty -g); stty -icanon -echo min 0 time 0; fi
  trap "af_core_show_cursor; af_core_clear; [[ -n '$tsave' ]] && stty '$tsave'; exit" EXIT SIGINT
  if (( splash )); then af_splash_show; sleep 0.5; fi
  af_engine_run
  af_core_show_cursor; af_core_clear; if [[ -n "$tsave" ]]; then stty "$tsave"; fi
}
af_api_geometry() {
  local c r; read c r <<<"$(af_core_size)"
  ((c<20)) && c=80; ((r<10)) && r=24
  echo "COLS=$c ROWS=$r HALF_W=$((c/2)) HALF_H=$((r/2))"
}
