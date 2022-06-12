// SPDX-FileCopyrightText: 2016 Michael Bohlender <michael.bohlender@kdemail.net>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import org.kde.kalendar 1.0
import org.kde.kalendar.mail 1.0
import org.kde.kitemmodels 1.0 as KItemModels
import './mailpartview'

Kirigami.ScrollablePage {
    id: root

    title: props.title
    readonly property int mode: KalendarApplication.Mail
    property var item
    property var props

    ColumnLayout {
        // TODO use repeater to see the full conversation
        MailViewer {
            item: root.item
            subject: props.title
            from: props.from
            to: props.to
            sender: props.sender
            dateTime: props.datetime
        }
    }
}
