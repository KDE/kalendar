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

import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar.contact 1.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras

PlasmaComponents3.ItemDelegate {
    id: listItem

    property string name
    property var avatarIcon

    contentItem: RowLayout {
        Kirigami.Avatar {
            id: avatar
            Layout.maximumHeight: parent.height
            Layout.maximumWidth: parent.height
            source: ContactManager.decorationToUrl(avatarIcon)
            name: name
        }

        PlasmaExtras.Heading {
            text: name
            textFormat: Text.PlainText
            elide: Text.ElideRight
            maximumLineCount: 1
            level: 5
            Layout.fillWidth: true
        }
    }
}
