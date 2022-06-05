// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar

MouseArea {
    id: mouseArea

    signal viewClicked(var incidenceData)
    signal editClicked(var incidencePtr)
    signal deleteClicked(var incidencePtr, date deleteDate)
    signal todoCompletedClicked(var incidencePtr)
    signal addSubTodoClicked(var parentWrapper)

    property double clickX
    property double clickY
    property var incidenceData
    property int collectionId
    property var collectionDetails

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: {
        if (mouse.button == Qt.LeftButton) {
            collectionDetails = Kalendar.CalendarManager.getCollectionDetails(mouseArea.collectionId)
            viewClicked(incidenceData);
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
    onDoubleClicked: {
        collectionDetails = Kalendar.CalendarManager.getCollectionDetails(mouseArea.collectionId)
        editClicked(incidenceData.incidencePtr);
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
                onClicked: viewClicked(incidenceData);
            }
            QQC2.MenuItem {
                icon.name: "edit-entry"
                text:i18n("Edit")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onClicked: editClicked(incidenceData.incidencePtr)
            }
            QQC2.MenuItem {
                icon.name: "edit-delete"
                text:i18n("Delete")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onClicked: deleteClicked(incidenceData.incidencePtr, incidenceData.startTime)
            }

            QQC2.MenuSeparator {
            }
            QQC2.MenuItem {
                icon.name: "task-complete"
                text: incidenceData.todoCompleted ? i18n("Mark Task as Incomplete") : i18n("Mark Task as Complete")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onClicked: todoCompletedClicked(incidenceData.incidencePtr)
                visible: incidenceData.incidenceType === Kalendar.IncidenceWrapper.TypeTodo
            }
            QQC2.MenuItem {
                icon.name: "list-add"
                text: i18n("Add Sub-Task")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onClicked: {
                    let parentWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', this, "incidence");
                    parentWrapper.incidenceItem = Kalendar.CalendarManager.incidenceItem(mouseArea.incidenceData.incidencePtr);
                    addSubTodoClicked(parentWrapper);
                }
                visible: incidenceData.incidenceType === Kalendar.IncidenceWrapper.TypeTodo
            }
            QQC2.Menu {
                id: setPriorityMenu
                title: i18n("Set priority...")
                enabled: incidenceData.incidenceType === Kalendar.IncidenceWrapper.TypeTodo
                z: 1001

                function setPriority(level) {
                    let wrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', this, "incidence");
                    wrapper.incidenceItem = Kalendar.CalendarManager.incidenceItem(mouseArea.incidenceData.incidencePtr);
                    wrapper.priority = level;
                    Kalendar.CalendarManager.editIncidence(wrapper);
                }

                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("None")
                    onClicked: setPriorityMenu.setPriority(0)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("1 (highest priority)")
                    onClicked: setPriorityMenu.setPriority(1)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("2 (mid-high priority)")
                    onClicked: setPriorityMenu.setPriority(2)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("3 (mid-high priority)")
                    onClicked: setPriorityMenu.setPriority(3)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("4 (mid-high priority)")
                    onClicked: setPriorityMenu.setPriority(4)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("5 (medium priority)")
                    onClicked: setPriorityMenu.setPriority(5)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("6 (mid-low priority)")
                    onClicked: setPriorityMenu.setPriority(6)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("7 (mid-low priority)")
                    onClicked: setPriorityMenu.setPriority(7)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("8 (mid-low priority)")
                    onClicked: setPriorityMenu.setPriority(8)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("9 (lowest priority)")
                    onClicked: setPriorityMenu.setPriority(9)
                }
            }
        }
    }
}
