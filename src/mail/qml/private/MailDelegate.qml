// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.19 as Kirigami

Kirigami.AbstractListItem {
    id: root

    property bool showSeparator: false

    property string datetime
    property string author
    property string title

    property bool isRead

    leftPadding: Kirigami.Units.gridUnit
    rightPadding: Kirigami.Units.gridUnit
    topPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing

    hoverEnabled: true

    signal openMailRequested()
    signal starMailRequested()
    signal contextMenuRequested()

    property bool showSelected: (mouseArea.pressed === true || (root.highlighted === true && applicationWindow().isWidescreen))

    background: Rectangle {
        color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, root.showSelected ? 0.5 : hoverHandler.hovered ? 0.2 : 0)

        // indicator rectangle
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1

            width: 4
            visible: !root.isRead
            color: Kirigami.Theme.highlightColor
        }

        HoverHandler {
            id: hoverHandler
            // disable hover input on mobile because touchscreens trigger hover feedback and do not "unhover" in Qt
            enabled: !Kirigami.Settings.isMobile
        }

        Kirigami.Separator {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.leftPadding
            anchors.rightMargin: root.rightPadding
            visible: root.showSeparator && !root.showSelected
            opacity: 0.5
        }
    }

    onClicked: root.openMailRequested()

    Item {
        id: item
        implicitHeight: rowLayout.implicitHeight

        RowLayout {
            id: rowLayout
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            Kirigami.Avatar {
                // Euristic to extract name from "Name <email>" pattern
                name: author.replace(/<.*>/, '').replace(/\(.*\)/, '')
                // Extract and use email address as unique identifier for image provider
                source: 'image://contact/' + new RegExp("<(.*)>").exec(author)[1] ?? ''
                Layout.rightMargin: Kirigami.Units.largeSpacing
                sourceSize.width: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 2
                sourceSize.height: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 2
                Layout.preferredWidth: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 2
                Layout.preferredHeight: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 2
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: root.author
                        elide: Text.ElideRight
                        font.weight: root.isRead ? Font.Normal : Font.Bold
                    }

                    QQC2.Label {
                        color: Kirigami.Theme.disabledTextColor
                        text: root.datetime
                    }
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.title
                    elide: Text.ElideRight
                    font.weight: root.isRead ? Font.Normal : Font.Bold
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: {
                if (mouse.button === Qt.RightButton) {
                    root.contextMenuRequested();
                } else if (mouse.button === Qt.LeftButton) {
                    root.clicked();
                }
            }
            onPressAndHold: root.contextMenuRequested();
        }
    }
}

