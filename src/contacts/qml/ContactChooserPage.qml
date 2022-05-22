// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.12 as Kirigami
import org.kde.kalendar 1.0
import org.kde.kalendar.contact 1.0
import './private'

ContactsPage {
    id: root
    signal addAttendee(var itemId, string email)
    signal removeAttendee(var itemId)

    property var attendeeAkonadiIds

    actions.main: Kirigami.Action {
        icon.name: "object-select-symbolic"
        text: i18n("Done")
        onTriggered: pageStack.pop()
    }
    contactDelegate: ContactListItem {
        height: Kirigami.Settings.isMobile ? Kirigami.Units.gridUnit * 3 : Kirigami.Units.gridUnit * 2
        name: model && model.display
        avatarIcon: model && model.decoration
        added: root.attendeeAkonadiIds.includes(model.itemId)

        onClicked: if (added) {
            removeAttendee(itemId);
        } else {
            const allEmail = root.model.data(root.model.index(index, 0), ContactsModel.AllEmailsRole);
            console.log(model.itemId, model.item)
            if (allEmail.length > 1) {
                emailsView.model = allEmail;
                emailsView.itemId = model.itemId;
                emailPickerSheet.open();
            } else if(allEmail.length === 1) {
                addAttendee(model.itemId, allEmail[0])
            } else {
                addAttendee(model.itemId, undefined)
            }
        }
    }

    Kirigami.OverlaySheet {
        id: emailPickerSheet

        header: Kirigami.Heading {
            text: i18n("Select Email Address")
        }

        ListView {
            id: emailsView
            property var itemId

            implicitWidth: Kirigami.Units.gridUnit * 30
            model: []

            delegate: Kirigami.BasicListItem {
                text: modelData
                onClicked: {
                    addAttendee(emailsView.itemId, modelData);
                    emailPickerSheet.close();
                }
            }
        }
    }

}
