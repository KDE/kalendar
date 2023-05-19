// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQml 2.15
import org.kde.kalendar.components 1.0
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kalendar 1.0
import org.kde.kalendar.calendar 1.0 as Calendar
import "./private/import" as Import

KalendarApp {
    id: root

    readonly property var _views: ({
        month: './views/MonthView.qml',
        week: './views/DayGridView.qml',
        schedule: './views/ScheduleView.qml',
        todo: './views/TodoView.qml',
    })

    property var openOccurrence: null

    /**
     * Args is an JS object containing the following values:
     *
     * - KCalendarCore::Incidence::Ptr incidence (optional): the incidence to edit
     * - IncidenceWrapper.Type type (optional): the type of the incidence
     * - bool initialDate (optional) default currentDate
     * - bool includeTime (optional) use time from initialDate instead of currentTime
     */
    function openEditor(args) {
        const editor = Navigation.pageStack.pushDialogLayers(Qt.resolvedUrl('./editor/IncidenceEditorPage.qml'));

        if (args.incidencePtr) {
            // Editor mode
            editor.editMode = true;
            editor.incidenceWrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(incidence);

        } else {
            // Creator mode
            editor.editMode = false;

            if (args.type === Calendar.IncidenceWrapper.TypeEvent) {
                editor.IncidenceWrapper.setNewEvent();
            } else if (args.type === Calendar.IncidenceWrapper.TypeTodo) {
                editor.IncidenceWrapper.setNewTodo();
            }

            let existingStart = editor.incidenceWrapper.incidenceStart;
            let existingEnd = editor.incidenceWrapper.incidenceEnd;

            if (args.initialDate) {
                let start = args.initialDate;

                if (!args.includeTime) {
                    start.setHours(existingStart.getHours(), existingStart.getMinutes());
                }

                let end = new Date(start);
                end.setHours(end.getHours() + 1);

                if (type === Calendar.IncidenceWrapper.TypeEvent) {
                    editor.incidenceWrapper.incidenceStart = start;
                    editor.incidenceWrapper.incidenceEnd = end;
                } else if (type === Calendar.IncidenceWrapper.TypeTodo) {
                    editor.incidenceWrapper.incidenceEnd = start;
                }
            }

            // Set collection
            if (args.collectionId && args.collectionId >= 0) {
                editor.incidenceWrapper.collectionId = collectionId;
            } else if (type === Calendar.IncidenceWrapper.TypeEvent && Calendar.Config.lastUsedEventCollection > -1) {
                editor.incidenceWrapper.collectionId = Calendar.Config.lastUsedEventCollection;
            } else if (type === Calendar.IncidenceWrapper.TypeTodo && Calendar.Config.lastUsedTodoCollection > -1) {
                editor.incidenceWrapper.collectionId = Calendar.Config.lastUsedTodoCollection;
            } else {
                editor.incidenceWrapper.collectionId = Calendar.CalendarManager.defaultCalendarId(editor.incidenceWrapper);
            }
        }
    }

    appName: 'calendar'

    onSwitchView: (viewName, args) => {
        if (viewName === 'editor') {
            openEditor(args)
            return;
        }

        const viewUrl = root._views[viewName];
        const component = Qt.createComponent(Qt.resolvedUrl(viewUrl));
        if (component.status !== Component.Ready) {
            console.error(component.errorString());
        }
        const page = component.createObject(Navigation.pageStack, args);
    }

    menuBar: Qt.resolvedUrl('./private/MenuBar.qml')
    globalMenuBar: Qt.resolvedUrl('./private/GlobalMenuBar.qml')

    hamburgerActions: [
        Kirigami.Action {
            icon.name: "edit-undo"
            text: Calendar.CalendarManager.undoRedoData.undoAvailable ?
                i18n("Undo: ") + Calendar.CalendarManager.undoRedoData.nextUndoDescription : undoAction.text
            shortcut: undoAction.shortcut
            enabled: Calendar.CalendarManager.undoRedoData.undoAvailable
            onTriggered: CalendarManager.undoAction();
        },
        Kirigami.Action {
            icon.name: KalendarApplication.iconName(redoAction.icon)
            text: Calendar.CalendarManager.undoRedoData.redoAvailable ?
                i18n("Redo: ") + Calendar.CalendarManager.undoRedoData.nextRedoDescription : redoAction.text
            shortcut: redoAction.shortcut
            enabled: Calendar.CalendarManager.undoRedoData.redoAvailable
            onTriggered: Calendar.CalendarManager.redoAction();
        },
        KActionFromAction {
            kalendarAction: "import_calendar"
        },
        KActionFromAction {
            text: i18n("Refresh All Calendars")
            kalendarAction: "refresh_all"
        }
    ]

    property Import.ImportHandler _connNav: Import.ImportHandler {
        id: importHandler
        readonly property var action: KalendarApplication.action(kalendarAction)
    }
}
