/*
 * SPDX-FileCopyrightText: 2015 Martin Klapetek <mklapetek@kde.org>
 * SPDX-FileCopyrightText: 2019 Linus Jahn <lnj@kaidan.im>
 * SPDX-FileCopyrightText: 2019 Jonah Brüchert <jbb@kaidan.im>
 * SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.12 as Kirigami
import org.kde.kalendar 1.0
import org.kde.kalendar.contact 1.0

Kirigami.ScrollablePage {
    id: root

    title: i18n("Contacts")

    property var attendeeAkonadiIds
    property alias contactDelegate: contactsList.delegate
    property var mode: KalendarApplication.Contact

    header: Controls.Control {
        contentItem: Kirigami.SearchField {
            id: searchField
            onTextChanged: root.model.setFilterFixedString(text)
        }
    }
    property alias model: contactsList.model

    ListView {
        id: contactsList

        reuseItems: true

        section.property: "display"
        section.criteria: ViewSection.FirstCharacter
        section.delegate: Kirigami.ListSectionHeader {text: section}
        clip: true
        model: ContactsModel {}

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            text: i18n("No contacts")
            visible: contactsList.count === 0
        }
    }
}
