// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar

MouseArea {
    id: mouseArea

    signal viewClicked(var incidenceData, var collectionData)
    signal editClicked(var incidencePtr, var collectionId)
    signal deleteClicked(var incidencePtr, date deleteDate)
    signal todoCompletedClicked(var incidencePtr)
    signal addSubTodoClicked(var parentWrapper)

    property double clickX
    property double clickY
    property var incidenceData
    property var collectionId
    property var collectionDetails

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: {
        if (mouse.button == Qt.LeftButton) {
            collectionDetails = Kalendar.CalendarManager.getCollectionDetails(collectionId)
            viewClicked(incidenceData, collectionDetails);
        } else if (mouse.button == Qt.RightButton) {
            clickX = mouseX;
            clickY = mouseY;
            incidenceActions.createObject(mouseArea, {}).open();
        }
    }
    onPressAndHold: if(Kirigami.Settings.isMobile) {
        clickX = mouseX;
        clickY = mouseY;
        incidenceActions.createObject(mouseArea, {}).open();
    }

    Component {
        id: incidenceActions
        QQC2.Menu {
            id: actionsPopup
            y: mouseArea.clickY
            x: mouseArea.clickX
            z: 1000
            Component.onCompleted: if(mouseArea.collectionId && !mouseArea.collectionDetails) mouseArea.collectionDetails = Kalendar.CalendarManager.getCollectionDetails(mouseArea.collectionId)

            QQC2.MenuItem {
                icon.name: "dialog-icon-preview"
                text:i18n("View")
                onClicked: viewClicked(incidenceData, collectionDetails);
            }
            QQC2.MenuItem {
                icon.name: "edit-entry"
                text:i18n("Edit")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onClicked: editClicked(incidenceData.incidencePtr, incidenceData.collectionId)
            }
            QQC2.MenuItem {
                icon.name: "edit-delete"
                text:i18n("Delete")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onClicked: deleteClicked(incidenceData.incidencePtr, incidenceData.startTime)
            }
            QQC2.MenuSeparator {
                visible: incidenceData.incidenceType === Kalendar.IncidenceWrapper.TypeTodo
            }
            QQC2.MenuItem {
                icon.name: "task-complete"
                text: incidenceData.todoCompleted ? i18n("Mark Todo as Incomplete") : i18n("Mark Todo as Complete")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onClicked: todoCompletedClicked(incidenceData.incidencePtr)
                visible: incidenceData.incidenceType === Kalendar.IncidenceWrapper.TypeTodo
            }
            QQC2.MenuItem {
                icon.name: "list-add"
                text: i18n("Add Sub-Todo")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onClicked: {
                    let parentWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', this, "incidence");
                    parentWrapper.incidencePtr = mouseArea.incidenceData.incidencePtr;
                    parentWrapper.collectionId = mouseArea.collectionDetails.id;
                    addSubTodoClicked(parentWrapper);
                }
                visible: incidenceData.incidenceType === Kalendar.IncidenceWrapper.TypeTodo
            }
        }
    }
}
