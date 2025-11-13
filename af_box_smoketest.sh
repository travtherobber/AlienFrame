#!/usr/bin/env bash

af_core_cursor() { printf '\033[%s;%sH' "$1" "$2"; }
af_core_clear()  { printf '\033[2J'; }

read cols rows <<<"$(./af_term_size.sh)"

w=$(( cols / 2 ))
h=$(( rows / 2 ))
x=$(( (cols - w) / 2 ))
y=$(( (rows - h) / 2 ))

af_core_clear

# ASCII chars
tl="+"; tr="+"; bl="+"; br="+"
hz="-"; vt="|"

# top
af_core_cursor "$y" "$x"
printf "%s" "$tl"
printf "%${w-2}s" "" | tr ' ' "$hz"
printf "%s" "$tr"

# sides
for ((i=1; i<h-1; i++)); do
    af_core_cursor $((y+i)) "$x"; printf "%s" "$vt"
    af_core_cursor $((y+i)) $((x + w - 1)); printf "%s" "$vt"
done

# bottom
af_core_cursor $((y+h-1)) "$x"
printf "%s" "$bl"
printf "%${w-2}s" "" | tr ' ' "$hz"
printf "%s" "$br"

sleep 3

