/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.15 as Kirigami

Item {
    id: tagRoot
    property alias actionText: toolButton.text
    property alias headingItem: heading
    property alias icon: toolButton.icon
    property bool isHeading: false
    property alias itemLayout: layout
    property alias labelItem: label
    property bool showAction: true
    property string text

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false
    implicitHeight: layout.implicitHeight
    implicitWidth: layout.implicitWidth

    signal clicked

    Rectangle {
        id: mainBg
        anchors.fill: parent
        anchors.leftMargin: pointyBit.anchors.leftMargin + pointyBit.width / 2 - radius / 2
        border.color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.3)
        border.width: 1
        color: Kirigami.Theme.backgroundColor
        radius: 3
    }
    Rectangle {
        id: pointyBit
        anchors.left: parent.left
        anchors.leftMargin: y + radius / 2
        antialiasing: true
        border.color: mainBg.border.color
        border.width: 1
        color: mainBg.color
        // `parent.height * Math.cos(radians)` fits a rotated square inside the parent.
        // `rotation * (Math.PI / 180)` is rotation in radians instead of degrees.
        // `Math.PI / 4` is 45 degrees. 180 / 4 is 45.
        // `height + radius / 2` accounts for the rounded corners reducing visual size.
        height: parent.height * Math.cos(Math.PI / 4) + radius / 2
        radius: 3
        rotation: 45
        width: height
        y: (parent.height - height) / 2
    }
    Rectangle {
        id: borderCover
        antialiasing: true
        color: mainBg.color
        radius: mainBg.radius - mainBg.border.width
        width: height

        anchors {
            bottom: parent.bottom
            left: parent.left
            leftMargin: pointyBit.anchors.leftMargin + pointyBit.width / 2
            margins: mainBg.border.width
            top: parent.top
        }
    }
    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: Math.round(label.Layout.leftMargin - (toolButton.implicitWidth - toolButton.icon.width))

        QQC2.Label {
            id: label
            Layout.bottomMargin: tagRoot.showAction ? 0 : Kirigami.Units.smallSpacing
            Layout.fillWidth: true
            Layout.leftMargin: borderCover.anchors.leftMargin
            Layout.rightMargin: tagRoot.showAction ? 0 : Kirigami.Units.smallSpacing
            Layout.topMargin: tagRoot.showAction ? 0 : Kirigami.Units.smallSpacing
            elide: Text.ElideRight
            horizontalAlignment: Qt.AlignLeft
            text: tagRoot.text
            verticalAlignment: Qt.AlignVCenter
            visible: !tagRoot.isHeading
        }
        Kirigami.Heading {
            id: heading
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            Layout.fillWidth: true
            Layout.leftMargin: borderCover.anchors.leftMargin
            Layout.topMargin: Kirigami.Units.smallSpacing
            elide: Text.ElideRight
            horizontalAlignment: Qt.AlignLeft
            level: 2
            text: tagRoot.text
            verticalAlignment: Qt.AlignVCenter
            visible: tagRoot.isHeading
        }
        QQC2.ToolButton {
            id: toolButton
            display: QQC2.AbstractButton.IconOnly
            icon.height: Kirigami.Units.iconSizes.sizeForLabels
            icon.width: Kirigami.Units.iconSizes.sizeForLabels
            text: i18n("Remove Tag")
            visible: tagRoot.showAction

            onClicked: tagRoot.clicked()
        }
    }
}
