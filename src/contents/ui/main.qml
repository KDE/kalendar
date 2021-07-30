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
                text: i18n("Add")
                icon.name: "list-add"

                Kirigami.Action {
                    text: i18n("New event")
                    icon.name: "resource-calendar-insert"
                    onTriggered: root.setUpAdd(IncidenceWrapper.TypeEvent);
                }
                Kirigami.Action {
                    text: i18n("New todo")
                    icon.name: "view-task-add"
                    onTriggered: root.setUpAdd(IncidenceWrapper.TypeTodo);
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

    contextDrawer: IncidenceInfo {
        id: incidenceInfo

        contentItem.implicitWidth: Kirigami.Units.gridUnit * 25
        modal: !root.wideScreen || !enabled
        onEnabledChanged: drawerOpen = enabled && !modal
        onModalChanged: drawerOpen = !modal
        enabled: incidenceData != undefined && pageStack.layers.depth < 2 && pageStack.depth < 3
        handleVisible: enabled && pageStack.layers.depth < 2 && pageStack.depth < 3
        interactive: Kirigami.Settings.isMobile // Otherwise get weird bug where drawer gets dragged around despite no click

        onEditIncidence: {
            setUpEdit(incidencePtr, collectionId);
            if (modal) { incidenceInfo.close() }
        }
        onDeleteIncidence: {
            setUpDelete(incidencePtr, deleteDate)
            if (modal) { incidenceInfo.close() }
        }
    }

    IncidenceEditor {
        id: incidenceEditor
        onAdded: CalendarManager.addIncidence(incidenceWrapper)
        onEdited: CalendarManager.editIncidence(incidenceWrapper)
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
            property var incidenceEditor: incidenceEditorInLoader

            pageStack.initialPage: incidenceEditorInLoader

            IncidenceEditor {
                id: incidenceEditorInLoader
                onAdded: CalendarManager.addIncidence(incidenceWrapper)
                onEdited: CalendarManager.editIncidence(incidenceWrapper)
                onCancel: root.close()
            }

            visible: true
            onClosing: editorWindowedLoader.active = false
        }
    }

    function editorToUse() {
        if (!Kirigami.Settings.isMobile) {
            editorWindowedLoader.active = true
            return editorWindowedLoader.item.incidenceEditor
        } else {
            pageStack.push(incidenceEditor);
            return incidenceEditor;
        }
    }

    function setUpAdd(type, addDate) {
        let editorToUse = root.editorToUse();
        if (editorToUse.editMode || !editorToUse.incidenceWrapper) {
            editorToUse.incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}',
                                                              editorToUse,
                                                              "incidence");
        }
        editorToUse.editMode = false;

        if(type === IncidenceWrapper.TypeEvent) {
            editorToUse.incidenceWrapper.setNewEvent();
        } else if (type === IncidenceWrapper.TypeTodo) {
            editorToUse.incidenceWrapper.setNewTodo();
        }

        editorToUse.incidenceWrapper.collectionId = CalendarManager.defaultCalendarId(editorToUse.incidenceWrapper)

        if(addDate !== undefined && !isNaN(addDate.getTime())) {
            let existingStart = editorToUse.incidenceWrapper.incidenceStart;
            let existingEnd = editorToUse.incidenceWrapper.incidenceEnd;

            if(type === IncidenceWrapper.TypeEvent) {
                editorToUse.incidenceWrapper.incidenceStart = new Date(addDate.setHours(existingStart.getHours(), existingStart.getMinutes()));
                editorToUse.incidenceWrapper.incidenceEnd = new Date(addDate.setHours(existingStart.getHours() + 1, existingStart.getMinutes()));
            } else if (type === IncidenceWrapper.TypeTodo) {
                editorToUse.incidenceWrapper.incidenceEnd = new Date(addDate.setHours(existingEnd.getHours() + 1, existingEnd.getMinutes()));
            }
        }
    }

    function setUpView(modelData, collectionData) {
        incidenceInfo.incidenceData = modelData
        incidenceInfo.collectionData = collectionData
        incidenceInfo.open()
    }

    function setUpEdit(incidencePtr, collectionId) {
        let editorToUse = root.editorToUse();
        editorToUse.incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}',
                                                          editorToUse,
                                                          "incidence");
        editorToUse.incidenceWrapper.incidencePtr = incidencePtr;
        editorToUse.incidenceWrapper.collectionId = collectionId;
        editorToUse.editMode = true;
    }

    function setUpDelete(incidencePtr, deleteDate) {
        deleteIncidenceSheet.incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}',
                                                                   deleteIncidenceSheet,
                                                                   "incidence");
        deleteIncidenceSheet.incidenceWrapper.incidencePtr = incidencePtr;
        deleteIncidenceSheet.deleteDate = deleteDate;
        deleteIncidenceSheet.open();
    }

    function completeTodo(incidencePtr) {
        let todo = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}',
                                      this,
                                      "incidence");

        todo.incidencePtr = incidencePtr;

        if(todo.incidenceType === IncidenceWrapper.TypeTodo) {
            todo.todoCompleted = !todo.todoCompleted;
            CalendarManager.editIncidence(todo);
        }
    }

    DeleteIncidenceSheet {
        id: deleteIncidenceSheet
        onAddException: {
            incidenceWrapper.recurrenceExceptionsModel.addExceptionDateTime(exceptionDate);
            CalendarManager.editIncidence(incidenceWrapper);
            deleteIncidenceSheet.close();
        }
        onAddRecurrenceEndDate: {
            incidenceWrapper.recurrenceEndDateTime = endDate;
            CalendarManager.editIncidence(incidenceWrapper);
            deleteIncidenceSheet.close();
        }
        onDeleteIncidence: {
            CalendarManager.deleteIncidence(incidencePtr);
            deleteIncidenceSheet.close();
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

            onAddIncidenceReceived: root.setUpAdd(receivedType, receivedAddDate)
            onViewIncidenceReceived: root.setUpView(receivedModelData, receivedCollectionData)
            onEditIncidenceReceived: root.setUpEdit(receivedIncidencePtr, receivedCollectionId)
            onDeleteIncidenceReceived: root.setUpDelete(receivedIncidencePtr, receivedDeleteDate)
            onCompleteTodoReceived: root.completeTodo(receivedIncidencePtr)

            onMonthChanged: root.month = month
            onYearChanged: root.year = year

            actions.contextualActions: [
                Kirigami.Action {
                    text: i18n("Add")
                    icon.name: "list-add"

                    Kirigami.Action {
                        text: i18n("New event")
                        icon.name: "resource-calendar-insert"
                        onTriggered: root.setUpAdd(IncidenceWrapper.TypeEvent);
                    }
                    Kirigami.Action {
                        text: i18n("New todo")
                        icon.name: "view-task-add"
                        onTriggered: root.setUpAdd(IncidenceWrapper.TypeTodo);
                    }
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

            onAddIncidence: root.setUpAdd(type, addDate)
            onViewIncidence: root.setUpView(modelData, collectionData)
            onEditIncidence: root.setUpEdit(incidencePtr, collectionData)
            onDeleteIncidence: root.setUpDelete(incidencePtr, deleteDate)
            onCompleteTodo: root.completeTodo(incidencePtr)

            actions.contextualActions: [
                Kirigami.Action {
                    text: i18n("Add")
                    icon.name: "list-add"

                    Kirigami.Action {
                        text: i18n("New event")
                        icon.name: "resource-calendar-insert"
                        onTriggered: root.setUpAdd(IncidenceWrapper.TypeEvent);
                    }
                    Kirigami.Action {
                        text: i18n("New todo")
                        icon.name: "view-task-add"
                        onTriggered: root.setUpAdd(IncidenceWrapper.TypeTodo);
                    }
                }
            ]
        }
    }
}
