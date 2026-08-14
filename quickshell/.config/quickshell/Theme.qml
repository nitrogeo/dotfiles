pragma Singleton

import QtQuick

QtObject {
    readonly property color background: "#130e29" // void purple
    readonly property color foreground: "#f0f0f0" // off white
    
    readonly property color accent: "#28A9FF" // neon blue
    readonly property color accentDark: "#11496e" // idk?/
    readonly property color accentLight: "#5AC8FF" // light neon blue

    readonly property color greyTest: "#594964"
    
    
    readonly property color pink: "#f65298" // pink
    readonly property color lightPink: "#F781C4" // light pink
    readonly property color lighterPink: "#F9A7D0" // lighter pink

    readonly property color purple: "#5b4dc5" // purple
    readonly property color lightPurple: "#715AD6" // light purple
    readonly property color lighterPurple: "#a273e8" // lighter purple - a24 lol
    
    readonly property color blue: "#8aadf4" // waybar blue lol

    
    readonly property color red: "#f38ba8"
    readonly property color green: "#a6e3a1"

    readonly property string fontMain: "Inter"
    readonly property int sizeMain: 14
    readonly property int weightMain: 500
}

// notes lol
// 
// color notes - moves from main shell.qml lo
// color: "#1E1E1E" // - waybar current
// color: "#24273a" // waybar catppuccin bkg

// color: "#1b1d25" // catppuccin dark-ish bkg
// color: "#26283b" // - darker
// color: "#1e1f30" // - darkest
// color: "#181a2b" // - darkest

// color: "#130e29" // - void purple
// color: bkgColor // - void purple
