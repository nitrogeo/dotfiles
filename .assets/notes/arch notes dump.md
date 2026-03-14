# commands
restart network:
`sudo systemctl restart NetworkManager`

save kde plasma config:
https://www.youtube.com/watch?v=jEVcrPMfXGU

use konsave -h
![[snapshot.jpg]]




---




start waybar and background it
`nohup waybar &`



https://github.com/fidian/ansi

commands:
`ansi --color-table`
`ansi --color-codes`

![[2026-02-14_22-05-39.png]]

---

## 2.15.2026 
6:27pm
obs - first monitor 1 then 0

waybar 12hr format clock:
```
"clock": {
    "format": "{:%a %d %b %I:%M %p}",
    "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
},
```

og
`"format": "{:%a %d %b %H:%M}",`

better; with date
`"format": "{:%a %d %b %I:%M %p}"` 

---


# 2.16.2026
change prmary audio device hyprland??
use pavucontrol

change bluetooth settings??
use bzmenu and map to a shortcut (like super + b)