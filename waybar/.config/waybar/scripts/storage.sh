#!/usr/bin/env bash
# waybar custom module "custom/storage"
# Default: nothing but the storage icon. On left click waybar swaps to
# format-alt, which prints the icon plus free space on / (e.g. "3.43 gb").
# Prints waybar JSON so text/alt/tooltip can live in one place.

set -u

icon=""   # nf-fa-database (U+F1C0) - solid disc stack, stays legible at 9.6px
           # (fa-hdd_o / md-harddisk are outline+detail and wash out at this size)

# bytes available on the filesystem holding /
avail=$(df -B1 --output=avail / 2>/dev/null | tail -n 1 | tr -d ' ')
case "$avail" in
    ''|*[!0-9]*) avail=0 ;;
esac

# 800 mb for small sizes, 3.43 gb once it gets big
human() {
    awk -v b="$1" 'BEGIN {
        split("b kb mb gb tb", u, " ")
        i = 1; v = b
        while (v >= 1024 && i < 5) { v /= 1024; i++ }
        if (i <= 2) printf "%d %s\n", v, u[i]
        else        printf "%.2f %s\n", v, u[i]
    }'
}

free=$(human "$avail")

printf '{"text":"%s","alt":"%s %s","tooltip":"%s free on /"}\n' \
    "$icon" "$icon" "$free" "$free"
