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
      // 8.11.2026 - behind windows lol
      aboveWindows: false
      
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
      
      color: Theme.background // - void purple
      
      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14

        // left
        OSLogo {}
        Workspaces {}
        // copied.Workspaces1 {}
  
        Item {
          Layout.fillWidth: true
        }

        //center
        // copied.MediaPlayer {}

        Item {
          Layout.fillWidth: true
        }
        
        // right
        // copied.Memory {} - from tonybtw lol
        Volume {}
        Clock {}
      }
    }
  }
}
