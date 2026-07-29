// comments from saneaspect explanation btw - 7.28.2026
import Quickshell // gives "shell root thing" and main panel window
import Quickshell.Hyprland // gives Hyprland workspace info - copilot /// give Hyprland integration - saneaspect
import QtQuick // gives text "and other basic QML types" says copilot lol)
import QtQuick.Layouts
import "."


ShellRoot { // root object; not the visual itself, just contains everything
  
  Variants {
    model: Quickshell.screens
    // model = number of stuff in the list, in this case, screens - copilot + saneaspect
    // "i want 'quickshell.screens' [number of] variants, bro" - the model for the variants, so that each screen gets its own panel window" - saneaspect + copilot
    // quickshell.screens = list of screens, so the model is the number of screens - saneaspect + copilot
    // variaants injects the model data into each component's list property, so we can easily pass each screen to its component - saneaspect
    
    PanelWindow { // "decorationless window attached to the screen edges by anchors"
      required property var modelData
      // reuired property = how u define varialbes; var = typeless variable - saneaspect
      // We declare required property of our model data to receive it. Then set screen model data to tell each panel window which monitor it belongs to. So one bar per screen. - saneaspect
      
      screen: modelData // modelData = the current screen in the model, so that each panel window is attached to its respective screen - copilot
      
      anchors {
        top: true
        left: true
        right: true
      }
        
      implicitHeight: 25
      // color: "#1E1E1E" // - waybar current
      // color: "#24273a" // waybar catppuccin bkg
      
      // color: "#1b1d25" // catppuccin dark-ish bkg
      // color: "#26283b" // - darker
      // color: "#1e1f30" // - darkest
      // color: "#181a2b" // - darkest
  
      // color: "#130e29" // - void purple
      // color: bkgColor // - void purple
      color: Theme.background // - void purple
      
      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
  
        RowLayout {
          spacing: 7
          Repeater {
            model: 22
            // model: 9
            // model: Hyprland.workspaces.values
            
            Text {
              property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1) // is the workspace in the index the currently focused workspace? / another binding btw; only chekcs ID if the workspace is focused - copilot + saneaspect
              text: index + 1 // indexes start at 0, so we add 1 to display workspace numbers starting from 1 - copilot + saneaspect
              // declaring a relationship; text is always gonna be equal to some value - saneaspect
              color: isActive ? Theme.accent : Theme.foreground 
              // if the workspace is active, use accent color; otherwise, use foreground color - copilot + saneaspect
              
              font {
                // family: "SF Mono"
                // family: "CommitMono"
                // family: "SF Pro"
  
                // family: "SF Pro Display"
                // family: "Free Sans"
                // family: "Inter"

                family: Theme.fontMain
                weight: isActive ? 500 : 500 // active : inactive == (font weight)
                
                letterSpacing: -0.1
                pixelSize: 10
                // weight: 400
              }
            }
          }
        }
  
        Item {
          Layout.fillWidth: true
        }

        Clock { }
      }
    }
  }
}
