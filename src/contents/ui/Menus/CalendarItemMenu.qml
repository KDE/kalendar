// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.0
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar
import org.kde.akonadi 1.0 as Akonadi

QQC2.Menu {
    id: actionsPopup
    z: 1000

    signal deleteCalendar(int collectionId, var collectionDetails)

    property var collectionId
    property var collectionDetails
    property Akonadi.AgentConfiguration agentConfiguration

    QQC2.MenuItem {
        icon.name: "edit-entry"
        text: i18nc("@action:inmenu", "Edit calendar…")
        onClicked: Kalendar.CalendarManager.editCollection(actionsPopup.collectionId);
    }
    QQC2.MenuItem {
        icon.name: "view-refresh"
        text: i18nc("@action:inmenu", "Update calendar")
        onClicked: Kalendar.CalendarManager.updateCollection(actionsPopup.collectionId);
    }
    QQC2.MenuItem {
        icon.name: "edit-delete"
        text: i18nc("@action:inmenu", "Delete calendar")
        enabled: actionsPopup.collectionDetails["canDelete"]
        onClicked: deleteCalendar(actionsPopup.collectionId, actionsPopup.collectionDetails)
    }
    QQC2.MenuSeparator {
    }
    QQC2.MenuItem {
        icon.name: "color-picker"
        text: i18nc("@action:inmenu", "Set calendar colour…")
        onClicked: {
            colorDialogLoader.active = true;
            colorDialogLoader.item.open();
        }
    }
    QQC2.MenuSeparator {
        visible: collectionDetails.isResource
    }

    QQC2.MenuItem {
        icon.name: "settings-configure"
        text: i18nc("@action:inmenu", "Calendar source settings…")
        onClicked: actionsPopup.agentConfiguration.editIdentifier(collectionDetails.resource)
        visible: collectionDetails.isResource
    }
    QQC2.MenuItem {
        icon.name: "view-refresh"
        text: i18nc("@action:inmenu", "Update calendar source")
        onClicked: actionsPopup.agentConfiguration.restartIdentifier(collectionDetails.resource)
        visible: collectionDetails.isResource
    }
    QQC2.MenuItem {
        icon.name: "edit-delete"
        text: i18nc("@action:inmenu", "Delete calendar source")
        onClicked: actionsPopup.agentConfiguration.removeIdentifier(collectionDetails.resource)
        visible: collectionDetails.isResource
    }
}
