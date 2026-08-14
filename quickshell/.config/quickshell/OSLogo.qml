import Quickshell
import QtQuick
import "."

// Rectangle {
  Text {
    // anchors.centerIn: parent
    // binds text to property =  "property binding", like a spreadsheet cell with a formula
    // text: Qt.formatDateTime(clock.date, "hh:mm A")
    text: "  "
    color: Theme.foreground
  
    font {
      // family: "SF Mono"
      // family: "CommitMono"
      // family: "SF Pro"
      family: Theme.fontMain
      letterSpacing: -0.35
      pixelSize: 13
      weight: 450
    }
  }
// }