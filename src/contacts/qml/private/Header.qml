/*
 * SPDX-FileCopyrightText: 2019 Fabian Riethmayer <fabian@web2.0-apps.de>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import QtGraphicalEffects 1.0

Control {
    id: root
    clip: true
    default property alias contentItems: content.children
    //property alias stripContent: strip.data

    property var source
    property var backgroundSource

    background: Item {
        // Background image
        Image {
            id: bg
            width: root.width
            height: root.height
            source: root.backgroundSource
        }

        FastBlur {
            id: blur
            source: bg
            radius: 48
            width: root.width
            height: root.height
        }
        ColorOverlay {
            width: root.width
            height: root.height
            source: blur
            color: "#66808080"
        }
        Rectangle {
            id: strip
            color: "#66F0F0F0"
            anchors.bottom: parent.bottom;
            height: 2 * Kirigami.Units.gridUnit
            width: parent.width
            visible: children.length > 0
        }
    }
    bottomPadding: strip.children.length > 0 ? strip.height : 0

    // Container for the content of the header
    contentItem: Kirigami.FlexColumn {
        id: contentContainer

        maximumWidth: Kirigami.Units.gridUnit * 30

        RowLayout {
            Layout.fillHeight: true
            Layout.topMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit

            Kirigami.Icon {
                id: img
                source: root.source
                Layout.fillHeight: true
                Layout.preferredWidth: height
            }
            ColumnLayout {
                id: content
                Layout.alignment: Qt.AlignBottom
                Layout.leftMargin: Kirigami.Units.largeSpacing
            }
        }
    }
}
