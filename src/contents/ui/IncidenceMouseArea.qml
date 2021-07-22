// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

MouseArea {
    id: mouseArea

    signal viewClicked(var eventData, var collectionData)
    signal editClicked(var eventPtr, var collectionId)
    signal deleteClicked(var eventPtr, date deleteDate)

    property double clickX
    property double clickY
    property var eventData
    property var collectionDetails

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onPressed: {
        clickX = mouseX
        clickY = mouseY
        if (pressedButtons & Qt.LeftButton) {
            viewClicked(eventData, collectionDetails);
        } else if (pressedButtons & Qt.RightButton) {
            eventActions.createObject(mouseArea, {}).open();
        }
    }

    Component {
        id: eventActions
        QQC2.Menu {
            id: actionsPopup
            y: parent.y + mouseArea.clickY
            x: parent.x + mouseArea.clickX

            QQC2.MenuItem {
                icon.name: "edit-entry"
                text:i18n("Edit")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onClicked: editClicked(eventData.eventPtr, eventData.collectionId)
            }
            QQC2.MenuItem {
                icon.name: "edit-delete"
                text:i18n("Delete")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onClicked: deleteClicked(eventData.eventPtr, eventData.startTime)
            }
        }
    }
}
