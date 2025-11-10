#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame Demo :: AFtop v2
#  Rewritten — fully live CPU + Memory monitor using AlienFrame core
# ─────────────────────────────────────────────────────────────────────────────

AF_BASE_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AF_BASE_DIR

source "$AF_BASE_DIR/af_bootstrap.sh"
af_bootstrap_init default
af_require theme

# themes
AF_DEMO_THEMES=(ghostlight corrosion sunflower)
AF_DEMO_THEME_IDX=0
af_theme_use "${AF_DEMO_THEMES[$AF_DEMO_THEME_IDX]}"

cleanup() {
  af_core_show_cursor
  af_core_color_reset
  af_core_clear
  af_io_writeln "[AFtop] exited cleanly."
}
trap cleanup EXIT

# --- utilities ---------------------------------------------------------------
cpu_snapshot() {
  local a; read -r -a a </proc/stat
  local idle=$(( a[4] + a[5] ))
  local nonidle=$(( a[1] + a[2] + a[3] + a[6] + a[7] + a[8] ))
  echo "$((idle + nonidle)) $idle"
}

mem_snapshot() {
  local k v total=0 avail=0
  while IFS=' :' read -r k v _; do
    case "$k" in
      MemTotal) total="$v" ;;
      MemAvailable) avail="$v" ;;
    esac
    (( total && avail )) && break
  done </proc/meminfo
  echo "$total $avail"
}

color_for_pct() {
  (( $1 < 50 )) && echo 118 && return
  (( $1 < 80 )) && echo 220 && return
  echo 196
}

rpad() {
  local s="$1" w="$2"; local pad=$((w - ${#s}))
  ((pad<0)) && pad=0
  af_io_write "$s"; ((pad)) && af_core_repeat "$pad" " "
}

draw_bar() {
  local x="$1" y="$2" w="$3" pct="$4" color="$5"
  local fill=$(( w * pct / 100 ))
  ((fill>w)) && fill=w
  local empty=$(( w - fill ))
  af_core_cursor "$y" "$x"
  af_core_color_fg "$color"; af_core_repeat "$fill" "█"
  af_core_color_fg 240;      af_core_repeat "$empty" "░"
  af_core_color_reset
}

# --- layout -----------------------------------------------------------------
calc_regions() {
  read _ _ wL hL xL yL _ _ _ _ _ <<<"$(af_layout_color left-half "$AF_THEME")"
  CPU_X=$((xL+2)); CPU_Y=$((yL+2)); CPU_W=$((wL-4))
  read _ _ wR hR xR yR _ _ _ _ _ <<<"$(af_layout_color right-half "$AF_THEME")"
  MEM_X=$((xR+2)); MEM_Y=$((yR+2)); MEM_W=$((wR-4))
  read COLS ROWS _ _ _ _ _ _ BORDER ACCENT _ <<<"$(af_layout_color full "$AF_THEME")"
  FT_Y="$ROWS" BORDER="$BORDER" ACCENT="$ACCENT"
}

draw_static() {
  af_core_clear; af_core_hide_cursor
  af_draw_box left-half  "CPU"    "$AF_THEME"
  af_draw_box right-half "Memory" "$AF_THEME"
  calc_regions
}

draw_footer() {
  local now=$(date +%H:%M:%S)
  local up; read -r _ up _ </proc/uptime; up=${up%.*}
  local uh=$((up/3600)) um=$(( (up%3600)/60 ))
  printf -v upfmt "%02dh:%02dm" "$uh" "$um"

  af_core_cursor "$FT_Y" 2
  af_core_color_fg 240
  local msg="Theme: $AF_THEME  •  Uptime: $upfmt  •  Time: $now  •  [t] theme  [q] quit"
  rpad "$msg" "$((COLS-2))"
  af_core_color_reset
}

# --- main loop --------------------------------------------------------------
main() {
  draw_static
  read t0 i0 < <(cpu_snapshot)

  while :; do
    # --- CPU ---
    read t1 i1 < <(cpu_snapshot)
    local dt=$((t1 - t0)) di=$((i1 - i0))
    ((dt<=0)) && dt=1
    local cpu_pct=$(( 100 * (dt - di) / dt ))
    ((cpu_pct<0)) && cpu_pct=0; ((cpu_pct>100)) && cpu_pct=100
    t0=$t1; i0=$i1

    # --- MEM ---
    read mt ma < <(mem_snapshot)
    local used=$((mt - ma))
    local mem_pct=$(( mt ? (used * 100 / mt) : 0 ))
    ((mem_pct>100)) && mem_pct=100

    # --- draw bars ---
    local ccolor=$(color_for_pct "$cpu_pct")
    af_core_cursor "$CPU_Y" "$CPU_X"
    af_core_color_fg "$ccolor"
    rpad "CPU: ${cpu_pct}%" "$CPU_W"
    draw_bar "$CPU_X" $((CPU_Y+1)) "$CPU_W" "$cpu_pct" "$ccolor"

    local mcolor=$(color_for_pct "$mem_pct")
    local used_mb=$((used / 1024)) total_mb=$((mt / 1024))
    af_core_cursor "$MEM_Y" "$MEM_X"
    af_core_color_fg "$mcolor"
    rpad "MEM: ${mem_pct}%  (${used_mb}/${total_mb} MB)" "$MEM_W"
    draw_bar "$MEM_X" $((MEM_Y+1)) "$MEM_W" "$mem_pct" "$mcolor"

    draw_footer

    # --- keys ---
    local k; k="$(af_core_read_key)"
    case "$k" in
      q|Q) break ;;
      t|T)
        AF_DEMO_THEME_IDX=$(( (AF_DEMO_THEME_IDX + 1) % ${#AF_DEMO_THEMES[@]} ))
        af_theme_use "${AF_DEMO_THEMES[$AF_DEMO_THEME_IDX]}"
        draw_static
        ;;
      *) : ;;
    esac

    sleep 0.1
  done
}

main
