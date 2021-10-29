/*
 * SPDX-FileCopyrightText: 2015 Martin Klapetek <mklapetek@kde.org>
 * SPDX-FileCopyrightText: 2019 Linus Jahn <lnj@kaidan.im>
 * SPDX-FileCopyrightText: 2019 Jonah Brüchert <jbb@kaidan.im>
 * SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */
import QtQuick 2.15
import QtQuick.Controls 2.0 as Controls
import QtQuick.Layouts 1.7
import org.kde.kirigami 2.12 as Kirigami
import org.kde.kalendar 1.0

Kirigami.ScrollablePage {
    id: root
    property var attendeeAkonadiIds

    title: i18n("Contacts")

    signal addAttendee(var itemId, string email)
    signal removeAttendee(var itemId)

    Connections {
        target: ContactsManager

        function onEmailsFetched(emails, itemId) {
            if (emails.length > 1) {
                emailsView.itemId = itemId;
                emailsView.model = emails;
                emailPickerSheet.open();
            } else {
                addAttendee(itemId, undefined);
            }
        }
    }
    Kirigami.OverlaySheet {
        id: emailPickerSheet
        ListView {
            id: emailsView
            property var itemId

            implicitWidth: Kirigami.Units.gridUnit * 30

            delegate: Kirigami.BasicListItem {
                text: modelData

                onClicked: {
                    addAttendee(emailsView.itemId, modelData);
                    emailPickerSheet.close();
                }
            }
        }

        header: Kirigami.Heading {
            text: i18n("Select Email Address")
        }
    }
    ListView {
        id: contactsList
        property bool delegateSelected: false
        property string numberToCall

        clip: true
        model: ContactsManager.contactsModel
        reuseItems: true
        section.criteria: ViewSection.FirstCharacter
        section.property: "display"

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            text: i18n("No contacts")
            visible: contactsList.count === 0
        }

        delegate: ContactListItem {
            added: root.attendeeAkonadiIds.includes(model.itemId)
            avatarIcon: model && model.decoration
            height: Kirigami.Settings.isMobile ? Kirigami.Units.gridUnit * 3 : Kirigami.Units.gridUnit * 2
            name: model && model.display

            onClicked: added ? removeAttendee(itemId) : ContactsManager.contactEmails(model.itemId)
        }
        section.delegate: Kirigami.ListSectionHeader {
            text: section
        }
    }

    actions.main: Kirigami.Action {
        icon.name: "object-select-symbolic"
        text: i18n("Done")

        onTriggered: pageStack.pop()
    }
    header: Controls.Control {
        padding: Kirigami.Units.largeSpacing

        contentItem: Kirigami.SearchField {
            id: searchField
            onTextChanged: ContactsManager.contactsModel.setFilterFixedString(text)
        }
    }
}
