// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma Singleton

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami

import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils
import org.kde.kalendar 1.0
import org.kde.kalendar.contact 1.0

QtObject {
    id: utilsObject
    property var appMain

    readonly property bool darkMode: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    function switchView(newViewComponent, viewSettings) {
        if(appMain.pageStack.layers.depth > 1) {
            appMain.pageStack.layers.pop(appMain.pageStack.layers.initialItem);
        }
        if (appMain.pageStack.depth > 1) {
            appMain.pageStack.pop();
        }
        appMain.pageStack.replace(newViewComponent);

        if (appMain.filterHeaderBarLoaderItem.active && appMain.pageStack.currentItem.mode !== KalendarApplication.Contact) {
            appMain.pageStack.currentItem.header = appMain.filterHeaderBarLoaderItem.item;
        }

        if(viewSettings) {
            for(const [key, value] of Object.entries(viewSettings)) {
                appMain.pageStack.currentItem[key] = value;
            }
        }

        if (appMain.pageStack.currentItem.mode === KalendarApplication.Event) {
            appMain.pageStack.currentItem.setToDate(appMain.selectedDate, true);
        }
    }

    function editorToUse() {
        if (!Kirigami.Settings.isMobile) {
            appMain.editorWindowedLoaderItem.active = true
            return appMain.editorWindowedLoaderItem.item.incidenceEditorPage
        } else {
            appMain.pageStack.layers.push(incidenceEditorPage);
            return incidenceEditorPage;
        }
    }

    function setUpAdd(type, addDate, collectionId, includeTime) {
        let editorToUse = utilsObject.editorToUse();
        if (editorToUse.editMode || !editorToUse.incidenceWrapper) {
            editorToUse.incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}',
                editorToUse, "incidence");
        }
        editorToUse.editMode = false;

        if(type === IncidenceWrapper.TypeEvent) {
            editorToUse.incidenceWrapper.setNewEvent();
        } else if (type === IncidenceWrapper.TypeTodo) {
            editorToUse.incidenceWrapper.setNewTodo();
        }

        if(addDate !== undefined && !isNaN(addDate.getTime())) {
            let existingStart = editorToUse.incidenceWrapper.incidenceStart;
            let existingEnd = editorToUse.incidenceWrapper.incidenceEnd;

            let newStart = addDate;
            let newEnd = new Date(newStart.getFullYear(), newStart.getMonth(), newStart.getDate(), newStart.getHours() + 1, newStart.getMinutes());

            if(!includeTime) {
                newStart = new Date(addDate.setHours(existingStart.getHours(), existingStart.getMinutes()));
                newEnd = new Date(addDate.setHours(existingStart.getHours() + 1, existingStart.getMinutes()));
            }

            if(type === IncidenceWrapper.TypeEvent) {
                editorToUse.incidenceWrapper.incidenceStart = newStart;
                editorToUse.incidenceWrapper.incidenceEnd = newEnd;
            } else if (type === IncidenceWrapper.TypeTodo) {
                editorToUse.incidenceWrapper.incidenceEnd = newStart;
            }
        }

        if(collectionId && collectionId >= 0) {
            editorToUse.incidenceWrapper.collectionId = collectionId;
        } else if(type === IncidenceWrapper.TypeEvent && Config.lastUsedEventCollection > -1) {
            editorToUse.incidenceWrapper.collectionId = Config.lastUsedEventCollection;
        } else if (type === IncidenceWrapper.TypeTodo && Config.lastUsedTodoCollection > -1) {
            editorToUse.incidenceWrapper.collectionId = Config.lastUsedTodoCollection;
        } else {
            editorToUse.incidenceWrapper.collectionId = CalendarManager.defaultCalendarId(editorToUse.incidenceWrapper);
        }
    }

    function setUpAddSubTodo(parentWrapper) {
        let editorToUse = utilsObject.editorToUse();
        if (editorToUse.editMode || !editorToUse.incidenceWrapper) {
            editorToUse.incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}',
                editorToUse, "incidence");
        }
        editorToUse.editMode = false;
        editorToUse.incidenceWrapper.setNewTodo();
        editorToUse.incidenceWrapper.parent = parentWrapper.uid;
        editorToUse.incidenceWrapper.collectionId = parentWrapper.collectionId;
        editorToUse.incidenceWrapper.incidenceStart = parentWrapper.incidenceStart;
        editorToUse.incidenceWrapper.incidenceEnd = parentWrapper.incidenceEnd;
    }

    function setUpView(modelData) {
        appMain.incidenceInfoDrawer.incidenceData = modelData;
        appMain.incidenceInfoDrawer.open();
    }

    function fakeModelDataFromIncidenceWrapper(incidenceWrapper) {
        // Spoof what a modelData would look like from the model
        const collectionDetails = CalendarManager.getCollectionDetails(incidenceWrapper.collectionId)
        const fakeModelData = {
            "text": incidenceWrapper.summary,
            "description": incidenceWrapper.description,
            "location": incidenceWrapper.location,
            "startTime": incidenceWrapper.incidenceStart,
            "endTime": incidenceWrapper.incidenceEnd,
            "allDay": incidenceWrapper.allDay,
            "todoCompleted": incidenceWrapper.todoCompleted,
            "priority": incidenceWrapper.priority,
            // These next two are mainly used in the hourly and day grid views, and we don't use this for
            // anything but the incidence info drawer -- for now. Remember that they are different to
            // the incidence's actual startTime and duration time -- these are just for positioning!
            //"starts":
            //"duration":
            "durationString": incidenceWrapper.durationDisplayString,
            "recurs": incidenceWrapper.recurrenceData.type !== 0,
            "hasReminders": incidenceWrapper.remindersModel.rowCount() > 0,
            "isOverdue": incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo &&
                         !isNaN(incidenceWrapper.incidenceEnd.getTime()) &&
                         incidenceWrapper.incidenceEnd < appMain.currentDate,
            "isReadOnly": collectionDetails.readOnly,
            "color": collectionDetails.color,
            "collectionId": incidenceWrapper.collectionId,
            "incidenceId": incidenceWrapper.uid,
            "incidenceType": incidenceWrapper.incidenceType,
            "incidenceTypeStr": incidenceWrapper.incidenceTypeStr,
            "incidenceTypeIcon": incidenceWrapper.incidenceIconName,
            "incidencePtr": incidenceWrapper.incidencePtr,
            //"incidenceOccurrence":
        };

        return fakeModelData;
    }

    function setUpEdit(incidencePtr) {
        let editorToUse = utilsObject.editorToUse();
        editorToUse.incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}',
            editorToUse, "incidence");
        editorToUse.incidenceWrapper.incidenceItem = CalendarManager.incidenceItem(incidencePtr);
        editorToUse.incidenceWrapper.triggerEditMode();
        editorToUse.editMode = true;
    }

    function setUpDelete(incidencePtr, deleteDate) {
        let incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', utilsObject, "incidence");
        incidenceWrapper.incidenceItem = CalendarManager.incidenceItem(incidencePtr);

        const openDialogWindow = appMain.pageStack.pushDialogLayer(appMain.deleteIncidencePageComponent, {
            incidenceWrapper: incidenceWrapper,
            deleteDate: deleteDate
        }, {
            width: Kirigami.Units.gridUnit * 32,
            height: Kirigami.Units.gridUnit * 6
        });

        openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
    }

    function completeTodo(incidencePtr) {
        let todo = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}',
            utilsObject, "incidence");

        todo.incidenceItem = CalendarManager.incidenceItem(incidencePtr);

        if(todo.incidenceType === IncidenceWrapper.TypeTodo) {
            todo.todoCompleted = !todo.todoCompleted;
            CalendarManager.editIncidence(todo);
        }
    }

    function setUpIncidenceDateChange(incidenceWrapper, startOffset, endOffset, occurrenceDate, caughtDelegate, allDay=null) {
        appMain.pageStack.currentItem.dragDropEnabled = false;

        if(appMain.pageStack.layers.currentItem && appMain.pageStack.layers.currentItem.dragDropEnabled) {
            appMain.pageStack.layers.currentItem.dragDropEnabled = false;
        }

        if(incidenceWrapper.recurrenceData.type === 0) {
            if (allDay !== null) {
                incidenceWrapper.allDay = allDay;
            }
            CalendarManager.updateIncidenceDates(incidenceWrapper, startOffset, endOffset);
        } else {
            const onClosingHandler = () => { caughtDelegate.caught = false; utilsObject.reenableDragOnCurrentView(); };
            const openDialogWindow = appMain.pageStack.pushDialogLayer(appMain.recurringIncidenceChangePageComponent, {
                incidenceWrapper: incidenceWrapper,
                startOffset: startOffset,
                endOffset: endOffset,
                occurrenceDate: occurrenceDate,
                caughtDelegate: caughtDelegate,
                allDay: allDay
            }, {
                width: Kirigami.Units.gridUnit * 34,
                height: Kirigami.Units.gridUnit * 6,
                onClosing: onClosingHandler()
            });

            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }
    }

    function reenableDragOnCurrentView() {
        appMain.pageStack.currentItem.dragDropEnabled = true;

        if(appMain.pageStack.layers.currentItem && appMain.pageStack.layers.currentItem.dragDropEnabled) {
            appMain.pageStack.layers.currentItem.dragDropEnabled = true;
        }
    }

    function openDayLayer(selectedDate) {
        if(!isNaN(selectedDate.getTime())) {
            appMain.selectedDate = selectedDate;
            appMain.dayViewAction.trigger();
        }
    }
}
