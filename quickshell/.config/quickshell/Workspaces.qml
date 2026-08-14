import Quickshell
import Quickshell.Hyprland // for hyprland dispatcher
import QtQuick
import QtQuick.Layouts
import "."

RowLayout {
  spacing: 3

  Repeater {
    // model: 22
    // model: Hyprland.workspaces.values
    model: 9
    
    // repeater = factory that stamps out # copies of whatever's inside it
    // index starts at 0 but humans cout from 1, as you know from java + programmer memes lol
      
    Rectangle {
      id: wsButton
      required property int index // index of the workspace

      property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1) // find the workspace object with the matching ID
      property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1) // is the workspace in the index the currently focused workspace?
      // creating 2 cusotm properties on each button and bidning them (delcarative, "spreadsheet" style) to "facts" (properties) abt hyprland
      // each one - is there a real (active?) workspace that matches my number?
      // hyprland.workspaces.values = live list of existing worksapces; i.e. windows on it or being looked at
        // if ws finds a workspace that matches the current workspace id, it holds it 
        // ws = answers "does my worksapce have anything on it?"
      // isActive = "am i the workspace ur currently looking at?"
      // also the reactive binds change based on the current worksapce
      // the "?" after focusedworkspaceid only checks if one exsits to prevent erros/crashing (supposedly; according to saneaspect btw)

      implicitWidth:  label.implicitWidth + 14
      implicitHeight:  22
      radius: 6

      color: isActive ? Theme.accentDark : (ws ? Theme.background : "transparent") // if the workspace is active, use accent color; otherwise, use background color - copilot
      // wait this is for the rectangle around the workspace button, not the text. - me + copilot
      // So if the workspace is active, use accent color; if the workspace exists but is not active, use background color; if the workspace does not exist, make it transparent - copilot
      //
      // qt/parser or whatever reads it like: am i active? if yes, use accentDark, if no, do i at least have windows? if so, do i have windows? then use "background", if no windows, then "transparent"
        // thats the logic, but if it's not focused i made it to where it doesnt have a background either way lol
      // the line is a question inside a question with 3 possible outcomes

      Behavior on color {
        ColorAnimation {
          duration: 150
          // easing.type: Easing.InOutQuad
        }
      }
      // quickshell animations are also fun bc of the declarative syntax says saneaspect lol
      // describe what and not the how

      Text {
        id: label
        anchors.centerIn: parent
        text: wsButton.index + 1
        color: wsButton.isActive ? Theme.accent : (wsButton.ws ? Theme.foreground : Theme.greyTest)

        font {
          family: Theme.fontMain
          // pixelSize: Theme.sizeMain
          weight: Theme.weightMain
          letterSpacing: -0.1
          pixelSize: 10
        }
      }
      
      MouseArea {
      // adds an invisible, clickable layer
        anchors.fill: parent
        // not sure?? lol

        // lua
        // onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (parent.index + 1) + " })")

        // conf
        // onClicked: Hyprland.dispatch("workspace " + (parent.index + 1))
        // freakahh line is impossible to figure out rn... if / when figure out later, def make new ver:
        // working below later hopefully
        // geminie lol:
        // onClicked: Hyprland.dispatch(`workspace ${parent.index}`)
        // working from TONYBTW!? WOOO - 8.6.2026
        onClicked: Hyprland.dispatch("workspace " + (index + 1))
        cursorShape: Qt.PointingHandCursor
      }
    }
  }
}
