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

    width: Kirigami.Units.gridUnit * 65

    property date currentDate: new Date()
    property date selectedDate: currentDate
    property int month: currentDate.getMonth()
    property int year: currentDate.getFullYear()

    property var openOccurrence

    readonly property var monthViewAction: KalendarApplication.action("open_month_view")
    readonly property var scheduleViewAction: KalendarApplication.action("open_schedule_view")
    readonly property var todoViewAction: KalendarApplication.action("open_todo_view")
    readonly property var createEventAction: KalendarApplication.action("create_event")
    readonly property var createTodoAction: KalendarApplication.action("create_todo")
    readonly property var configureAction: KalendarApplication.action("options_configure")
    readonly property var quitAction: KalendarApplication.action("file_quit")
    readonly property var undoAction: KalendarApplication.action("edit_undo")
    readonly property var redoAction: KalendarApplication.action("edit_redo")

    readonly property var todoViewSortAlphabeticallyAction: KalendarApplication.action("todoview_sort_alphabetically")
    readonly property var todoViewSortByDueDateAction: KalendarApplication.action("todoview_sort_by_due_date")
    readonly property var todoViewSortByPriorityAction: KalendarApplication.action("todoview_sort_by_priority")
    readonly property var todoViewOrderAscendingAction: KalendarApplication.action("todoview_order_ascending")
    readonly property var todoViewOrderDescendingAction: KalendarApplication.action("todoview_order_descending")
    readonly property var todoViewShowCompletedAction: KalendarApplication.action("todoview_show_completed")

    Component.onCompleted: if (Kirigami.Settings.isMobile) {
        scheduleViewAction.setChecked(true);
    } else {
        monthViewAction.setChecked(true);
    }

    Connections {
        target: KalendarApplication
        function onOpenMonthView() {
            pageStack.pop(null);
            pageStack.replace(monthViewComponent);
        }

        function onOpenScheduleView() {
            pageStack.pop(null);
            pageStack.replace(scheduleViewComponent);
        }

        function onOpenTodoView() {
            pageStack.pop(null);
            pageStack.replace(todoPageComponent);
        }

        function onCreateNewEvent() {
            root.setUpAdd(IncidenceWrapper.TypeEvent);
        }

        function onCreateNewTodo() {
            root.setUpAdd(IncidenceWrapper.TypeTodo);
        }

        function onUndo() {
            CalendarManager.undoAction();
        }

        function onRedo() {
            CalendarManager.redoAction();
        }

        function onTodoViewSortAlphabetically() {
            pageStack.currentItem.sortBy = TodoSortFilterProxyModel.SummaryColumn;
        }

        function onTodoViewSortByDueDate() {
            pageStack.currentItem.sortBy = TodoSortFilterProxyModel.EndTimeColumn;
        }

        function onTodoViewSortByPriority() {
            pageStack.currentItem.sortBy = TodoSortFilterProxyModel.PriorityIntColumn;
        }

        function onTodoViewOrderAscending() {
            pageStack.currentItem.ascendingOrder = true;
        }

        function onTodoViewOrderDescending() {
            pageStack.currentItem.ascendingOrder = false;
        }

        function onTodoViewShowCompleted() {
            pageStack.currentItem.completedSheet.open();
        }

        function onQuit() {
             Qt.quit();
        }

        function onOpenSettings() {
            pageStack.pushDialogLayer("qrc:/SettingsPage.qml", {
                width: root.width
            }, {
                title: i18n("Settings"),
                width: root.width - (Kirigami.Units.gridUnit * 4),
                height: root.height - (Kirigami.Units.gridUnit * 3)
            })
        }
    }

    Connections {
        target: CalendarManager

        function onUndoRedoDataChanged() {
            undoAction.enabled = CalendarManager.undoRedoData.undoAvailable;
            redoAction.enabled = CalendarManager.undoRedoData.redoAvailable;
        }
    }

    property Kirigami.Action createAction: Kirigami.Action {
        text: i18n("Create")
        icon.name: "list-add"

        Kirigami.Action {
            id: newEventAction
            text: i18n("New event")
            icon.name: "resource-calendar-insert"
            onTriggered: createEventAction.trigger()
        }
        Kirigami.Action {
            id: newTodoAction
            text: i18n("New todo")
            icon.name: "view-task-add"
            onTriggered: createTodoAction.trigger()
        }
    }

    title: {
        switch (pageStack.currentItem.objectName) {
            case "monthView":
                return i18n("Month View");
                break;
            case "scheduleView":
                return i18n("Schedule View");
                break;
            case "todoView":
                return i18n("Todo View");
                break;
            default:
                return i18n("Calendar");
        }
    }

    pageStack.initialPage: Kirigami.Settings.isMobile ? scheduleViewComponent : monthViewComponent

    menuBar: Loader {
        id: menuLoader
        active: Kirigami.Settings.hasPlatformMenuBar != undefined ?
                !Kirigami.Settings.hasPlatformMenuBar && !Kirigami.Settings.isMobile :
                !Kirigami.Settings.isMobile

        sourceComponent: WindowMenu {
            parentWindow: root
            todoMode: pageStack.currentItem.objectName == "todoView"
            Kirigami.Theme.colorSet: Kirigami.Theme.Header
        }
    }

    globalDrawer: Sidebar {
        bottomPadding: menuLoader.active ? menuLoader.height : 0
        todoMode: pageStack.currentItem.objectName == "todoView"
        onCalendarClicked: if(todoMode) pageStack.currentItem.filterCollectionId = collectionId
        onViewAllTodosClicked: if(todoMode) pageStack.currentItem.filterCollectionId = -1
    }

    contextDrawer: IncidenceInfo {
        id: incidenceInfo

        bottomPadding: menuLoader.active ? menuLoader.height : 0
        contentItem.implicitWidth: Kirigami.Units.gridUnit * 25
        modal: !root.wideScreen || !enabled
        onEnabledChanged: drawerOpen = enabled && !modal
        onModalChanged: drawerOpen = !modal
        enabled: incidenceData != undefined && pageStack.layers.depth < 2 && pageStack.depth < 3
        handleVisible: enabled && pageStack.layers.depth < 2 && pageStack.depth < 3
        interactive: Kirigami.Settings.isMobile // Otherwise get weird bug where drawer gets dragged around despite no click

        onIncidenceDataChanged: root.openOccurrence = incidenceData;
        onVisibleChanged: {
            if(visible) {
                root.openOccurrence = incidenceData;
            } else {
                root.openOccurrence = null;
            }
        }

        onAddSubTodo: {
            setUpAddSubTodo(parentWrapper);
            if (modal) { incidenceInfo.close() }
        }
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
        active: !Kirigami.Settings.isMobile
        sourceComponent: GlobalMenu {
            todoMode: pageStack.currentItem.filterCollectionId !== undefined
        }
        onLoaded: item.parentWindow = root;
    }

    Loader {
        id: editorWindowedLoader
        active: false
        sourceComponent: Kirigami.ApplicationWindow {
            id: root

            width: Kirigami.Units.gridUnit * 40
            height: Kirigami.Units.gridUnit * 32

            flags: Qt.Dialog | Qt.WindowCloseButtonHint

            // Probably a more elegant way of accessing the editor from outside than this.
            property var incidenceEditor: incidenceEditorInLoader

            pageStack.initialPage: incidenceEditorInLoader

            Loader {
                active: !Kirigami.Settings.isMobile
                source: Qt.resolvedUrl("qrc:/GlobalMenu.qml")
                onLoaded: item.parentWindow = root
            }

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

    function setUpAdd(type, addDate, collectionId) {
        let editorToUse = root.editorToUse();
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

            if(type === IncidenceWrapper.TypeEvent) {
                editorToUse.incidenceWrapper.incidenceStart = new Date(addDate.setHours(existingStart.getHours(), existingStart.getMinutes()));
                editorToUse.incidenceWrapper.incidenceEnd = new Date(addDate.setHours(existingStart.getHours() + 1, existingStart.getMinutes()));
            } else if (type === IncidenceWrapper.TypeTodo) {
                editorToUse.incidenceWrapper.incidenceEnd = new Date(addDate.setHours(existingEnd.getHours() + 1, existingEnd.getMinutes()));
            }
        }

        if(collectionId && collectionId >= 0) {
            editorToUse.incidenceWrapper.collectionId = collectionId;
        } else {
            editorToUse.incidenceWrapper.collectionId = CalendarManager.defaultCalendarId(editorToUse.incidenceWrapper);
        }
    }

    function setUpAddSubTodo(parentWrapper) {
        let editorToUse = root.editorToUse();
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

    function setUpView(modelData, collectionData) {
        incidenceInfo.incidenceData = modelData
        incidenceInfo.collectionData = collectionData
        incidenceInfo.open()
    }

    function setUpEdit(incidencePtr, collectionId) {
        let editorToUse = root.editorToUse();
        editorToUse.incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}',
            editorToUse, "incidence");
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
            this, "incidence");

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
            incidenceWrapper.setRecurrenceDataItem("endDateTime", endDate);
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
            objectName: "monthView"

            title: firstDayOfMonth.toLocaleDateString(Qt.locale(), "<b>MMMM</b> yyyy")
            currentDate: root.currentDate
            openOccurrence: root.openOccurrence

            onAddIncidence: root.setUpAdd(type, addDate)
            onViewIncidence: root.setUpView(modelData, collectionData)
            onEditIncidence: root.setUpEdit(incidencePtr, collectionId)
            onDeleteIncidence: root.setUpDelete(incidencePtr, deleteDate)
            onCompleteTodo: root.completeTodo(incidencePtr)
            onAddSubTodo: root.setUpAddSubTodo(parentWrapper)

            onMonthChanged: if(month !== currentDate.getMonth()) root.month = month
            onYearChanged: if(year !== currentDate.getFullYear()) root.year = year

            Component.onCompleted: setToDate(new Date(root.year, root.month))

            actions.contextualActions: createAction
        }
    }

    Component {
        id: scheduleViewComponent

        ScheduleView {
            id: scheduleView
            objectName: "scheduleView"

            title: startDate.toLocaleDateString(Qt.locale(), "<b>MMMM</b> yyyy")
            selectedDate: root.currentDate.getMonth() === root.month ? root.currentDate : new Date(root.year, root.month)
            startDate: new Date(root.year, root.month)
            openOccurrence: root.openOccurrence

            onMonthChanged: root.month = month
            onYearChanged: root.year = year

            onAddIncidence: root.setUpAdd(type, addDate)
            onViewIncidence: root.setUpView(modelData, collectionData)
            onEditIncidence: root.setUpEdit(incidencePtr, collectionId)
            onDeleteIncidence: root.setUpDelete(incidencePtr, deleteDate)
            onCompleteTodo: root.completeTodo(incidencePtr)
            onAddSubTodo: root.setUpAddSubTodo(parentWrapper)

            actions.contextualActions: createAction
        }
    }

    Component {
        id: todoPageComponent

        TodoPage {
            id: todoPage
            objectName: "todoView"

            onAddTodo: root.setUpAdd(IncidenceWrapper.TypeTodo, new Date(), collectionId)
            onViewTodo: root.setUpView(todoData, collectionData)
            onEditTodo: root.setUpEdit(todoPtr, collectionId)
            onDeleteTodo: root.setUpDelete(todoPtr, deleteDate)
            onCompleteTodo: root.completeTodo(todoPtr)
            onAddSubTodo: root.setUpAddSubTodo(parentWrapper)
        }
    }
}
