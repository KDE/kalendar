// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtQml.Models 2.15
import QtGraphicalEffects 1.12

import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils
import org.kde.kalendar 1.0

Kirigami.ApplicationWindow {
    id: root

    width: Kirigami.Units.gridUnit * 65

    property date currentDate: new Date()
    Timer {
        interval: 5000;
        running: true
        repeat: true
        onTriggered: currentDate = new Date()
    }
    property date selectedDate: new Date()
    property var openOccurrence: {}
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    readonly property var monthViewAction: KalendarApplication.action("open_month_view")
    readonly property var weekViewAction: KalendarApplication.action("open_week_view")
    readonly property var scheduleViewAction: KalendarApplication.action("open_schedule_view")
    readonly property var todoViewAction: KalendarApplication.action("open_todo_view")
    readonly property var moveViewForwardsAction: KalendarApplication.action("move_view_forwards")
    readonly property var moveViewBackwardsAction: KalendarApplication.action("move_view_backwards")
    readonly property var moveViewToTodayAction: KalendarApplication.action("move_view_to_today")
    readonly property var openDateChangerAction: KalendarApplication.action("open_date_changer")
    readonly property var aboutPageAction: KalendarApplication.action("open_about_page")
    readonly property var toggleMenubarAction: KalendarApplication.action("toggle_menubar")
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
    readonly property var openKCommandBarAction: KalendarApplication.action("open_kcommand_bar")
    readonly property var tagManagerAction: KalendarApplication.action("open_tag_manager")

    pageStack.globalToolBar.canContainHandles: true
    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.ToolBar
    pageStack.initialPage: Kirigami.Settings.isMobile ? scheduleViewComponent : monthViewComponent

    QQC2.Action {
        id: closeOverlayAction
        shortcut: "Escape"
        onTriggered: {
            if(applicationWindow().overlay.children[0].visible) {
                applicationWindow().overlay.children[0].visible = false;
                return;
            }
            if(pageStack.layers.depth > 1) {
                pageStack.layers.pop();
                return;
            }
            if(contextDrawer.visible) {
                contextDrawer.close();
                return;
            }
        }
    }

    Component.onCompleted: {
        switch (Config.lastOpenedView) {
            case Config.MonthView:
                monthViewAction.trigger();
                break;
            case Config.WeekView:
                weekViewAction.trigger();
                break;
            case Config.ScheduleView:
                scheduleViewAction.trigger();
                break;
            case Config.TodoView:
                todoViewAction.trigger();
                break;
            default:
                monthViewAction.trigger();
                break;
        }
    }

    function switchView(newViewComponent) {
        if(pageStack.layers.depth > 1) {
            pageStack.layers.pop(pageStack.layers.initialItem);
        }
        let filterCache = pageStack.currentItem.filter;
        pageStack.replace(newViewComponent);
        pageStack.currentItem.filter = filterCache;

        if(filterHeader.active) {
            pageStack.currentItem.header = filterHeader.item;
        }
    }

    Connections {
        target: KalendarApplication
        function onOpenMonthView() {
            root.switchView(monthViewComponent);
        }

        function onOpenWeekView() {
            root.switchView(weekViewComponent);
        }

        function onOpenScheduleView() {
            root.switchView(scheduleViewComponent);
        }

        function onOpenTodoView() {
            filterHeader.active = true;
            root.switchView(todoPageComponent);
        }

        function onMoveViewForwards() {
            pageStack.currentItem.nextAction.trigger();
        }

        function onMoveViewBackwards() {
            pageStack.currentItem.previousAction.trigger();
        }

        function onMoveViewToToday() {
            pageStack.currentItem.todayAction.trigger();
        }

        function onOpenDateChanger() {
            dateChangeDrawer.open()
        }

        function onOpenAboutPage() {
            pageStack.layers.push("AboutPage.qml")
        }

        function onToggleMenubar() {
            Config.showMenubar = !Config.showMenubar;
            Config.save();
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
            Config.sort = Config.Alphabetically;
            Config.save();
        }

        function onTodoViewSortByDueDate() {
            Config.sort = Config.DueTime;
            Config.save();
        }

        function onTodoViewSortByPriority() {
            Config.sort = Config.Priority;
            Config.save();
        }

        function onTodoViewOrderAscending() {
            Config.ascendingOrder = true;
            Config.save();
        }

        function onTodoViewOrderDescending() {
            Config.ascendingOrder = false;
            Config.save();
        }

        function onTodoViewShowCompleted() {
            pageStack.pushDialogLayer(pageStack.currentItem.completedSheetComponent)
        }

        function onQuit() {
             Qt.quit();
        }

        function onOpenSettings() {
            const openDialogWindow = pageStack.pushDialogLayer("qrc:/SettingsPage.qml", {
                width: root.width
            }, {
                title: i18n("Configure"),
                width: Kirigami.Units.gridUnit * 45,
                height: Kirigami.Units.gridUnit * 35
            });

            if(!Kirigami.Settings.isMobile) {
                openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
            }
        }

        function onOpenTagManager() {
            const openDialogWindow = pageStack.pushDialogLayer("qrc:/TagManagerPage.qml", {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 30
            });

            if(!Kirigami.Settings.isMobile) {
                openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
            }
        }

        function onOpenKCommandBarAction() {
            kcommandbarLoader.active = true;
        }
    }

    Loader {
        id: kcommandbarLoader
        active: false
        source: 'qrc:/KQuickCommandbar.qml'
        onActiveChanged: if (active) {
            item.open()
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
            text: i18n("New Event…")
            icon.name: "resource-calendar-insert"
            onTriggered: createEventAction.trigger()
        }
        Kirigami.Action {
            id: newTodoAction
            text: i18n("New Task…")
            icon.name: "view-task-add"
            onTriggered: createTodoAction.trigger()
        }
    }

    title: if(pageStack.currentItem) {
        switch (pageStack.currentItem.objectName) {
            case "monthView":
                return i18n("Month View");
                break;
            case "scheduleView":
                return i18n("Schedule View");
                break;
            case "todoView":
                return i18n("Tasks View");
                break;
            default:
                return i18n("Calendar");
        }
    } else {
        return i18n("Calendar");
    }

    menuBar: Loader {
        id: menuLoader
        active: Kirigami.Settings.hasPlatformMenuBar != undefined ?
                !Kirigami.Settings.hasPlatformMenuBar && !Kirigami.Settings.isMobile : !Kirigami.Settings.isMobile && Config.showMenubar

        visible: Config.showMenubar
        height: visible ? implicitHeight : 0

        sourceComponent: WindowMenu {
            parentWindow: root
            todoMode: pageStack.currentItem.objectName == "todoView"
            Kirigami.Theme.colorSet: Kirigami.Theme.Header
        }
    }

    footer: Loader {
        id: bottomLoader
        active: Kirigami.Settings.isMobile
        visible: pageStack.layers.currentItem.objectName != "settingsPage"

        source: Qt.resolvedUrl("qrc:/BottomToolBar.qml")
    }

    globalDrawer: Sidebar {
        id: sidebar
        bottomPadding: menuLoader.active ? menuLoader.height : 0
        todoMode: pageStack.currentItem ? pageStack.currentItem.objectName === "todoView" : false
        onCalendarClicked: if(todoMode) {
            pageStack.currentItem.filter ?
                pageStack.currentItem.filter.collectionId = collectionId :
                pageStack.currentItem.filter = {"collectionId" : collectionId};
            pageStack.currentItem.filterChanged();
            pageStack.currentItem.filterCollectionDetails = CalendarManager.getCollectionDetails(collectionId);
        }
        onCalendarCheckChanged: {
            CalendarManager.save();
            if(todoMode && collectionId === pageStack.currentItem.filterCollectionId) {
                pageStack.currentItem.filterCollectionDetails = CalendarManager.getCollectionDetails(pageStack.currentItem.filterCollectionId);
                // HACK: The Todo View should be able to detect change in collection filtering independently
            }
        }
        onTagClicked: if(!pageStack.currentItem.filter || !pageStack.currentItem.filter.tags || !pageStack.currentItem.filter.tags.includes(tagName)) {
            pageStack.currentItem.filter ? pageStack.currentItem.filter.tags ?
                pageStack.currentItem.filter.tags.push(tagName) :
                pageStack.currentItem.filter.tags = [tagName] :
                pageStack.currentItem.filter = {"tags" : [tagName]};
            pageStack.currentItem.filterChanged();
            filterHeader.active = true;
            pageStack.currentItem.header = filterHeader.item;
        }
        onViewAllTodosClicked: if(todoMode) {
            pageStack.currentItem.filter.collectionId = -1;
            pageStack.currentItem.filter.name = "";
            pageStack.currentItem.filterChanged();
        }
    }

    contextDrawer: IncidenceInfo {
        id: incidenceInfo

        bottomPadding: menuLoader.active ? menuLoader.height : 0
        width: actualWidth
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

        readonly property int minWidth: Kirigami.Units.gridUnit * 15
        readonly property int maxWidth: Kirigami.Units.gridUnit * 25
        readonly property int defaultWidth: Kirigami.Units.gridUnit * 20
        property int actualWidth: {
            if (Config.incidenceInfoDrawerWidth === -1) {
                return defaultWidth;
            } else {
                return Config.incidenceInfoDrawerWidth;
            }
        }

        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: undefined
            width: 2
            z: 500
            cursorShape: !Kirigami.Settings.isMobile ? Qt.SplitHCursor : undefined
            enabled: true
            visible: true
            onPressed: _lastX = mapToGlobal(mouseX, mouseY).x
            onReleased: {
                Config.incidenceInfoDrawerWidth = incidenceInfo.actualWidth;
                Config.save();
            }
            property real _lastX: -1

            onPositionChanged: {
                if (_lastX === -1) {
                    return;
                }
                if (Qt.application.layoutDirection === Qt.RightToLeft) {
                    incidenceInfo.actualWidth = Math.min(incidenceInfo.maxWidth, Math.max(incidenceInfo.minWidth, Config.incidenceInfoDrawerWidth - _lastX + mapToGlobal(mouseX, mouseY).x))
                } else {
                    incidenceInfo.actualWidth = Math.min(incidenceInfo.maxWidth, Math.max(incidenceInfo.minWidth, Config.incidenceInfoDrawerWidth + _lastX - mapToGlobal(mouseX, mouseY).x))
                }
            }
        }
    }

    DateChanger {
        id: dateChangeDrawer
        y: pageStack.globalToolBar.height - 1
        showDays: pageStack.currentItem && pageStack.currentItem.objectName !== "monthView"
        date: root.selectedDate
        onDateSelected: if(visible) {
            pageStack.currentItem.setToDate(date);
            root.selectedDate = date;
        }
    }

    IncidenceEditor {
        id: incidenceEditor
        onAdded: CalendarManager.addIncidence(incidenceWrapper)
        onEdited: CalendarManager.editIncidence(incidenceWrapper)
        onCancel: pageStack.layers.pop()
    }

    Loader {
        id: globalMenuLoader
        active: !Kirigami.Settings.isMobile
        sourceComponent: GlobalMenu {
            todoMode: pageStack.currentItem && pageStack.currentItem.filterCollectionId !== undefined
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
                Keys.onEscapePressed: root.close()
            }

            visible: true
            onClosing: editorWindowedLoader.active = false
        }
    }

    Loader {
        id: filterHeader
        active: false
        sourceComponent: Item {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: visible ? header.implicitHeight + headerSeparator.height : 0
            visible: header.todoMode || header.filter.tags.length > 0 || header.visible

            Rectangle {
                width: header.width
                height: header.height
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                color: Kirigami.Theme.backgroundColor
            }

            FilterHeader {
                id: header
                anchors.fill: parent
                todoMode: pageStack.currentItem ? pageStack.currentItem.objectName === "todoView" : false
                filter: pageStack.currentItem && pageStack.currentItem.filter ?
                    pageStack.currentItem.filter : {"tags": [], "collectionId": -1}
                isDark: root.isDark

                onRemoveFilterTag: {
                    pageStack.currentItem.filter.tags.splice(pageStack.currentItem.filter.tags.indexOf(tagName), 1);
                    pageStack.currentItem.filterChanged();
                }
                onSearchTextChanged: if(todoMode) {
                    pageStack.currentItem.filter.name = text;
                    pageStack.currentItem.filterChanged();
                }
            }
            Kirigami.Separator {
                id: headerSeparator
                anchors.top: header.bottom
                width: parent.width
                height: 1
                z: -2

                RectangularGlow {
                    anchors.fill: parent
                    z: -1
                    glowRadius: 5
                    spread: 0.3
                    color: Qt.rgba(0.0, 0.0, 0.0, 0.15)
                }
            }
        }
    }

    function editorToUse() {
        if (!Kirigami.Settings.isMobile) {
            editorWindowedLoader.active = true
            return editorWindowedLoader.item.incidenceEditor
        } else {
            pageStack.layers.push(incidenceEditor);
            return incidenceEditor;
        }
    }

    function setUpAdd(type, addDate, collectionId, includeTime) {
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
        onDeleteIncidenceWithChildren: {
            CalendarManager.deleteIncidence(incidencePtr, true);
            deleteIncidenceSheet.close();
        }
    }

    Component {
        id: monthViewComponent

        MonthView {
            id: monthView
            objectName: "monthView"

            titleDelegate: ViewTitleDelegate {
                titleDateButton.date: monthView.firstDayOfMonth
                titleDateButton.onClicked: dateChangeDrawer.open()
            }
            currentDate: root.currentDate
            openOccurrence: root.openOccurrence

            onAddIncidence: root.setUpAdd(type, addDate)
            onViewIncidence: root.setUpView(modelData, collectionData)
            onEditIncidence: root.setUpEdit(incidencePtr, collectionId)
            onDeleteIncidence: root.setUpDelete(incidencePtr, deleteDate)
            onCompleteTodo: root.completeTodo(incidencePtr)
            onAddSubTodo: root.setUpAddSubTodo(parentWrapper)
            onDeselect: incidenceInfo.close()

            onMonthChanged: if(month !== root.selectedDate.getMonth() && !initialMonth) root.selectedDate = new Date (year, month, 1)
            onYearChanged: if(year !== root.selectedDate.getFullYear() && !initialMonth) root.selectedDate = new Date (year, month, 1)

            Component.onCompleted: setToDate(root.selectedDate, true)

            actions.contextualActions: createAction
        }
    }

    Component {
        id: scheduleViewComponent

        ScheduleView {
            id: scheduleView
            objectName: "scheduleView"

            titleDelegate: ViewTitleDelegate {
                titleDateButton.date: scheduleView.startDate
                titleDateButton.onClicked: dateChangeDrawer.open()
            }
            selectedDate: root.selectedDate
            openOccurrence: root.openOccurrence

            onDayChanged: if(day !== root.selectedDate.getDate() && !initialMonth) root.selectedDate = new Date (year, month, day)
            onMonthChanged: if(month !== root.selectedDate.getMonth() && !initialMonth) root.selectedDate = new Date (year, month, day)
            onYearChanged: if(year !== root.selectedDate.getFullYear() && !initialMonth) root.selectedDate = new Date (year, month, day)

            Component.onCompleted: setToDate(root.selectedDate, true)

            onAddIncidence: root.setUpAdd(type, addDate)
            onViewIncidence: root.setUpView(modelData, collectionData)
            onEditIncidence: root.setUpEdit(incidencePtr, collectionId)
            onDeleteIncidence: root.setUpDelete(incidencePtr, deleteDate)
            onCompleteTodo: root.completeTodo(incidencePtr)
            onAddSubTodo: root.setUpAddSubTodo(parentWrapper)
            onDeselect: incidenceInfo.close()

            actions.contextualActions: createAction
        }
    }

    Component {
        id: weekViewComponent

        WeekView {
            id: weekView
            objectName: "weekView"

            titleDelegate: ViewTitleDelegate {
                titleDateButton.range: true
                titleDateButton.date: weekView.startDate
                titleDateButton.lastDate: DateUtils.addDaysToDate(weekView.startDate, 6)
                titleDateButton.onClicked: dateChangeDrawer.open()
            }
            selectedDate: root.selectedDate
            currentDate: root.currentDate
            openOccurrence: root.openOccurrence

            onDayChanged: if(day !== root.selectedDate.getDate() && !initialWeek) root.selectedDate = new Date (year, month, day)
            onMonthChanged: if(month !== root.selectedDate.getMonth() && !initialWeek) root.selectedDate = new Date (year, month, day)
            onYearChanged: if(year !== root.selectedDate.getFullYear() && !initialWeek) root.selectedDate = new Date (year, month, day)

            Component.onCompleted: setToDate(root.selectedDate)

            onAddIncidence: root.setUpAdd(type, addDate, null, includeTime)
            onViewIncidence: root.setUpView(modelData, collectionData)
            onEditIncidence: root.setUpEdit(incidencePtr, collectionId)
            onDeleteIncidence: root.setUpDelete(incidencePtr, deleteDate)
            onCompleteTodo: root.completeTodo(incidencePtr)
            onAddSubTodo: root.setUpAddSubTodo(parentWrapper)
            onDeselect: incidenceInfo.close()

            actions.contextualActions: createAction
        }
    }

    Component {
        id: todoPageComponent

        TodoPage {
            id: todoPage
            objectName: "todoView"

            titleDelegate: RowLayout {
                spacing: 0
                QQC2.ToolButton {
                    visible: !Kirigami.Settings.isMobile
                    icon.name: sidebar.collapsed ? "sidebar-expand" : "sidebar-collapse"
                    onClicked: {
                        Config.forceCollapsedSidebar = !Config.forceCollapsedSidebar;
                        Config.save()
                    }

                    QQC2.ToolTip.text: sidebar.collapsed ? i18n("Expand Sidebar") : i18n("Collapse Sidebar")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
                Kirigami.Heading {
                    text: i18n("Tasks")
                }
            }

            onAddTodo: root.setUpAdd(IncidenceWrapper.TypeTodo, new Date(), collectionId)
            onViewTodo: root.setUpView(todoData, collectionData)
            onEditTodo: root.setUpEdit(todoPtr, collectionId)
            onDeleteTodo: root.setUpDelete(todoPtr, deleteDate)
            onCompleteTodo: root.completeTodo(todoPtr)
            onAddSubTodo: root.setUpAddSubTodo(parentWrapper)
            onDeselect: incidenceInfo.close()
        }
    }

    property Item hoverLinkIndicator: QQC2.Control {
        parent: overlay.parent
        property alias text: linkText.text
        opacity: text.length > 0 ? 1 : 0

        z: 99999
        x: 0
        y: parent.height - implicitHeight
        contentItem: QQC2.Label {
            id: linkText
        }
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        background: Rectangle {
             color: Kirigami.Theme.backgroundColor
        }
    }
}
