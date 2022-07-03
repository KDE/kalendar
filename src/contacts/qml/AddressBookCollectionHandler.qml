// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.0
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar
import org.kde.kalendar.contact 1.0
import './private'

TapHandler {
    id: handler

    property var collection
    property var collectionDetails

    acceptedButtons: Kirigami.Settings.isMobile ? Qt.LeftButton | Qt.RightButton : Qt.RightButton

    onTapped: addressBookActions.createObject(handler, {}).popup();

    onLongPressed: if (Kirigami.Settings.isMobile) {
        addressBookActions.createObject(handler, {}).popup();
    }

    property Loader colorDialogLoader: Loader {
        active: false
        sourceComponent: ColorDialog {
            id: colorDialog
            title: i18nc("@title:window", "Choose Address Book Color")
            color: handler.collectionDetails.color
            onAccepted: ContactManager.setCollectionColor(handler.collection, color)
            onRejected: {
                close();
                colorDialogLoader.active = false;
            }
        }
    }

    property Component addressBookActions: Component {
        AddressBookMenu {
            parent: handler.parent
            collection: handler.collection
            collectionDetails: handler.collectionDetails
        }
    }
}
