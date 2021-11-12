// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.0
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar

MouseArea {
    id: calendarMouseArea

    signal deleteCalendar(int collectionId, var collectionDetails)

    property double clickX
    property double clickY
    property var collectionId
    property var collectionDetails

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.RightButton
    onClicked: {
        if (mouse.button == Qt.RightButton) {
            clickX = mouseX;
            clickY = mouseY;
            calendarActions.createObject(calendarMouseArea, {}).open();
        }
    }
    onPressAndHold: if(Kirigami.Settings.isMobile) {
        clickX = mouseX;
        clickY = mouseY;
        calendarActions.createObject(calendarMouseArea, {}).open();
    }

    Loader {
        id: colorDialogLoader
        active: false
        sourceComponent: ColorDialog {
            id: colorDialog
            title: i18nc("@title:window", "Choose Calendar Color")
            color: calendarMouseArea.collectionDetails.color
            onAccepted: Kalendar.CalendarManager.setCollectionColor(calendarMouseArea.collectionId, color)
            onRejected: {
                close();
                colorDialogLoader.active = false;
            }
        }
    }

    Component {
        id: calendarActions

        QQC2.Menu {
            id: actionsPopup
            y: calendarMouseArea.clickY
            x: calendarMouseArea.clickX
            z: 1000
            Component.onCompleted: if(calendarMouseArea.collectionId && !calendarMouseArea.collectionDetails) calendarMouseArea.collectionDetails = Kalendar.CalendarManager.getCollectionDetails(calendarMouseArea.collectionId)

            QQC2.MenuItem {
                icon.name: "edit-entry"
                text: i18nc("@action:inmenu", "Edit calendar…")
                onClicked: Kalendar.CalendarManager.editCollection(calendarMouseArea.collectionId);
            }
            QQC2.MenuItem {
                icon.name: "view-refresh"
                text: i18nc("@action:inmenu", "Update calendar")
                onClicked: Kalendar.CalendarManager.updateCollection(calendarMouseArea.collectionId);
            }
            QQC2.MenuItem {
                icon.name: "edit-delete"
                text: i18nc("@action:inmenu", "Delete calendar")
                enabled: calendarMouseArea.collectionDetails["canDelete"]
                onClicked: deleteCalendar(calendarMouseArea.collectionId, calendarMouseArea.collectionDetails)
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
        }
    }
}
