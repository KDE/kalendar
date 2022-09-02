// SPDX-FileCopyrightText: 2016 Michael Bohlender <michael.bohlender@kdemail.net>
// SPDX-FileCopyrightText: 2022 Devin Lin <espidev@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2

import org.kde.kalendar 1.0
import org.kde.kalendar.mail 1.0
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kitemmodels 1.0 as KItemModels

import './mailpartview'

Kirigami.ScrollablePage {
    id: root
    readonly property int mode: KalendarApplication.Mail

    property var item
    property var props

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    contextualActions: [
        Kirigami.Action {
            text: i18n("Move to trash")
            iconName: "albumfolder-user-trash"
            // TODO implement move to trash
        }
    ]

    ColumnLayout {
        spacing: 0

        QQC2.Label {
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            Layout.rightMargin: Kirigami.Units.largeSpacing * 2
            Layout.topMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit
            Layout.fillWidth: true

            text: props.title
            maximumLineCount: 2
            wrapMode: Text.Wrap
            elide: Text.ElideRIght

            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
        }

        // TODO use repeater to see the full conversation
        MailViewer {
            Layout.fillWidth: true

            item: root.item
            subject: props.title
            from: props.from
            to: props.to
            sender: props.sender
            dateTime: props.datetime
        }
    }
}
