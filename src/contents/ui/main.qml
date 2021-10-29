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
    readonly property var aboutPageAction: KalendarApplication.action("open_about_page")
    readonly property var configureAction: KalendarApplication.action("options_configure")
    property Kirigami.Action createAction: Kirigami.Action {
        icon.name: "list-add"
        text: i18n("Create")

        Kirigami.Action {
            id: newEventAction
            icon.name: "resource-calendar-insert"
            text: i18n("New Event…")

            onTriggered: createEventAction.trigger()
        }
        Kirigami.Action {
            id: newTodoAction
            icon.name: "view-task-add"
            text: i18n("New Task…")

            onTriggered: createTodoAction.trigger()
        }
    }
    readonly property var createEventAction: KalendarApplication.action("create_event")
    readonly property var createTodoAction: KalendarApplication.action("create_todo")
    property date currentDate: new Date()
    property Item hoverLinkIndicator: QQC2.Control {
        property alias text: linkText.text

        Kirigami.Theme.colorSet: Kirigami.Theme.View
        opacity: text.length > 0 ? 1 : 0
        parent: overlay.parent
        x: 0
        y: parent.height - implicitHeight
        z: 99999

        background: Rectangle {
            color: Kirigami.Theme.backgroundColor
        }
        contentItem: QQC2.Label {
            id: linkText
        }
    }
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)
    readonly property var monthViewAction: KalendarApplication.action("open_month_view")
    readonly property var moveViewBackwardsAction: KalendarApplication.action("move_view_backwards")
    readonly property var moveViewForwardsAction: KalendarApplication.action("move_view_forwards")
    readonly property var moveViewToTodayAction: KalendarApplication.action("move_view_to_today")
    readonly property var openDateChangerAction: KalendarApplication.action("open_date_changer")
    readonly property var openKCommandBarAction: KalendarApplication.action("open_kcommand_bar")
    property var openOccurrence: {
    }
    readonly property var quitAction: KalendarApplication.action("file_quit")
    readonly property var redoAction: KalendarApplication.action("edit_redo")
    readonly property var scheduleViewAction: KalendarApplication.action("open_schedule_view")
    property date selectedDate: new Date()
    readonly property var tagManagerAction: KalendarApplication.action("open_tag_manager")
    readonly property var todoViewAction: KalendarApplication.action("open_todo_view")
    readonly property var todoViewOrderAscendingAction: KalendarApplication.action("todoview_order_ascending")
    readonly property var todoViewOrderDescendingAction: KalendarApplication.action("todoview_order_descending")
    readonly property var todoViewShowCompletedAction: KalendarApplication.action("todoview_show_completed")
    readonly property var todoViewSortAlphabeticallyAction: KalendarApplication.action("todoview_sort_alphabetically")
    readonly property var todoViewSortByDueDateAction: KalendarApplication.action("todoview_sort_by_due_date")
    readonly property var todoViewSortByPriorityAction: KalendarApplication.action("todoview_sort_by_priority")
    readonly property var toggleMenubarAction: KalendarApplication.action("toggle_menubar")
    readonly property var undoAction: KalendarApplication.action("edit_undo")
    readonly property var weekViewAction: KalendarApplication.action("open_week_view")

    pageStack.globalToolBar.canContainHandles: true
    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.ToolBar
    pageStack.initialPage: Kirigami.Settings.isMobile ? scheduleViewComponent : monthViewComponent
    title: if (pageStack.currentItem) {
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
    width: Kirigami.Units.gridUnit * 65

    function completeTodo(incidencePtr) {
        let todo = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', this, "incidence");
        todo.incidencePtr = incidencePtr;
        if (todo.incidenceType === IncidenceWrapper.TypeTodo) {
            todo.todoCompleted = !todo.todoCompleted;
            CalendarManager.editIncidence(todo);
        }
    }
    function editorToUse() {
        if (!Kirigami.Settings.isMobile) {
            editorWindowedLoader.active = true;
            return editorWindowedLoader.item.incidenceEditor;
        } else {
            pageStack.layers.push(incidenceEditor);
            return incidenceEditor;
        }
    }
    function setUpAdd(type, addDate, collectionId, includeTime) {
        let editorToUse = root.editorToUse();
        if (editorToUse.editMode || !editorToUse.incidenceWrapper) {
            editorToUse.incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', editorToUse, "incidence");
        }
        editorToUse.editMode = false;
        if (type === IncidenceWrapper.TypeEvent) {
            editorToUse.incidenceWrapper.setNewEvent();
        } else if (type === IncidenceWrapper.TypeTodo) {
            editorToUse.incidenceWrapper.setNewTodo();
        }
        if (addDate !== undefined && !isNaN(addDate.getTime())) {
            let existingStart = editorToUse.incidenceWrapper.incidenceStart;
            let existingEnd = editorToUse.incidenceWrapper.incidenceEnd;
            let newStart = addDate;
            let newEnd = new Date(newStart.getFullYear(), newStart.getMonth(), newStart.getDate(), newStart.getHours() + 1, newStart.getMinutes());
            if (!includeTime) {
                newStart = new Date(addDate.setHours(existingStart.getHours(), existingStart.getMinutes()));
                newEnd = new Date(addDate.setHours(existingStart.getHours() + 1, existingStart.getMinutes()));
            }
            if (type === IncidenceWrapper.TypeEvent) {
                editorToUse.incidenceWrapper.incidenceStart = newStart;
                editorToUse.incidenceWrapper.incidenceEnd = newEnd;
            } else if (type === IncidenceWrapper.TypeTodo) {
                editorToUse.incidenceWrapper.incidenceEnd = newStart;
            }
        }
        if (collectionId && collectionId >= 0) {
            editorToUse.incidenceWrapper.collectionId = collectionId;
        } else if (type === IncidenceWrapper.TypeEvent && Config.lastUsedEventCollection > -1) {
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
            editorToUse.incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', editorToUse, "incidence");
        }
        editorToUse.editMode = false;
        editorToUse.incidenceWrapper.setNewTodo();
        editorToUse.incidenceWrapper.parent = parentWrapper.uid;
        editorToUse.incidenceWrapper.collectionId = parentWrapper.collectionId;
        editorToUse.incidenceWrapper.incidenceStart = parentWrapper.incidenceStart;
        editorToUse.incidenceWrapper.incidenceEnd = parentWrapper.incidenceEnd;
    }
    function setUpDelete(incidencePtr, deleteDate) {
        deleteIncidenceSheet.incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', deleteIncidenceSheet, "incidence");
        deleteIncidenceSheet.incidenceWrapper.incidencePtr = incidencePtr;
        deleteIncidenceSheet.deleteDate = deleteDate;
        deleteIncidenceSheet.open();
    }
    function setUpEdit(incidencePtr, collectionId) {
        let editorToUse = root.editorToUse();
        editorToUse.incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', editorToUse, "incidence");
        editorToUse.incidenceWrapper.incidencePtr = incidencePtr;
        editorToUse.incidenceWrapper.collectionId = collectionId;
        editorToUse.editMode = true;
    }
    function setUpView(modelData, collectionData) {
        incidenceInfo.incidenceData = modelData;
        incidenceInfo.collectionData = collectionData;
        incidenceInfo.open();
    }
    function switchView(newViewComponent) {
        if (pageStack.layers.depth > 1) {
            pageStack.layers.pop(pageStack.layers.initialItem);
        }
        let filterCache = pageStack.currentItem.filter;
        pageStack.replace(newViewComponent);
        pageStack.currentItem.filter = filterCache;
        if (filterHeader.active) {
            pageStack.currentItem.header = filterHeader.item;
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

    Timer {
        interval: 5000
        repeat: true
        running: true

        onTriggered: currentDate = new Date()
    }
    QQC2.Action {
        id: closeOverlayAction
        shortcut: "Escape"

        onTriggered: {
            if (applicationWindow().overlay.children[0].visible) {
                applicationWindow().overlay.children[0].visible = false;
                return;
            }
            if (pageStack.layers.depth > 1) {
                pageStack.layers.pop();
                return;
            }
            if (contextDrawer.visible) {
                contextDrawer.close();
                return;
            }
        }
    }
    Connections {
        target: KalendarApplication

        function onCreateNewEvent() {
            root.setUpAdd(IncidenceWrapper.TypeEvent);
        }
        function onCreateNewTodo() {
            root.setUpAdd(IncidenceWrapper.TypeTodo);
        }
        function onMoveViewBackwards() {
            pageStack.currentItem.previousAction.trigger();
        }
        function onMoveViewForwards() {
            pageStack.currentItem.nextAction.trigger();
        }
        function onMoveViewToToday() {
            pageStack.currentItem.todayAction.trigger();
        }
        function onOpenAboutPage() {
            pageStack.layers.push("AboutPage.qml");
        }
        function onOpenDateChanger() {
            dateChangeDrawer.open();
        }
        function onOpenKCommandBarAction() {
            kcommandbarLoader.active = true;
        }
        function onOpenMonthView() {
            root.switchView(monthViewComponent);
        }
        function onOpenScheduleView() {
            root.switchView(scheduleViewComponent);
        }
        function onOpenSettings() {
            const openDialogWindow = pageStack.pushDialogLayer("qrc:/SettingsPage.qml", {
                    "width": root.width
                }, {
                    "title": i18n("Configure"),
                    "width": Kirigami.Units.gridUnit * 45,
                    "height": Kirigami.Units.gridUnit * 35
                });
            if (!Kirigami.Settings.isMobile) {
                openDialogWindow.Keys.escapePressed.connect(function () {
                        openDialogWindow.closeDialog();
                    });
            }
        }
        function onOpenTagManager() {
            const openDialogWindow = pageStack.pushDialogLayer("qrc:/TagManagerPage.qml", {
                    "width": root.width
                }, {
                    "width": Kirigami.Units.gridUnit * 30,
                    "height": Kirigami.Units.gridUnit * 30
                });
            if (!Kirigami.Settings.isMobile) {
                openDialogWindow.Keys.escapePressed.connect(function () {
                        openDialogWindow.closeDialog();
                    });
            }
        }
        function onOpenTodoView() {
            filterHeader.active = true;
            root.switchView(todoPageComponent);
        }
        function onOpenWeekView() {
            root.switchView(weekViewComponent);
        }
        function onQuit() {
            Qt.quit();
        }
        function onRedo() {
            CalendarManager.redoAction();
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
            pageStack.pushDialogLayer(pageStack.currentItem.completedSheetComponent);
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
        function onToggleMenubar() {
            Config.showMenubar = !Config.showMenubar;
            Config.save();
        }
        function onUndo() {
            CalendarManager.undoAction();
        }
    }
    Loader {
        id: kcommandbarLoader
        active: false
        source: 'qrc:/KQuickCommandbar.qml'

        onActiveChanged: if (active) {
            item.open();
        }
    }
    Connections {
        target: CalendarManager

        function onUndoRedoDataChanged() {
            undoAction.enabled = CalendarManager.undoRedoData.undoAvailable;
            redoAction.enabled = CalendarManager.undoRedoData.redoAvailable;
        }
    }
    DateChanger {
        id: dateChangeDrawer
        date: root.selectedDate
        showDays: pageStack.currentItem && pageStack.currentItem.objectName !== "monthView"
        y: pageStack.globalToolBar.height - 1

        onDateSelected: if (visible) {
            pageStack.currentItem.setToDate(date);
            root.selectedDate = date;
        }
    }
    IncidenceEditor {
        id: incidenceEditor
        onAdded: CalendarManager.addIncidence(incidenceWrapper)
        onCancel: pageStack.layers.pop()
        onEdited: CalendarManager.editIncidence(incidenceWrapper)
    }
    Loader {
        id: globalMenuLoader
        active: !Kirigami.Settings.isMobile

        onLoaded: item.parentWindow = root

        sourceComponent: GlobalMenu {
            todoMode: pageStack.currentItem && pageStack.currentItem.filterCollectionId !== undefined
        }
    }
    Loader {
        id: editorWindowedLoader
        active: false

        sourceComponent: Kirigami.ApplicationWindow {
            id: root

            // Probably a more elegant way of accessing the editor from outside than this.
            property var incidenceEditor: incidenceEditorInLoader

            flags: Qt.Dialog | Qt.WindowCloseButtonHint
            height: Kirigami.Units.gridUnit * 32
            pageStack.initialPage: incidenceEditorInLoader
            visible: true
            width: Kirigami.Units.gridUnit * 40

            onClosing: editorWindowedLoader.active = false

            Loader {
                active: !Kirigami.Settings.isMobile
                source: Qt.resolvedUrl("qrc:/GlobalMenu.qml")

                onLoaded: item.parentWindow = root
            }
            IncidenceEditor {
                id: incidenceEditorInLoader
                Keys.onEscapePressed: root.close()
                onAdded: CalendarManager.addIncidence(incidenceWrapper)
                onCancel: root.close()
                onEdited: CalendarManager.editIncidence(incidenceWrapper)
            }
        }
    }
    Loader {
        id: filterHeader
        active: false

        sourceComponent: Item {
            height: visible ? header.implicitHeight + headerSeparator.height : 0
            visible: header.todoMode || header.filter.tags.length > 0 || header.visible

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            Rectangle {
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                Kirigami.Theme.inherit: false
                color: Kirigami.Theme.backgroundColor
                height: header.height
                width: header.width
            }
            FilterHeader {
                id: header
                anchors.fill: parent
                filter: pageStack.currentItem && pageStack.currentItem.filter ? pageStack.currentItem.filter : {
                    "tags": [],
                    "collectionId": -1
                }
                isDark: root.isDark
                todoMode: pageStack.currentItem ? pageStack.currentItem.objectName === "todoView" : false

                onRemoveFilterTag: {
                    pageStack.currentItem.filter.tags.splice(pageStack.currentItem.filter.tags.indexOf(tagName), 1);
                    pageStack.currentItem.filterChanged();
                }
                onSearchTextChanged: if (todoMode) {
                    pageStack.currentItem.filter.name = text;
                    pageStack.currentItem.filterChanged();
                }
            }
            Kirigami.Separator {
                id: headerSeparator
                anchors.top: header.bottom
                height: 1
                width: parent.width
                z: -2

                RectangularGlow {
                    anchors.fill: parent
                    color: Qt.rgba(0.0, 0.0, 0.0, 0.15)
                    glowRadius: 5
                    spread: 0.3
                    z: -1
                }
            }
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
            actions.contextualActions: createAction
            currentDate: root.currentDate
            objectName: "monthView"
            openOccurrence: root.openOccurrence

            Component.onCompleted: setToDate(root.selectedDate, true)
            onAddIncidence: root.setUpAdd(type, addDate)
            onAddSubTodo: root.setUpAddSubTodo(parentWrapper)
            onCompleteTodo: root.completeTodo(incidencePtr)
            onDeleteIncidence: root.setUpDelete(incidencePtr, deleteDate)
            onDeselect: incidenceInfo.close()
            onEditIncidence: root.setUpEdit(incidencePtr, collectionId)
            onMonthChanged: if (month !== root.selectedDate.getMonth() && !initialMonth)
                root.selectedDate = new Date(year, month, 1)
            onViewIncidence: root.setUpView(modelData, collectionData)
            onYearChanged: if (year !== root.selectedDate.getFullYear() && !initialMonth)
                root.selectedDate = new Date(year, month, 1)

            titleDelegate: ViewTitleDelegate {
                titleDateButton.date: monthView.firstDayOfMonth

                titleDateButton.onClicked: dateChangeDrawer.open()
            }
        }
    }
    Component {
        id: scheduleViewComponent
        ScheduleView {
            id: scheduleView
            actions.contextualActions: createAction
            objectName: "scheduleView"
            openOccurrence: root.openOccurrence
            selectedDate: root.selectedDate

            Component.onCompleted: setToDate(root.selectedDate, true)
            onAddIncidence: root.setUpAdd(type, addDate)
            onAddSubTodo: root.setUpAddSubTodo(parentWrapper)
            onCompleteTodo: root.completeTodo(incidencePtr)
            onDayChanged: if (day !== root.selectedDate.getDate() && !initialMonth)
                root.selectedDate = new Date(year, month, day)
            onDeleteIncidence: root.setUpDelete(incidencePtr, deleteDate)
            onDeselect: incidenceInfo.close()
            onEditIncidence: root.setUpEdit(incidencePtr, collectionId)
            onMonthChanged: if (month !== root.selectedDate.getMonth() && !initialMonth)
                root.selectedDate = new Date(year, month, day)
            onViewIncidence: root.setUpView(modelData, collectionData)
            onYearChanged: if (year !== root.selectedDate.getFullYear() && !initialMonth)
                root.selectedDate = new Date(year, month, day)

            titleDelegate: ViewTitleDelegate {
                titleDateButton.date: scheduleView.startDate

                titleDateButton.onClicked: dateChangeDrawer.open()
            }
        }
    }
    Component {
        id: weekViewComponent
        WeekView {
            id: weekView
            actions.contextualActions: createAction
            currentDate: root.currentDate
            objectName: "weekView"
            openOccurrence: root.openOccurrence
            selectedDate: root.selectedDate

            Component.onCompleted: setToDate(root.selectedDate)
            onAddIncidence: root.setUpAdd(type, addDate, null, includeTime)
            onAddSubTodo: root.setUpAddSubTodo(parentWrapper)
            onCompleteTodo: root.completeTodo(incidencePtr)
            onDayChanged: if (day !== root.selectedDate.getDate() && !initialWeek)
                root.selectedDate = new Date(year, month, day)
            onDeleteIncidence: root.setUpDelete(incidencePtr, deleteDate)
            onDeselect: incidenceInfo.close()
            onEditIncidence: root.setUpEdit(incidencePtr, collectionId)
            onMonthChanged: if (month !== root.selectedDate.getMonth() && !initialWeek)
                root.selectedDate = new Date(year, month, day)
            onViewIncidence: root.setUpView(modelData, collectionData)
            onYearChanged: if (year !== root.selectedDate.getFullYear() && !initialWeek)
                root.selectedDate = new Date(year, month, day)

            titleDelegate: ViewTitleDelegate {
                titleDateButton.date: weekView.startDate
                titleDateButton.lastDate: DateUtils.addDaysToDate(weekView.startDate, 6)
                titleDateButton.range: true

                titleDateButton.onClicked: dateChangeDrawer.open()
            }
        }
    }
    Component {
        id: todoPageComponent
        TodoPage {
            id: todoPage
            objectName: "todoView"

            onAddSubTodo: root.setUpAddSubTodo(parentWrapper)
            onAddTodo: root.setUpAdd(IncidenceWrapper.TypeTodo, new Date(), collectionId)
            onCompleteTodo: root.completeTodo(todoPtr)
            onDeleteTodo: root.setUpDelete(todoPtr, deleteDate)
            onDeselect: incidenceInfo.close()
            onEditTodo: root.setUpEdit(todoPtr, collectionId)
            onViewTodo: root.setUpView(todoData, collectionData)

            titleDelegate: RowLayout {
                spacing: 0

                QQC2.ToolButton {
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    QQC2.ToolTip.text: sidebar.collapsed ? i18n("Expand Sidebar") : i18n("Collapse Sidebar")
                    QQC2.ToolTip.visible: hovered
                    icon.name: sidebar.collapsed ? "sidebar-expand" : "sidebar-collapse"
                    visible: !Kirigami.Settings.isMobile

                    onClicked: {
                        Config.forceCollapsedSidebar = !Config.forceCollapsedSidebar;
                        Config.save();
                    }
                }
                Kirigami.Heading {
                    text: i18n("Tasks")
                }
            }
        }
    }

    contextDrawer: IncidenceInfo {
        id: incidenceInfo
        property int actualWidth: {
            if (Config.incidenceInfoDrawerWidth === -1) {
                return defaultWidth;
            } else {
                return Config.incidenceInfoDrawerWidth;
            }
        }
        readonly property int defaultWidth: Kirigami.Units.gridUnit * 20
        readonly property int maxWidth: Kirigami.Units.gridUnit * 25
        readonly property int minWidth: Kirigami.Units.gridUnit * 15

        bottomPadding: menuLoader.active ? menuLoader.height : 0
        enabled: incidenceData != undefined && pageStack.layers.depth < 2 && pageStack.depth < 3
        handleVisible: enabled && pageStack.layers.depth < 2 && pageStack.depth < 3
        interactive: Kirigami.Settings.isMobile // Otherwise get weird bug where drawer gets dragged around despite no click
        modal: !root.wideScreen || !enabled
        width: actualWidth

        onAddSubTodo: {
            setUpAddSubTodo(parentWrapper);
            if (modal) {
                incidenceInfo.close();
            }
        }
        onDeleteIncidence: {
            setUpDelete(incidencePtr, deleteDate);
            if (modal) {
                incidenceInfo.close();
            }
        }
        onEditIncidence: {
            setUpEdit(incidencePtr, collectionId);
            if (modal) {
                incidenceInfo.close();
            }
        }
        onEnabledChanged: drawerOpen = enabled && !modal
        onIncidenceDataChanged: root.openOccurrence = incidenceData
        onModalChanged: drawerOpen = !modal
        onVisibleChanged: {
            if (visible) {
                root.openOccurrence = incidenceData;
            } else {
                root.openOccurrence = null;
            }
        }

        MouseArea {
            property real _lastX: -1

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: undefined
            anchors.top: parent.top
            cursorShape: !Kirigami.Settings.isMobile ? Qt.SplitHCursor : undefined
            enabled: true
            visible: true
            width: 2
            z: 500

            onPositionChanged: {
                if (_lastX === -1) {
                    return;
                }
                if (Qt.application.layoutDirection === Qt.RightToLeft) {
                    incidenceInfo.actualWidth = Math.min(incidenceInfo.maxWidth, Math.max(incidenceInfo.minWidth, Config.incidenceInfoDrawerWidth - _lastX + mapToGlobal(mouseX, mouseY).x));
                } else {
                    incidenceInfo.actualWidth = Math.min(incidenceInfo.maxWidth, Math.max(incidenceInfo.minWidth, Config.incidenceInfoDrawerWidth + _lastX - mapToGlobal(mouseX, mouseY).x));
                }
            }
            onPressed: _lastX = mapToGlobal(mouseX, mouseY).x
            onReleased: {
                Config.incidenceInfoDrawerWidth = incidenceInfo.actualWidth;
                Config.save();
            }
        }
    }
    footer: Loader {
        id: bottomLoader
        active: Kirigami.Settings.isMobile
        source: Qt.resolvedUrl("qrc:/BottomToolBar.qml")
        visible: pageStack.layers.currentItem.objectName != "settingsPage"
    }
    globalDrawer: Sidebar {
        id: sidebar
        bottomPadding: menuLoader.active ? menuLoader.height : 0
        todoMode: pageStack.currentItem ? pageStack.currentItem.objectName === "todoView" : false

        onCalendarCheckChanged: {
            CalendarManager.save();
            if (todoMode && collectionId === pageStack.currentItem.filterCollectionId) {
                pageStack.currentItem.filterCollectionDetails = CalendarManager.getCollectionDetails(pageStack.currentItem.filterCollectionId);
                // HACK: The Todo View should be able to detect change in collection filtering independently
            }
        }
        onCalendarClicked: if (todoMode) {
            pageStack.currentItem.filter ? pageStack.currentItem.filter.collectionId = collectionId : pageStack.currentItem.filter = {
                "collectionId": collectionId
            };
            pageStack.currentItem.filterChanged();
            pageStack.currentItem.filterCollectionDetails = CalendarManager.getCollectionDetails(collectionId);
        }
        onTagClicked: if (!pageStack.currentItem.filter || !pageStack.currentItem.filter.tags || !pageStack.currentItem.filter.tags.includes(tagName)) {
            pageStack.currentItem.filter ? pageStack.currentItem.filter.tags ? pageStack.currentItem.filter.tags.push(tagName) : pageStack.currentItem.filter.tags = [tagName] : pageStack.currentItem.filter = {
                "tags": [tagName]
            };
            pageStack.currentItem.filterChanged();
            filterHeader.active = true;
            pageStack.currentItem.header = filterHeader.item;
        }
        onViewAllTodosClicked: if (todoMode) {
            pageStack.currentItem.filter.collectionId = -1;
            pageStack.currentItem.filter.name = "";
            pageStack.currentItem.filterChanged();
        }
    }
    menuBar: Loader {
        id: menuLoader
        active: Kirigami.Settings.hasPlatformMenuBar != undefined ? !Kirigami.Settings.hasPlatformMenuBar && !Kirigami.Settings.isMobile : !Kirigami.Settings.isMobile && Config.showMenubar
        height: visible ? implicitHeight : 0
        visible: Config.showMenubar

        sourceComponent: WindowMenu {
            Kirigami.Theme.colorSet: Kirigami.Theme.Header
            parentWindow: root
            todoMode: pageStack.currentItem.objectName == "todoView"
        }
    }
}
