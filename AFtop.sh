#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  sysmon.sh — example external app built on AlienFrame
#  live CPU + Memory bars, theme toggle, flicker-free updates
# ─────────────────────────────────────────────────────────────────────────────

# 1) bring AlienFrame online
source ./af_bootstrap.sh
af_bootstrap_init default
af_require theme

# 2) choose a default theme (cycle with 't')
AF_DEMO_THEMES=(ghostlight corrosion sunflower)
AF_DEMO_THEME_IDX=0
af_theme_use "${AF_DEMO_THEMES[$AF_DEMO_THEME_IDX]}"

# 3) housekeeping
cleanup() {
  af_core_color_reset
  af_core_show_cursor
  af_core_clear
}
trap cleanup EXIT

# 4) draw static chrome (boxes)
draw_frame() {
  af_core_clear
  af_core_hide_cursor
  af_draw_box "left-half"  "CPU"    "$AF_THEME"
  af_draw_box "right-half" "Memory" "$AF_THEME"

  # status footer
  read cols rows _ _ _ _ FG BG BORDER ACCENT TEXT <<<"$(af_layout_color full "$AF_THEME")"
  af_core_color_fg "$BORDER"
  af_core_cursor "$rows" 1
  af_core_repeat "$cols" " "
  af_core_color_reset
}

# 5) read /proc — pure bash
cpu_snapshot() {
  # outputs: total idle
  local a; read -r -a a </proc/stat
  # a[0]="cpu" a[1]=user a[2]=nice a[3]=system a[4]=idle a[5]=iowait a[6]=irq a[7]=softirq a[8]=steal ...
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

# 6) HUD helpers
color_for_pct() {
  # green → yellow → red thresholds
  local pct="$1"
  if   (( pct < 50 )); then echo 118
  elif (( pct < 80 )); then echo 220
  else                    echo 196
  fi
}

rpad() { local s="$1" w="$2"; local pad=$(( w - ${#s} )); ((pad<0))&&pad=0; af_io_write "$s"; ((pad))&&af_core_repeat "$pad" " "; }

draw_bar() {
  # draw_bar x y width pct color
  local x="$1" y="$2" w="$3" pct="$4" color="$5"
  (( w < 3 )) && return
  local fill=$(( (w * pct) / 100 ))
  ((fill > w)) && fill="$w"
  local empty=$(( w - fill ))

  af_core_cursor "$y" "$x"
  af_core_color_fg "$color"; af_core_repeat "$fill"  "█"
  af_core_color_fg 240;      af_core_repeat "$empty" "░"
  af_core_color_reset
}

# 7) dynamic layout coordinates
calc_regions() {
  # CPU region
  read _ _ wL hL xL yL _ _ _ ACCENTL TEXTL <<<"$(af_layout_color left-half "$AF_THEME")"
  CPU_X=$((xL+2));  CPU_Y=$((yL+2))
  CPU_W=$((wL-4));  CPU_H=$((hL-4))

  # MEM region
  read _ _ wR hR xR yR _ _ _ ACCENTR TEXTR <<<"$(af_layout_color right-half "$AF_THEME")"
  MEM_X=$((xR+2));  MEM_Y=$((yR+2))
  MEM_W=$((wR-4));  MEM_H=$((hR-4))

  # footer
  read COLS ROWS _ _ _ _ FG BG BORDER ACCENT TEXT <<<"$(af_layout_color full "$AF_THEME")"
  FT_Y="$ROWS"
}

# 8) status footer line
draw_footer() {
  local theme="$AF_THEME"
  local now; now="$(date +%H:%M:%S)"
  local up;  read -r _ up _ </proc/uptime  # seconds.dec
  up="${up%.*}"
  local uh=$(( up/3600 )); local um=$(( (up%3600)/60 ))
  local ustr
  printf -v ustr "%02dh:%02dm" "$uh" "$um"

  af_core_cursor "$FT_Y" 2
  af_core_color_fg 240
  local msg="Theme: $theme  •  Uptime: $ustr  •  Time: $now  •  [t] theme  [q] quit"
  rpad "$msg" "$((COLS-2))"
  af_core_color_reset
}

# 9) main loop: no flicker (partial redraw only)
main() {
  draw_frame
  calc_regions

  # initial CPU snapshot
  local t0 i0 t1 i1 dt di cpu_pct
  read t0 i0 < <(cpu_snapshot)

  # input handling: raw mode-ish
  stty_state="$(stty -g)"
  stty -icanon -echo min 0 time 1

  while :; do
    # CPU %
    read t1 i1 < <(cpu_snapshot)
    dt=$((t1 - t0)); di=$((i1 - i0))
    (( dt <= 0 )) && dt=1
    cpu_pct=$(( 100 * (dt - di) / dt ))
    (( cpu_pct < 0 )) && cpu_pct=0
    (( cpu_pct > 100 )) && cpu_pct=100
    t0=$t1; i0=$i1

    # MEM %
    local mt ma mem_used_k pct_mem
    read mt ma < <(mem_snapshot)
    mem_used_k=$(( mt - ma ))
    (( mt > 0 )) && pct_mem=$(( (mem_used_k * 100) / mt )) || pct_mem=0
    (( pct_mem > 100 )) && pct_mem=100

    # DRAW CPU block
    local ccolor; ccolor="$(color_for_pct "$cpu_pct")"
    af_core_color_fg "$ccolor"
    af_core_cursor "$CPU_Y" "$CPU_X"; rpad "CPU: ${cpu_pct}%" "$CPU_W"
    draw_bar "$CPU_X" $((CPU_Y+1)) "$CPU_W" "$cpu_pct" "$ccolor"

    # DRAW MEM block
    local mcolor; mcolor="$(color_for_pct "$pct_mem")"
    af_core_color_fg "$mcolor"
    local used_mb=$(( mem_used_k / 1024 ))
    local tot_mb=$(( mt / 1024 ))
    af_core_cursor "$MEM_Y" "$MEM_X"; rpad "MEM: ${pct_mem}%  (${used_mb}/${tot_mb} MB)" "$MEM_W"
    draw_bar "$MEM_X" $((MEM_Y+1)) "$MEM_W" "$pct_mem" "$mcolor"

    # footer
    draw_footer

    # input (non-blocking)
    local k
    IFS= read -rsn1 k
    case "$k" in
      q|Q) break ;;
      t|T)
        AF_DEMO_THEME_IDX=$(( (AF_DEMO_THEME_IDX + 1) % ${#AF_DEMO_THEMES[@]} ))
        af_theme_use "${AF_DEMO_THEMES[$AF_DEMO_THEME_IDX]}"
        draw_frame
        calc_regions
        ;;
      $'\e')
        # consume possible escape sequence without acting
        read -rsn2 -t 0.001 _ 2>/dev/null
        ;;
      *) : ;;
    esac

    # pacing
    sleep 0.1
  done

  stty "$stty_state"
}

main
