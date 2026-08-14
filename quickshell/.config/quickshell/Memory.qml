import Quickshell
import Quickshell.Hyprland // for hyprland dispatcher
import QtQuick
import QtQuick.Layouts
import "."



RowLayout {
	id: root
	spacing: 7



	
  // Add to your system data properties
  property int memUsage: 0
  
  // Memory process
  Process {
      id: memProc
      command: ["sh", "-c", "free | grep Mem"]
      stdout: SplitParser {
          onRead: data => {
              if (!data) return
              var parts = data.trim().split(/\s+/)
              var total = parseInt(parts[1]) || 1
              var used = parseInt(parts[2]) || 0
              memUsage = Math.round(100 * used / total)
          }
      }
      Component.onCompleted: running = true
  }
  
  // Update your timer to run both processes
  Timer {
      interval: 2000
      running: true
      repeat: true
      onTriggered: {
          cpuProc.running = true
          memProc.running = true
      }
  }


  
}