// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import org.kde.kirigami 2.15 as Kirigami

// Useful for things such as resizing views

Kirigami.Separator {
    id: root

    signal dragBegin(real globalPosX, real globalPosY)
    signal dragReleased(real totalChangeX, real totalChangeY)
    signal dragPositionChanged(real changeX, real changeY)

    property int oversizeMouseAreaVertical: 0
    property int oversizeMouseAreaHorizontal: 0
    property color unhoveredColor: defaultSeparator.color

    property Item mouseArea: separatorMouseArea

    MouseArea {
        id: separatorMouseArea

        property Item resizerSeparator: parent

        anchors.centerIn: parent
        width: root.width + root.oversizeMouseAreaHorizontal
        height: root.height + root.oversizeMouseAreaVertical

        cursorShape: !Kirigami.Settings.isMobile ? root.width < root.height ? Qt.SplitHCursor : Qt.SplitVCursor : undefined
        preventStealing: true
        hoverEnabled: true
        enabled: parent.enabled

        drag.target: this
        Drag.active: drag.active

        property real initX: 0
        property real initY: 0
        property real lastX: 0
        property real lastY: 0

        onPressed: {
            const globalPos = mapToGlobal(mouseX, mouseY);
            initX = globalPos.x;
            initY = globalPos.y;
            lastX = globalPos.x;
            lastY = globalPos.y;
            root.dragBegin(initX, initY);
        }

        onReleased: {
            const globalPos = mapToGlobal(mouseX, mouseY);
            const totalChangedX = globalPos.x - initX;
            const totalChangedY = globalPos.y - initY;
            root.dragReleased(totalChangedX, totalChangedY);
            Drag.drop();
        }

        onPositionChanged: if(pressed) {
            const globalPos = mapToGlobal(mouseX, mouseY);
            const changedX = globalPos.x - lastX;
            const changedY = globalPos.y - lastY;
            root.dragPositionChanged(changedX, changedY);
        }
    }

    color: (mouseArea.containsMouse || mouseArea.pressed) && enabled ? Kirigami.Theme.highlightColor : unhoveredColor
    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }

    Kirigami.Separator { // So we can pull the normal separator colour, as we always want to match
        id: defaultSeparator
        visible: false
    }

}
