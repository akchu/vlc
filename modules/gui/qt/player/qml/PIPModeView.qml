/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick
import QtQuick.Window

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Player
import VLC.Playlist
import VLC.Style
import VLC.Util

FocusScope {
    id: root

    anchors.fill: parent

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        palette: VLCStyle.darkPalette
        colorSet: ColorContext.Window
    }

    // Full-bleed video surface
    VideoSurface {
        id: videoSurface

        anchors.fill: parent
        focus: visible

        videoSurfaceProvider: MainCtx.videoSurfaceProvider
        visible: MainCtx.hasEmbededVideo

        onMouseMoved: {
            mouseAutoHide.restart()
            controlsOverlay.visible = true
            videoSurface.cursorShape = Qt.ArrowCursor
        }

        Timer {
            id: mouseAutoHide
            interval: 2500
            running: true
            repeat: false
            onTriggered: {
                controlsOverlay.visible = false
                videoSurface.cursorShape = Qt.BlankCursor
            }
        }
    }

    // Drag-to-move across desktop & double-click to restore
    MouseArea {
        id: dragArea

        anchors.fill: parent
        hoverEnabled: true

        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                root.Window.window.startSystemMove()
            }
        }

        onDoubleClicked: {
            MainCtx.pipView = false
        }

        onPositionChanged: {
            mouseAutoHide.restart()
            controlsOverlay.visible = true
            videoSurface.cursorShape = Qt.ArrowCursor
        }
    }

    // Floating controls overlay (shows on hover)
    Item {
        id: controlsOverlay

        anchors.fill: parent
        visible: false
        z: 2

        // Top gradient for button contrast
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: VLCStyle.dp(48, VLCStyle.scale)

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#A0000000" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Restore button (top-left)
        Widgets.IconButton {
            id: restoreButton

            anchors {
                top: parent.top
                left: parent.left
                margins: VLCStyle.margin_small
            }

            font.pixelSize: VLCStyle.icon_normal
            description: qsTr("Restore full window")
            text: VLCIcons.window_restore

            onClicked: MainCtx.pipView = false
        }

        // Close button (top-right)
        Widgets.IconButton {
            id: closeButton

            anchors {
                top: parent.top
                right: parent.right
                margins: VLCStyle.margin_small
            }

            font.pixelSize: VLCStyle.icon_normal
            description: qsTr("Close")
            text: VLCIcons.close

            onClicked: {
                MainPlaylistController.stop()
                MainCtx.pipView = false
            }
        }

        // Play/Pause button (center)
        Widgets.IconButton {
            id: playButton

            anchors.centerIn: parent
            font.pixelSize: VLCStyle.icon_large
            description: qsTr("Play/Pause")

            text: (Player.playingState === Player.PLAYING_STATE_PLAYING)
                  ? VLCIcons.pause_filled
                  : VLCIcons.play_filled

            onClicked: MainPlaylistController.togglePlayPause()
        }

        // Bottom progress bar
        Rectangle {
            id: progressBackground

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }

            height: VLCStyle.dp(4, VLCStyle.scale)
            color: "#40FFFFFF"

            Rectangle {
                id: progressFill

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }

                width: parent.width * (Player.position || 0)
                color: VLCStyle.colors.accent
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -VLCStyle.dp(8, VLCStyle.scale)

                onClicked: (mouse) => {
                    var newPos = mouse.x / width
                    Player.position = Math.max(0.0, Math.min(1.0, newPos))
                }
            }
        }
    }

    Keys.onPressed: (event) => {
        if (event.accepted)
            return
        MainCtx.sendHotkey(event.key, event.modifiers)
    }
}
