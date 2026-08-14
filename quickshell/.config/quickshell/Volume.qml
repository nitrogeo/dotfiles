import Quickshell
import Quickshell.Hyprland // for hyprland dispatcher
import QtQuick
import QtQuick.Layouts
import "."

RowLayout {
	id: root
	spacing: 7

	property var sink: Pipewire.defaultAudioSink

	readonly property bool ready: sink && sink.ready
	// so we dont have to type sink and sink ready in the file ig lol
	readonly property bool muted: ready && sink.audio.muted
	readonly property int vol: ready ? Math.round(sink.audio.volume * 100) : 0
	// {":" = "or"} btw lol (ig like how im pretty sure {"||" = "or"} in java lol)

	readonly property string icon: {
		if (!ready) return String.fromCodePoint(0xF0581)
		if (muted) return ""
		
		if (vol === 0) return String.fromCodePoint(0xF0581)
		if (vol < 34) return String.fromCodePoint(0xF057F)
		if (vol > 67) return String.fromCodePoint(0xF0580)
	
		return String.fromCodePoint(0xF057E)
	}

	Text {
		text: root.icon
		color: Theme.blue

		font {
		  family: Theme.fontMain
			pixelSize: 13
		}
	}

	Text {
	// actual volume percentage text
	  text: {
			if (!root.ready) return "-"
			if (root.muted) return "Muted"
			return root.vol + "%"
		}

		color {
		
		}
	}
}
