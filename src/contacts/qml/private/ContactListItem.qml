/*
 * SPDX-FileCopyrightText: 2017-2019 Kaidan Developers and Contributors 
 * SPDX-FileCopyrightText: 2019 Jonah Brüchert <jbb@kaidan.im>
 * SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import QtGraphicalEffects 1.0

import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar.contact 1.0

Kirigami.BasicListItem {
    id: listItem

    property string name
    property bool added: false
    property var avatarIcon

    signal createContextMenu

    contentItem: RowLayout {
        Kirigami.Avatar {
            id: avatar
            Layout.maximumHeight: parent.height
            Layout.maximumWidth: parent.height
            source: ContactManager.decorationToUrl(avatarIcon)
            name: name
        }

        Kirigami.Heading {
            text: name
            textFormat: Text.PlainText
            elide: Text.ElideRight
            maximumLineCount: 1
            level: Kirigami.Settings.isMobile ? 3 : 0
            Layout.fillWidth: true
        }

        Kirigami.Icon {
            height: parent.height
            width: height
            source: "checkmark"
            visible: added
        }

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: listItem.createContextMenu()
        }
    }
}
