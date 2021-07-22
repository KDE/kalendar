// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15 
import org.kde.kalendar 1.0
import QtQml.Models 2.15
import "dateutils.js" as DateUtils

Kirigami.ApplicationWindow {
    id: root

    property date currentDate: new Date()
    property date selectedDate: currentDate
    property int month: currentDate.getMonth()
    property int year: currentDate.getFullYear()

    title: i18n("Calendar")

    pageStack.initialPage: Kirigami.Settings.isMobile ? scheduleViewComponent : monthViewComponent

    globalDrawer: Kirigami.GlobalDrawer {
        isMenu: true
        actions: [
            Kirigami.Action {
                text: i18n("Add...")
                icon.name: "list-add"

                Kirigami.Action {
                    text: i18n("New event")
                    icon.name: "tag-events"
                    onTriggered: root.setUpAdd();
                }
            },
            Kirigami.Action {
                icon.name: "edit-undo"
                text: CalendarManager.undoRedoData.undoAvailable ?
                      i18n("Undo: ") + CalendarManager.undoRedoData.nextUndoDescription :
                      i18n("Undo")
                shortcut: StandardKey.Undo
                enabled: CalendarManager.undoRedoData.undoAvailable
                onTriggered: CalendarManager.undoAction();
            },
            Kirigami.Action {
                icon.name: "edit-redo"
                text: CalendarManager.undoRedoData.redoAvailable ?
                      i18n("Redo: ") + CalendarManager.undoRedoData.nextRedoDescription :
                      i18n("Redo")
                shortcut: StandardKey.Redo
                enabled: CalendarManager.undoRedoData.redoAvailable
                onTriggered: CalendarManager.redoAction();
            },
            Kirigami.Action {
                icon.name: "view-calendar"
                text: i18n("Month view")
                onTriggered: pageStack.layers.replace(monthViewComponent);
            },
            Kirigami.Action {
                icon.name: "view-calendar-list"
                text: i18n("Schedule view")
                onTriggered: pageStack.layers.replace(scheduleViewComponent)
            },
            Kirigami.Action {
                icon.name: "settings-configure"
                text: i18n("Settings")
                onTriggered: pageStack.layers.push("qrc:/SettingsPage.qml")
            },
            Kirigami.Action {
                icon.name: "application-exit"
                text: i18n("Quit")
                shortcut: StandardKey.Quit
                onTriggered: Qt.quit()
                visible: !Kirigami.Settings.isMobile
            }
        ]
    }

    contextDrawer: EventInfo {
        id: eventInfo

        contentItem.implicitWidth: Kirigami.Units.gridUnit * 25
        modal: !root.wideScreen || !enabled
        onEnabledChanged: drawerOpen = enabled && !modal
        onModalChanged: drawerOpen = !modal
        enabled: eventData != undefined && pageStack.layers.depth < 2 && pageStack.depth < 3
        handleVisible: enabled && pageStack.layers.depth < 2 && pageStack.depth < 3
        interactive: Kirigami.Settings.isMobile // Otherwise get weird bug where drawer gets dragged around despite no click

        onEditEvent: {
            setUpEdit(eventPtr, collectionId);
            if (modal) { eventInfo.close() }
        }
        onDeleteEvent: {
            setUpDelete(eventPtr, deleteDate)
            if (modal) { eventInfo.close() }
        }
    }

    EventEditor {
        id: eventEditor
        onAdded: CalendarManager.addEvent(collectionId, event.eventPtr)
        onEdited: CalendarManager.editEvent(collectionId, event.originalPtr, event.eventPtr)
        onCancel: pageStack.pop(monthViewComponent)
    }

    Loader {
        id: editorWindowedLoader
        active: false
        sourceComponent: Kirigami.ApplicationWindow {
            id: root

            width: Kirigami.Units.gridUnit * 40
            height: Kirigami.Units.gridUnit * 32

            // Probably a more elegant way of accessing the editor from outside than this.
            property var eventEditor: eventEditorInLoader

            pageStack.initialPage: eventEditorInLoader

            EventEditor {
                id: eventEditorInLoader
                onAdded: CalendarManager.addEvent(collectionId, event.eventPtr)
                onEdited: CalendarManager.editEvent(collectionId, event.originalEventPtr, event.eventPtr)
                onCancel: root.close()
            }

            visible: true
            onClosing: editorWindowedLoader.active = false
        }
    }

    function editorToUse() {
        if (!Kirigami.Settings.isMobile) {
            editorWindowedLoader.active = true
            return editorWindowedLoader.item.eventEditor
        } else {
            pageStack.push(eventEditor);
            return eventEditor;
        }
    }

    function setUpAdd(addDate) {
        let editorToUse = root.editorToUse();
        if (editorToUse.editMode || !editorToUse.eventWrapper) {
            editorToUse.eventWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; EventWrapper {id: event}',
                                                          editorToUse,
                                                          "event");
        }
        editorToUse.editMode = false;
        if(typeof(addDate) !== undefined && !isNaN(addDate.getTime())) {
            let existingStart = editorToUse.eventWrapper.eventStart;
            editorToUse.eventWrapper.eventStart = new Date(addDate.setHours(existingStart.getHours(), existingStart.getMinutes()));
            editorToUse.eventWrapper.eventEnd = new Date(addDate.setHours(existingStart.getHours() + 1, existingStart.getMinutes()));
        }
    }

    function setUpView(modelData, collectionData) {
        eventInfo.eventData = modelData
        eventInfo.collectionData = collectionData
        eventInfo.open()
    }

    function setUpEdit(eventPtr, collectionId) {
        let editorToUse = root.editorToUse();
        editorToUse.eventWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; EventWrapper {id: event}',
                                                      editorToUse,
                                                      "event");
        editorToUse.eventWrapper.eventPtr = eventPtr;
        editorToUse.eventWrapper.collectionId = collectionId;
        editorToUse.editMode = true;
    }

    function setUpDelete(eventPtr, deleteDate) {
        deleteEventSheet.eventWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; EventWrapper {id: event}',
                                                           deleteEventSheet,
                                                           "event");
        deleteEventSheet.eventWrapper.eventPtr = eventPtr
        deleteEventSheet.deleteDate = deleteDate
        deleteEventSheet.open()
    }

    DeleteEventSheet {
        id: deleteEventSheet
        onAddException: {
            eventWrapper.recurrenceExceptionsModel.addExceptionDateTime(exceptionDate);
            CalendarManager.editEvent(eventWrapper.eventPtr);
            deleteEventSheet.close();
        }
        onAddRecurrenceEndDate: {
            eventWrapper.recurrenceEndDateTime = endDate;
            CalendarManager.editEvent(eventWrapper.eventPtr);
            deleteEventSheet.close();
        }
        onDeleteEvent: {
            CalendarManager.deleteEvent(eventPtr);
            deleteEventSheet.close();
        }
    }

    Component {
        id: monthViewComponent

        MonthView {
            id: monthView

            // Make sure we get day from correct date, that is in the month we want
            title: DateUtils.addDaysToDate(startDate, 7).toLocaleDateString(Qt.locale(), "<b>MMMM</b> yyyy")
            currentDate: root.currentDate
            startDate: DateUtils.getFirstDayOfWeek(DateUtils.getFirstDayOfMonth(new Date(root.year, root.month)))
            month: root.month

            Layout.minimumWidth: applicationWindow().width * 0.66

            onAddEventReceived: root.setUpAdd(receivedAddDate)
            onViewEventReceived: root.setUpView(receivedModelData, receivedCollectionData)
            onEditEventReceived: root.setUpEdit(receivedEventPtr, receivedCollectionId)
            onDeleteEventReceived: root.setUpDelete(receivedEventPtr, receivedDeleteDate)

            onMonthChanged: root.month = month
            onYearChanged: root.year = year

            actions.contextualActions: [
                Kirigami.Action {
                    text: i18n("Add event")
                    icon.name: "list-add"
                    onTriggered: root.setUpAdd();
                }
            ]
        }
    }

    Component {
        id: scheduleViewComponent

        ScheduleView {
            id: scheduleView

            title: startDate.toLocaleDateString(Qt.locale(), "<b>MMMM</b> yyyy")
            selectedDate: root.currentDate.getMonth() === root.month ? root.currentDate : new Date(root.year, root.month)
            startDate: new Date(root.year, root.month)

            onMonthChanged: root.month = month
            onYearChanged: root.year = year

            onAddEvent: setUpAdd(addDate)
            onViewEvent: setUpView(modelData, collectionData)
            onEditEvent: setUpEdit(eventPtr, collectionData)
            onDeleteEvent: setUpDelete(eventPtr, deleteDate)

            actions.contextualActions: [
                Kirigami.Action {
                    text: i18n("Add event")
                    icon.name: "list-add"
                    onTriggered: root.setUpAdd();
                }
            ]
        }
    }
}
