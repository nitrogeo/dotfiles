// comments from saneaspect explanation btw - 7.28.2026
import Quickshell // gives "shell root thing" and main panel window
import QtQuick // gives text "and other basic QML types" says copilot lol)

ShellRoot { // root object; not the visual itself, just contains everything
    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 30

        Text {
            anchors.centerIn: parent
            text: "Hello World"
        }
    }
}
