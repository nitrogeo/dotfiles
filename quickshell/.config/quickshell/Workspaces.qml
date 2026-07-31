import Quickshell
import Quickshell.Hyprland // for hyprland dispatcher
import QtQuick
import QtQuick.Layouts
import "."

RowLayout {
  spacing: 7

  Repeater {
    model: 22
      
    Rectangle {
      id: wsButton
      required property int index // index of the workspace

      property var ws: Hyprland.workspaces.values
    }
  }
}
