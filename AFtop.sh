#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame Demo :: AFtop.sh
#  external example — live CPU + Memory monitor with theme switching
# ─────────────────────────────────────────────────────────────────────────────

#@AF:demo=AFtop
#@AF:desc=System monitor demo for AlienFrame (pure builtin I/O)
#@AF:version=1.1.0

# --- locate and initialize AlienFrame ---------------------------------------
AF_BASE_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AF_BASE_DIR

source "$AF_BASE_DIR/af_bootstrap.sh"
af_bootstrap_init default
af_require theme

# --- theme rotation ---------------------------------------------------------
AF_DEMO_THEMES=(ghostlight corrosion sunflower)
AF_DEMO_THEME_IDX=0
af_theme_use "${AF_DEMO_THEMES[$AF_DEMO_THEME_IDX]}"

# --- graceful cleanup -------------------------------------------------------
cleanup() {
  af_core_color_reset
  af_core_show_cursor
  af_core_clear
  af_io_writeln "[AFtop] exited cleanly."
}
trap cleanup EXIT

# --- static frame -----------------------------------------------------------
draw_frame() {
  af_core_clear
  af_core_hide_cursor
  af_draw_box "left-half"  "CPU"    "$AF_THEME"
  af_draw_box "right-half" "Memory" "$AF_THEME"

  read COLS ROWS _ _ _ _ FG BG BORDER ACCENT TEXT <<<"$(af_layout_color full "$AF_THEME")"
  af_core_color_fg "$BORDER"
  af_core_cursor "$ROWS" 1
  af_core_repeat "$COLS" " "
  af_core_color_reset
}

# --- system data readers ----------------------------------------------------
cpu_snapshot() {
  # outputs: total idle
  local a; read -r -a a </proc/stat
  local idle=$(( a[4] + a[5] ))
  local nonidle=$(( a[1] + a[2] + a[3] + a[6] + a[7] + a[8] ))
  local total=$(( idle + nonidle ))
  echo "$total $idle"
}

mem_snapshot() {
  # outputs: total_kb avail_kb
  local k v total=0 avail=0
  while IFS=' :' read -r k v _; do
    case "$k" in
      MemTotal)     total="$v" ;;
      MemAvailable) avail="$v" ;;
    esac
    (( total && avail )) && break
  done </proc/meminfo
  echo "$total $avail"
}

# --- helpers ----------------------------------------------------------------
color_for_pct() {
  local pct="$1"
  if   (( pct < 50 )); then echo 118
  elif (( pct < 80 )); then echo 220
  else                    echo 196
  fi
}

rpad() {
  local s="$1" w="$2"
  local pad=$(( w - ${#s} ))
  ((pad<0)) && pad=0
  af_io_write "$s"
  ((pad)) && af_core_repeat "$pad" " "
}

draw_bar() {
  local x="$1" y="$2" w="$3" pct="$4" color="$5"
  (( w < 3 )) && return
  local fill=$(( (w * pct) / 100 ))
  ((fill > w)) && fill="$w"
  local empty=$(( w - fill ))

  af_core_cursor "$y" "$x"
  af_core_color_fg "$color"; af_core_repeat "$fill" "█"
  af_core_color_fg 240;      af_core_repeat "$empty" "░"
  af_core_color_reset
}

calc_regions() {
  read _ _ wL hL xL yL _ _ _ ACCENTL TEXTL <<<"$(af_layout_color left-half "$AF_THEME")"
  CPU_X=$((xL+2)); CPU_Y=$((yL+2))
  CPU_W=$((wL-4)); CPU_H=$((hL-4))

  read _ _ wR hR xR yR _ _ _ ACCENTR TEXTR <<<"$(af_layout_color right-half "$AF_THEME")"
  MEM_X=$((xR+2)); MEM_Y=$((yR+2))
  MEM_W=$((wR-4)); MEM_H=$((hR-4))

  read COLS ROWS _ _ _ _ FG BG BORDER ACCENT TEXT <<<"$(af_layout_color full "$AF_THEME")"
  FT_Y="$ROWS"
}

draw_footer() {
  local now="$(date +%H:%M:%S)"
  local up;  read -r _ up _ </proc/uptime
  up="${up%.*}"
  local uh=$(( up/3600 ))
  local um=$(( (up%3600)/60 ))
  local ustr; printf -v ustr "%02dh:%02dm" "$uh" "$um"

  af_core_cursor "$FT_Y" 2
  af_core_color_fg 240
  local msg="Theme: $AF_THEME  •  Uptime: $ustr  •  Time: $now  •  [t] theme  [q] quit"
  rpad "$msg" "$((COLS-2))"
  af_core_color_reset
}

# --- main runtime loop ------------------------------------------------------
main() {
  draw_frame
  calc_regions
  read t0 i0 < <(cpu_snapshot)

  while :; do
    # CPU %
    read t1 i1 < <(cpu_snapshot)
    dt=$((t1 - t0)); di=$((i1 - i0)); ((dt<=0))&&dt=1
    cpu_pct=$(( 100 * (dt - di) / dt ))
    ((cpu_pct<0))&&cpu_pct=0; ((cpu_pct>100))&&cpu_pct=100
    t0=$t1; i0=$i1

    # MEM %
    read mt ma < <(mem_snapshot)
    mem_used_k=$(( mt - ma ))
    ((mt>0))&&pct_mem=$(( (mem_used_k * 100) / mt ))||pct_mem=0
    ((pct_mem>100))&&pct_mem=100

    # DRAW CPU
    local ccolor="$(color_for_pct "$cpu_pct")"
    af_core_color_fg "$ccolor"
    af_core_cursor "$CPU_Y" "$CPU_X"
    rpad "CPU: ${cpu_pct}%" "$CPU_W"
    draw_bar "$CPU_X" $((CPU_Y+1)) "$CPU_W" "$cpu_pct" "$ccolor"

    # DRAW MEM
    local mcolor="$(color_for_pct "$pct_mem")"
    local used_mb=$(( mem_used_k / 1024 ))
    local tot_mb=$(( mt / 1024 ))
    af_core_color_fg "$mcolor"
    af_core_cursor "$MEM_Y" "$MEM_X"
    rpad "MEM: ${pct_mem}%  (${used_mb}/${tot_mb} MB)" "$MEM_W"
    draw_bar "$MEM_X" $((MEM_Y+1)) "$MEM_W" "$pct_mem" "$mcolor"

    draw_footer

    # input — AlienFrame built-in
    local k; k="$(af_core_read_key)"
    case "$k" in
      q|Q) break ;;
      t|T)
        AF_DEMO_THEME_IDX=$(( (AF_DEMO_THEME_IDX + 1) % ${#AF_DEMO_THEMES[@]} ))
        af_theme_use "${AF_DEMO_THEMES[$AF_DEMO_THEME_IDX]}"
        draw_frame
        calc_regions
        ;;
      *) : ;;
    esac

    sleep 0.1
  done

  cleanup
}

main
