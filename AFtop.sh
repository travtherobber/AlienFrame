#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AlienFrame Demo :: AFtop.sh
#  live CPU + Memory monitor demo with theme switching
# ─────────────────────────────────────────────────────────────────────────────
#@AF:demo=AFtop
#@AF:desc=System monitor demo for AlienFrame
#@AF:version=1.1.0

# --- locate and source AlienFrame -------------------------------------------
AF_BASE_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AF_BASE_DIR
source "$AF_BASE_DIR/af_bootstrap.sh"
af_bootstrap_init default
af_require theme draw layout core io

# --- default theme rotation --------------------------------------------------
AF_DEMO_THEMES=(ghostlight corrosion sunflower)
AF_DEMO_THEME_IDX=0
af_theme_use "${AF_DEMO_THEMES[$AF_DEMO_THEME_IDX]}"

# --- graceful cleanup --------------------------------------------------------
cleanup() {
  af_core_color_reset
  af_core_show_cursor
  af_core_clear
  stty "$stty_state" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# --- static frame ------------------------------------------------------------
draw_frame() {
  af_core_clear
  af_core_hide_cursor
  af_draw_box "left-half"  "CPU"    "$AF_THEME"
  af_draw_box "right-half" "Memory" "$AF_THEME"

  read cols rows _ _ _ _ FG BG BORDER ACCENT TEXT <<<"$(af_layout_color full "$AF_THEME")"
  af_core_color_fg "$BORDER"
  af_core_cursor "$rows" 1
  af_core_repeat "$cols" " "
  af_core_color_reset
}

# --- platform-safe stats readers --------------------------------------------
cpu_snapshot() {
  if [[ -r /proc/stat ]]; then
    local a; read -r -a a </proc/stat
    local idle=$(( a[4] + a[5] ))
    local nonidle=$(( a[1] + a[2] + a[3] + a[6] + a[7] + a[8] ))
    echo $((idle + nonidle)) $idle
  else
    # fallback for non-Linux (dummy increasing counters)
    echo $((RANDOM%10000+10000)) $((RANDOM%5000))
  fi
}

mem_snapshot() {
  if [[ -r /proc/meminfo ]]; then
    local k v total=0 avail=0
    while IFS=' :' read -r k v _; do
      case "$k" in
        MemTotal)     total="$v" ;;
        MemAvailable) avail="$v" ;;
      esac
      (( total && avail )) && break
    done </proc/meminfo
    echo "$total" "$avail"
  else
    # macOS/BSD fallback (via sysctl if available)
    local total avail
    total=$(sysctl -n hw.memsize 2>/dev/null || echo 8388608)
    avail=$(( total * 60 / 100 )) # pretend 40% used
    echo $((total/1024)) $((avail/1024))
  fi
}

# --- helpers -----------------------------------------------------------------
color_for_pct() {
  local p="$1"
  ((p<50)) && echo 118 && return
  ((p<80)) && echo 220 && return
  echo 196
}

rpad() {
  local s="$1" w="$2"; local pad=$(( w - ${#s} ))
  ((pad<0)) && pad=0
  af_io_write "$s"; ((pad)) && af_core_repeat "$pad" " "
}

draw_bar() {
  local x="$1" y="$2" w="$3" pct="$4" color="$5"
  (( w < 3 )) && return
  local fill=$(( (w * pct) / 100 ))
  ((fill>w)) && fill="$w"
  local empty=$(( w - fill ))

  af_core_cursor "$y" "$x"
  af_core_color_fg "$color"; af_core_repeat "$fill" "█"
  af_core_color_fg 240; af_core_repeat "$empty" "░"
  af_core_color_reset
}

calc_regions() {
  read _ _ wL hL xL yL _ _ _ ACCENTL TEXTL <<<"$(af_layout_color left-half "$AF_THEME")"
  CPU_X=$((xL+2)); CPU_Y=$((yL+2)); CPU_W=$((wL-4)); CPU_H=$((hL-4))

  read _ _ wR hR xR yR _ _ _ ACCENTR TEXTR <<<"$(af_layout_color right-half "$AF_THEME")"
  MEM_X=$((xR+2)); MEM_Y=$((yR+2)); MEM_W=$((wR-4)); MEM_H=$((hR-4))

  read COLS ROWS _ _ _ _ FG BG BORDER ACCENT TEXT <<<"$(af_layout_color full "$AF_THEME")"
  FT_Y="$ROWS"
}

draw_footer() {
  local now up uh um ustr
  now="$(date +%H:%M:%S)"
  if [[ -r /proc/uptime ]]; then
    read -r up _ </proc/uptime; up="${up%.*}"
  else
    up=$SECONDS
  fi
  uh=$(( up/3600 )); um=$(( (up%3600)/60 ))
  printf -v ustr "%02dh:%02dm" "$uh" "$um"

  af_core_cursor "$FT_Y" 2
  af_core_color_fg 240
  local msg="Theme: $AF_THEME  •  Uptime: $ustr  •  Time: $now  •  [t] theme  [q] quit"
  rpad "$msg" "$((COLS-2))"
  af_core_color_reset
}

# --- main loop ---------------------------------------------------------------
main() {
  draw_frame; calc_regions
  read t0 i0 < <(cpu_snapshot)
  stty_state="$(stty -g 2>/dev/null || true)"
  stty -icanon -echo min 0 time 1 2>/dev/null || true

  local frame_time=0.1 last_key
  while :; do
    read t1 i1 < <(cpu_snapshot)
    local dt=$((t1 - t0)) di=$((i1 - i0))
    ((dt<=0)) && dt=1
    local cpu_pct=$(( 100 * (dt - di) / dt ))
    ((cpu_pct<0))&&cpu_pct=0; ((cpu_pct>100))&&cpu_pct=100
    t0=$t1; i0=$i1

    read mt ma < <(mem_snapshot)
    local mem_used=$(( mt - ma ))
    local pct_mem=$(( mt>0 ? (mem_used * 100 / mt) : 0 ))
    ((pct_mem>100)) && pct_mem=100

    local ccolor mcolor used_mb tot_mb
    ccolor="$(color_for_pct "$cpu_pct")"
    mcolor="$(color_for_pct "$pct_mem")"
    used_mb=$(( mem_used / 1024 ))
    tot_mb=$(( mt / 1024 ))

    af_core_color_fg "$ccolor"
    af_core_cursor "$CPU_Y" "$CPU_X"
    rpad "CPU: ${cpu_pct}%" "$CPU_W"
    draw_bar "$CPU_X" $((CPU_Y+1)) "$CPU_W" "$cpu_pct" "$ccolor"

    af_core_color_fg "$mcolor"
    af_core_cursor "$MEM_Y" "$MEM_X"
    rpad "MEM: ${pct_mem}%  (${used_mb}/${tot_mb} MB)" "$MEM_W"
    draw_bar "$MEM_X" $((MEM_Y+1)) "$MEM_W" "$pct_mem" "$mcolor"

    draw_footer

    if IFS= read -rsn1 -t "$frame_time" key; then
      case "$key" in
        q|Q) break ;;
        t|T)
          AF_DEMO_THEME_IDX=$(( (AF_DEMO_THEME_IDX + 1) % ${#AF_DEMO_THEMES[@]} ))
          af_theme_use "${AF_DEMO_THEMES[$AF_DEMO_THEME_IDX]}"
          draw_frame; calc_regions ;;
      esac
    fi
  done
}

main
