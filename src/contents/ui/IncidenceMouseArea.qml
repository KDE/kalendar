// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick 2.4
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar

MouseArea {
    id: mouseArea
    property double clickX
    property double clickY
    property var collectionDetails
    property var collectionId
    property var incidenceData

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    anchors.fill: parent
    hoverEnabled: true

    signal addSubTodoClicked(var parentWrapper)
    signal deleteClicked(var incidencePtr, date deleteDate)
    signal editClicked(var incidencePtr, var collectionId)
    signal todoCompletedClicked(var incidencePtr)
    signal viewClicked(var incidenceData, var collectionData)

    onClicked: {
        if (mouse.button == Qt.LeftButton) {
            collectionDetails = Kalendar.CalendarManager.getCollectionDetails(collectionId);
            viewClicked(incidenceData, collectionDetails);
        } else if (mouse.button == Qt.RightButton) {
            clickX = mouseX;
            clickY = mouseY;
            incidenceActions.createObject(mouseArea, {}).open();
        }
    }
    onPressAndHold: if (Kirigami.Settings.isMobile) {
        clickX = mouseX;
        clickY = mouseY;
        incidenceActions.createObject(mouseArea, {}).open();
    }

    Component {
        id: incidenceActions
        QQC2.Menu {
            id: actionsPopup
            x: mouseArea.clickX
            y: mouseArea.clickY
            z: 1000

            Component.onCompleted: if (mouseArea.collectionId && !mouseArea.collectionDetails)
                mouseArea.collectionDetails = Kalendar.CalendarManager.getCollectionDetails(mouseArea.collectionId)

            QQC2.MenuItem {
                icon.name: "dialog-icon-preview"
                text: i18n("View")

                onClicked: viewClicked(incidenceData, collectionDetails)
            }
            QQC2.MenuItem {
                enabled: !mouseArea.collectionDetails["readOnly"]
                icon.name: "edit-entry"
                text: i18n("Edit")

                onClicked: editClicked(incidenceData.incidencePtr, incidenceData.collectionId)
            }
            QQC2.MenuItem {
                enabled: !mouseArea.collectionDetails["readOnly"]
                icon.name: "edit-delete"
                text: i18n("Delete")

                onClicked: deleteClicked(incidenceData.incidencePtr, incidenceData.startTime)
            }
            QQC2.MenuSeparator {
                visible: incidenceData.incidenceType === Kalendar.IncidenceWrapper.TypeTodo
            }
            QQC2.MenuItem {
                enabled: !mouseArea.collectionDetails["readOnly"]
                icon.name: "task-complete"
                text: incidenceData.todoCompleted ? i18n("Mark Task as Incomplete") : i18n("Mark Task as Complete")
                visible: incidenceData.incidenceType === Kalendar.IncidenceWrapper.TypeTodo

                onClicked: todoCompletedClicked(incidenceData.incidencePtr)
            }
            QQC2.MenuItem {
                enabled: !mouseArea.collectionDetails["readOnly"]
                icon.name: "list-add"
                text: i18n("Add Sub-Task")
                visible: incidenceData.incidenceType === Kalendar.IncidenceWrapper.TypeTodo

                onClicked: {
                    let parentWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', this, "incidence");
                    parentWrapper.incidencePtr = mouseArea.incidenceData.incidencePtr;
                    parentWrapper.collectionId = mouseArea.collectionDetails.id;
                    addSubTodoClicked(parentWrapper);
                }
            }
        }
    }
}
