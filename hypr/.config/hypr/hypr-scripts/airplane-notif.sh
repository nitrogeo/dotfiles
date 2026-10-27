#!/bin/bash
# Airplane-mode notification — persistent path (no /tmp/), uses notify-send through swaync daemon.
# Per AGENTS.md: no /tmp/ artifacts; docs trail required.
# — Model: DeepSeek V4.1 Flash Free (opencode, provider: opencode) — 10.27.2026 04:57pm
notify-send -u low -t 3000 -i info "Airplane Mode" "Disabled (kernel-level RFKill handled by hwdb)"
