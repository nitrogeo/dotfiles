# .dotfiles

my dotfiles for my current linux setup(s).
<br><br>
i use arch btw
<br><br>

## screenshots
![setup as of 3.7.2026](/.assets/setup%203.7.2026~.png)
![setup as of 3.11.2026](/.assets/setup%203.11.2026~.png)

<br>

## (some) dependencies:
to use these yourself, you can likely use GNU Stow to stow the folders to your system to take effect.

### **core hyprland**

- **Hyprland** of course.
- **hyprlock**: screen locking.
- **hypridle**: required for automated locking/sleep triggers; not set up yet.
- **xdg-desktop-portal-hyprland**: essential for any display-related stuff
- **hyprland-plugins**: hyprland plugins manager

### hardware utils

- **brightnessctl**: controls screen brightness.
- **playerctl**: controls media playback (Play/Pause, Next, Previous).
- **wpctl** (from `wireplumber`): Used for audio volume and muting.
- **swww**: much easier to manage the wallpaper over hyprpaper.
- **nwg-displays**: used to generate `monitors.conf`; not required, however, as editing the main `hyprland.conf` can be easier.

### **core applications + ui**

- **kitty**: terminal emulator.
- **rofi-wayland**: application launcher and the hyprland exit menu (the `poweroff` and `reboot` commands are used for full restarts / reboots / shutdowns currently).
- **Waybar**: status bar
- **nwg-dock-hyprland**: provides dock functionality, not set up yet
- **Dolphin**: file manager
- **SwayNC**: notification center/daemon

### **scripts + tool backend**

- **jq**: processing JSON data in scripts
- **grim** & **slurp**: screenshots
- **wl-clipboard**: required for `wl-copy` and `wl-paste` to manage your clipboard via rofi.
- **cliphist**: clipboard history management.
- **tesseract-ocr**: required for OCR

### **plugins**

- **hyprexpo**: provides the workspace overview/grid.
- **dynamic-cursors**: adds effects like "shake to find" and tilting to the cursor.


## disclaimers
idc what reddit / eric murphy say(s)
<br>
endeavoros _is_ arch; i dont have time rn for a multi-hour archinstall / manual install ft. gemini (and the wiki ig haha) 😭🙏🥀
