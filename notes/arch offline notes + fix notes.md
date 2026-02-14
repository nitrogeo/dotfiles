# commands
restart network:
`sudo systemctl restart NetworkManager`

save kde plasma config:
https://www.youtube.com/watch?v=jEVcrPMfXGU

use konsave -h
![[snapshot.jpg]]



---


# 2.8.2026
https://gemini.google.com/app/054504fe359b93ac
`pactl load-module module-loopback`
`pactl unload-module module-loopback`

#ai 

Routing audio from an input (like a microphone) directly to an output (like speakers or headphones) in PipeWire is a common task, often used for monitoring or testing. Since PipeWire is modular, you have a few ways to do this depending on whether you want a quick command or a visual interface.

### Method 1: The Quick Command (Loopback)

The fastest way to do this without installing extra software is using the `pactl` command (PipeWire's PulseAudio-compatible utility).

Run this in your terminal:

Bash

```
pactl load-module module-loopback
```

- **How to stop it:** Run `pactl unload-module module-loopback`.
    
- **Note:** This creates a generic link between your default input and default output.
    

---

### Method 2: The Visual Way (Recommended)

If you want to see exactly what is going where, use a graph manager. This is the "Arch way" to handle complex routing.

1. **Install a graph tool:** `helvum` is the most popular GTK-based patchbay for PipeWire.
    
    Bash
    
    ```
    sudo pacman -S helvum
    ```
    
2. **Open Helvum:** You will see nodes for your hardware and applications.
    
3. **Connect them:** Click and drag a line from the **output terminal** of your microphone/input device to the **input terminal** of your speakers/headphones.
    

---

### Method 3: Persistent Configuration

If you want this routing to exist every time you boot up, you can use **pw-loopback**.

Run this command to create a named loopback:

Bash

```
pw-loopback --capture-props='node.name=my_mic' --playback-props='node.name=my_speakers'
```

For a permanent solution, you can create a configuration file in `~/.config/pipewire/pipewire.conf.d/` or use a session manager like **WirePlumber** to script the connection, but Method 2 is usually sufficient for most "endeavors."

---

### Quick Tips for Arch Users

- **Latency:** If you hear a delay, PipeWire might be using a large buffer. You can adjust this globally in your config or by setting `PIPEWIRE_LATENCY="128/48000"` before running an app.
    
- **Feedback Warning:** Be careful! If you route a microphone to speakers that the microphone can "hear," you will get a loud, piercing screech of feedback. **Wear headphones** while testing this.
    

Would you like me to help you write a systemd service to make one of these loopbacks start automatically when you log in?


---

2.9.2026 - 1:52a
fixed obs "yesteerday"by
```
systemctl --user stop xdg-desktop-portal-hyprland
systemctl --user stop xdg-desktop-portal
systemctl --user start xdg-desktop-portal-hyprland
```

i think this is what worked

---
2.13.2026 - 4:34p
fix brightness keys not working

Brightness keys are a classic Linux "right of passage." In Hyprland, these don't work out of the box because the compositor doesn't know which program you want to use to talk to the hardware.

The easiest and most reliable tool for this is `brightnessctl`.

### 1. Install the tool

Open your terminal and run:

Bash

```
sudo pacman -S brightnessctl
```

### 2. Add the binds to your Config

Add these lines to your `hyprland.conf`. Note the `e` flag—this stands for "repeat," which allows you to hold the button down to smoothly change brightness.

Bash

```
# Brightness control
binde = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
binde = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
```

---

### Why this might not work (and how to fix it):

If you press the keys and nothing happens, your user might not have permission to change backlight levels.

**The Fix:**

Add yourself to the `video` group by running this in your terminal:

Bash

```
sudo usermod -aG video $USER
```

_(Note: You will need to **log out and log back in** for this group change to take effect.)_


---

bzmenu post install fix:

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

