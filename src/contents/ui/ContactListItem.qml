/*
 * SPDX-FileCopyrightText: 2017-2019 Kaidan Developers and Contributors 
 * SPDX-FileCopyrightText: 2019 Jonah Brüchert <jbb@kaidan.im>
 * SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.3
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.0 as Controls
import QtGraphicalEffects 1.0

import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0

Kirigami.AbstractListItem {
    id: listItem

    property string name
    property bool added: false
    property var avatarIcon

    contentItem: RowLayout {

        Kirigami.Avatar {
            id: avatar
            Layout.maximumHeight: parent.height
            Layout.maximumWidth: parent.height
            source: ContactsManager.decorationToUrl(avatarIcon)
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
    }
}
