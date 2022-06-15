// SPDX-FileCopyrightText: 2016 Michael Bohlender <michael.bohlender@kdemail.net>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.7
import QtQuick.Controls 2.15 as QQC2

import org.kde.kalendar 1.0
import org.kde.kalendar.mail 1.0
import org.kde.kirigami 2.19 as Kirigami

Item {
    id: root
    property alias rootIndex: visualModel.rootIndex
    property alias model: visualModel.model
    property alias searchString: visualModel.searchString
    property alias autoLoadImages: visualModel.autoLoadImages
    property variant sender
    property variant date
    height: childrenRect.height

    Rectangle {
        id: border
        anchors {
            top: parent.top
            left: parent.left
            leftMargin: Kirigami.Units.smallSpacing
        }
        color: Kirigami.Theme.disabledTextColor
        height: partListView.height + sender.height
        width: Kirigami.Units.smallSpacing
    }

    Text {
        id: sender
        anchors {
            top: parent.top
            left: border.right
            leftMargin: Kirigami.Units.smallSpacing
            right: parent.right
        }

        text: i18n("sent by %1 on %2", root.sender, Qt.formatDateTime(root.date, "dd MMM yyyy hh:mm"))
        color: "grey"
        clip: true
    }
    ListView {
        id: partListView
        anchors {
            top: sender.bottom
            left: border.right
            margins: Kirigami.Units.smallSpacing
            leftMargin: Kirigami.Units.smallSpacing
        }
        model: MailPartModel {
            id: visualModel
        }
        spacing: 7
        height: contentHeight
        width: parent.width - Kirigami.Units.smallSpacing * 3
        interactive: false
    }
}
