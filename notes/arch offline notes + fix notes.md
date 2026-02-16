# commands
restart network:
`sudo systemctl restart NetworkManager`

save kde plasma config:
https://www.youtube.com/watch?v=jEVcrPMfXGU

use konsave -h
![[snapshot.jpg]]



---


# misc notes
## 2.8.2026
https://gemini.google.com/app/054504fe359b93ac
`pactl load-module module-loopback`
`pactl unload-module module-loopback`

ai version: [[audio speaker to mic hack ai reponse idk]]

---

## bzmenu post install fix:

Since you installed `bzmenu` from GitHub, you just need to make sure the compiled binary is in your "Path" (where the computer looks for commands) and then add a shortcut for it.

### 1. Finalize the Installation

If you just ran the `cargo build` command from the GitHub instructions, the actual program is currently "hiding" inside a folder called `target/release`. To make it usable as a command, move it to your local bin folder:

Bash

```
# Move to the folder where you cloned it
cd ~/bzmenu 

# Move the actual program to your bin folder
sudo cp target/release/bzmenu /usr/local/bin/
```

### 2. How to use it with Rofi

Since your `hyprland.conf` uses **Rofi** as the main menu, you must tell `bzmenu` to use it for the display.

**Test it in the terminal first:**

Bash

```
bzmenu -l rofi
```

- **-l rofi**: This tells the program to open the Bluetooth list inside Rofi.
    
- If you see "boxes" instead of icons, it's because you need a **Nerd Font** installed. If it looks messy, you can try the XDG icon mode: `bzmenu -l rofi -i xdg`.
    

### 3. Add the Keybind

Add this to your `hyprland.conf` so you can open it with `Super + B`:

Bash

```
# Bluetooth Menu (bzmenu)
bind = $mainMod, B, exec, bzmenu -l rofi
```

---

## 2.14.2026
start waybar and background it

```
nohup waybar &
```

https://github.com/fidian/ansi

commands:
`ansi --color-table`
`ansi --color-codes`

![[2026-02-14_22-05-39.png]]


colors from neofetch:
#cba6f7 - pinkish purple, similar to catppucin magenta but not quite
#8787d4 - bluer purple ie indigo, more like dark blurple (discord blurple) lol


just for ref (from catppuccin kitty theme)
**`#8AADF4`** - blue
**`#F5BDE6`** - magenta

**`#A5ADCB`** - bold white
**`#A5ADCB`** - dim white (light grey)

**`#494D64`** - bold black
**`#5B6078`** - dim black (dark grey)


more idk resources ig
https://www.youtube.com/watch?v=9U8LCjuQzdc&t=1s
"We may have killed p10k, so I found the perfect replacement."

https://github.com/fidian/ansi

## 2.15.2026 
6:27pm
obs - first monitor 1 then 0

waybar 12hr format clock:
```
"clock": {
    "format": "{:%I:%M %p}", 
    "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
},
```

og
`"format": "{:%a %d %b %H:%M}",`

better; with date
`"format": "{:%a %d %b %I:%M %p}"` 

## 2.16.2026
change prmary audio device hyprland??
use pavucontrol

change bluetooth settings??
use bzmenu and map to a shortcut (like super + b)

i think ts fixed the left airpod delay lol
![[2026-02-16_13-55-35.png]]


