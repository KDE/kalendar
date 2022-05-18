/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.15 as Kirigami

QQC2.AbstractButton {
    id: tagRoot
    property alias actionIcon: toolButton.icon
    property alias actionText: toolButton.text
    property bool showAction: true
    property bool isHeading: false
    property alias itemLayout: layout
    property alias labelItem: label
    property alias headingItem: heading
    property color backgroundColor: Kirigami.Theme.backgroundColor

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    background: Item {
        Rectangle {
            id: mainBg
            anchors.fill: parent
            anchors.leftMargin: pointyBit.anchors.leftMargin + pointyBit.width / 2 - radius / 2
            radius: 3
            color: tagRoot.backgroundColor
            border.color: tagRoot.visualFocus ? Kirigami.Theme.highlightColor
                    : Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor,
                                                        Kirigami.Theme.textColor,
                                                        0.3)
            border.width: 1
        }
        Rectangle {
            id: pointyBit
            antialiasing: true
            rotation: 45
            y: (parent.height - height) / 2
            anchors.left: parent.left
            anchors.leftMargin: y + radius / 2
            // `parent.height * Math.cos(radians)` fits a rotated square inside the parent.
            // `rotation * (Math.PI / 180)` is rotation in radians instead of degrees.
            // `Math.PI / 4` is 45 degrees. 180 / 4 is 45.
            // `height + radius / 2` accounts for the rounded corners reducing visual size.
            height: parent.height * Math.cos(Math.PI / 4) + radius / 2
            width: height
            color: mainBg.color
            border.width: 1
            border.color: mainBg.border.color
            radius: 3
        }
        Rectangle {
            id: borderCover
            antialiasing: true
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: pointyBit.anchors.leftMargin + pointyBit.width / 2
                margins: mainBg.border.width
            }
            width: height
            color: mainBg.color
            radius: mainBg.radius - mainBg.border.width
        }
    }

    contentItem: RowLayout {
        id: layout
        spacing: Math.round(label.Layout.leftMargin - (toolButton.implicitWidth - toolButton.icon.width))
        QQC2.Label {
            id: label
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 1.5
            Layout.leftMargin: borderCover.anchors.leftMargin
            Layout.rightMargin: tagRoot.showAction ? 0 : Kirigami.Units.smallSpacing
            Layout.topMargin: tagRoot.showAction ? 0 : Kirigami.Units.smallSpacing
            Layout.bottomMargin: tagRoot.showAction ? 0 : Kirigami.Units.smallSpacing
            text: tagRoot.text
            elide: Text.ElideRight
            visible: !tagRoot.isHeading
        }
        Kirigami.Heading {
            id: heading
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.minimumWidth: Kirigami.Units.gridUnit * 1.5
            Layout.fillWidth: true
            Layout.leftMargin: borderCover.anchors.leftMargin
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            level: 2
            text: tagRoot.text
            elide: Text.ElideRight
            visible: tagRoot.isHeading
        }
        QQC2.ToolButton {
            id: toolButton
            icon.width: Kirigami.Units.iconSizes.sizeForLabels
            icon.height: Kirigami.Units.iconSizes.sizeForLabels
            text: i18n("Remove Tag")
            display: QQC2.AbstractButton.IconOnly
            onClicked: tagRoot.clicked()
            visible: tagRoot.showAction
        }
    }
}

