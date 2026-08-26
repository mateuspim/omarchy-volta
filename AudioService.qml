pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
  id: root

  readonly property AudioModel audio: AudioModel { optionsActive: true }

  property IpcHandler controls: IpcHandler {
    target: "pym.volta-control"
    function mute(): void { root.audio.toggleMute() }
    function reset(): void { root.audio.reset() }
    function lock(): void { root.audio.toggleLock() }
    function leftUp(): void { root.audio.setLeft(root.audio.left + 0.05) }
    function leftDown(): void { root.audio.setLeft(root.audio.left - 0.05) }
    function rightUp(): void { root.audio.setRight(root.audio.right + 0.05) }
    function rightDown(): void { root.audio.setRight(root.audio.right - 0.05) }
    function balanceLeft(): void { root.audio.shiftBalance(-0.03) }
    function balanceRight(): void { root.audio.shiftBalance(0.03) }
    function previousSink(): void { root.audio.cycleSink(-1) }
    function nextSink(): void { root.audio.cycleSink(1) }
  }
}
