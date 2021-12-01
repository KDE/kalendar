// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtQml.Models 2.15
import QtGraphicalEffects 1.12
import QtQuick.Dialogs 1.0

import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils
import org.kde.kalendar 1.0

Kirigami.ApplicationWindow {
    id: root

    width: Kirigami.Units.gridUnit * 65

    minimumWidth: Kirigami.Units.gridUnit * 15
    minimumHeight: Kirigami.Units.gridUnit * 20
    onClosing: KalendarApplication.saveWindowGeometry(root)

    property date currentDate: new Date()
    Timer {
        interval: 5000;
        running: true
        repeat: true
        onTriggered: currentDate = new Date()
    }
    property date selectedDate: new Date()
    property var openOccurrence: {}
    property var filter: {
        "collectionId": -1,
        "tags": [],
        "name": ""
    }
    onFilterChanged: if(pageStack.currentItem.objectName === "todoView") pageStack.currentItem.filter = filter
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    readonly property var monthViewAction: KalendarApplication.action("open_month_view")
    readonly property var weekViewAction: KalendarApplication.action("open_week_view")
    readonly property var threeDayViewAction: KalendarApplication.action("open_threeday_view")
    readonly property var dayViewAction: KalendarApplication.action("open_day_view")
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
    readonly property var importAction: KalendarApplication.action("import_calendar")
    readonly property var quitAction: KalendarApplication.action("file_quit")
    readonly property var undoAction: KalendarApplication.action("edit_undo")
    readonly property var redoAction: KalendarApplication.action("edit_redo")
    readonly property var refreshAllAction: KalendarApplication.action("refresh_all_calendars")

    readonly property var todoViewSortAlphabeticallyAction: KalendarApplication.action("todoview_sort_alphabetically")
    readonly property var todoViewSortByDueDateAction: KalendarApplication.action("todoview_sort_by_due_date")
    readonly property var todoViewSortByPriorityAction: KalendarApplication.action("todoview_sort_by_priority")
    readonly property var todoViewOrderAscendingAction: KalendarApplication.action("todoview_order_ascending")
    readonly property var todoViewOrderDescendingAction: KalendarApplication.action("todoview_order_descending")
    readonly property var todoViewShowCompletedAction: KalendarApplication.action("todoview_show_completed")
    readonly property var openKCommandBarAction: KalendarApplication.action("open_kcommand_bar")
    readonly property var tagManagerAction: KalendarApplication.action("open_tag_manager")

    property var calendarFilesToImport: []
    property bool calendarImportInProgress: false

    onCalendarImportInProgressChanged: if (!calendarImportInProgress && calendarFilesToImport.length > 0) {
        importCalendarTimer.restart()
    }

    // Timer is needed here since opening and closing a window at the same time can cause
    // some kwin-x11 freeze
    Timer {
        id: importCalendarTimer
        interval: 1000
        running: false
        onTriggered: {
            // Start importing new calendar
            KalendarApplication.importCalendarFromFile(calendarFilesToImport.shift())
        }
    }

    pageStack.globalToolBar.canContainHandles: true
    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.ToolBar
    pageStack.initialPage: scheduleViewComponent

    property bool ignoreCurrentPage: true // HACK: ideally we just push an empty page here and save ourselves the trouble,
    // but we have had issues with pushing empty Kirigami pages somehow causing mobile controls to show up on desktop.
    // We use this property to temporarily allow a view to be replaced by a view of the same type

    Component.onCompleted: {
        switch (Config.lastOpenedView) {
            case Config.MonthView:
                monthViewAction.trigger();
                break;
            case Config.WeekView:
                weekViewAction.trigger();
                break;
            case Config.ThreeDayView:
                threeDayViewAction.trigger();
                break;
            case Config.DayView:
                dayViewAction.trigger();
                break;
            case Config.ScheduleView:
                scheduleViewAction.trigger();
                break;
            case Config.TodoView:
                todoViewAction.trigger();
                break;
            default:
                Kirigami.Settings.isMobile ? scheduleViewAction.trigger() : monthViewAction.trigger();
                break;
        }
        ignoreCurrentPage = false;
    }

    QQC2.Action {
        id: closeOverlayAction
        shortcut: "Escape"
        onTriggered: {
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

    QQC2.Action {
        id: deleteIncidenceAction
        shortcut: "Delete"
        onTriggered: {
            if(root.openOccurrence) {
                root.setUpDelete(incidenceInfo.incidenceData.incidencePtr, incidenceInfo.incidenceData.startTime);
            }
        }
    }

    function switchView(newViewComponent, viewSettings) {
        if(pageStack.layers.depth > 1) {
            pageStack.layers.pop(pageStack.layers.initialItem);
        }
        pageStack.replace(newViewComponent);

        if(filterHeader.active) {
            pageStack.currentItem.header = filterHeader.item;
        }

        if(viewSettings) {
            for(const [key, value] of Object.entries(viewSettings)) {
                pageStack.currentItem[key] = value;
            }
        }

        if(pageStack.currentItem.objectName !== "todoView") {
            pageStack.currentItem.setToDate(root.selectedDate, true);
        }
    }

    Connections {
        target: KalendarApplication
        function onOpenMonthView() {
            if(pageStack.currentItem.objectName !== "monthView" || root.ignoreCurrentPage) {
                monthScaleModelLoader.active = true;
                root.switchView(monthViewComponent);
            }
        }

        function onOpenWeekView() {
            if(pageStack.currentItem.objectName !== "weekView" || root.ignoreCurrentPage) {
                weekScaleModelLoader.active = true;
                root.switchView(hourlyViewComponent);
            }
        }

        function onOpenThreeDayView() {
            if(pageStack.currentItem.objectName !== "threeDayView" || root.ignoreCurrentPage) {
                threeDayScaleModelLoader.active = true;
                root.switchView(hourlyViewComponent, { daysToShow: 3 });
            }
        }

        function onOpenDayView() {
            if(pageStack.currentItem.objectName !== "dayView" || root.ignoreCurrentPage) {
                dayScaleModelLoader.active = true;
                root.switchView(hourlyViewComponent, { daysToShow: 1 });
            }
        }

        function onOpenScheduleView() {
            if(pageStack.currentItem.objectName !== "scheduleView" || root.ignoreCurrentPage) {
                monthScaleModelLoader.active = true;
                root.switchView(scheduleViewComponent);
            }
        }

        function onOpenTodoView() {
            if(pageStack.currentItem.objectName !== "todoView") {
                filterHeader.active = true;
                root.switchView(todoPageComponent);
            }
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
            const openDialogWindow = pageStack.pushDialogLayer(pageStack.currentItem.completedSheetComponent);
            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }

        function onImportCalendar() {
            filterHeader.active = true;
            importFileDialog.open();
        }

        function onImportCalendarFromFile(file) {

            if (root.calendarImportInProgress) {
                // Save urls to import
                root.calendarFilesToImport.push(file)
                return;
            }
            importFileDialog.selectedUrl = file // FIXME don't piggy-back on importFileDialog
            root.calendarImportInProgress = true;

            const openDialogWindow = pageStack.pushDialogLayer(importChoicePageComponent, {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 8
            });
        }

        function onImportIntoExistingFinished(success, total) {
            filterHeader.active = true;
            pageStack.currentItem.header = filterHeader.item;

            if(success) {
                filterHeader.item.messageItem.type = Kirigami.MessageType.Positive;
                filterHeader.item.messageItem.text = i18nc("%1 is a number", "%1 incidences were imported successfully.", total);
            } else {
                filterHeader.item.messageItem.type = Kirigami.MessageType.Error;
                filterHeader.item.messageItem.text = i18nc("%1 is the error message", "An error occurred importing incidences: %1", KalendarApplication.importErrorMessage);
            }

            filterHeader.item.messageItem.visible = true;
        }

        function onImportIntoNewFinished(success) {
            filterHeader.active = true;
            pageStack.currentItem.header = filterHeader.item;

            if(success) {
                filterHeader.item.messageItem.type = Kirigami.MessageType.Positive;
                filterHeader.item.messageItem.text = i18n("New calendar  created from imported file successfully.");
            } else {
                filterHeader.item.messageItem.type = Kirigami.MessageType.Error;
                filterHeader.item.messageItem.text = i18nc("%1 is the error message", "An error occurred importing incidences: %1", KalendarApplication.importErrorMessage);
            }

            filterHeader.item.messageItem.visible = true;
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
            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }

        function onOpenTagManager() {
            const openDialogWindow = pageStack.pushDialogLayer("qrc:/TagManagerPage.qml", {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 30
            });

            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }

        function onOpenKCommandBarAction() {
            kcommandbarLoader.active = true;
        }

        function onRefreshAllCalendars() {
            CalendarManager.updateAllCollections();
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
            case "weekView":
                return i18n("Week View");
                break;
            case "threeDayView":
                return i18n("3 Day View");
                break;
            case "dayView":
                return i18n("Day View");
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
            todoMode: pageStack.currentItem.objectName === "todoView"
            Kirigami.Theme.colorSet: Kirigami.Theme.Header
        }
    }

    footer: Loader {
        id: bottomLoader
        active: Kirigami.Settings.isMobile
        visible: pageStack.currentItem.objectName !== "settingsPage"

        source: Qt.resolvedUrl("qrc:/BottomToolBar.qml")
    }

    globalDrawer: Sidebar {
        id: sidebar
        bottomPadding: menuLoader.active ? menuLoader.height : 0
        todoMode: pageStack.currentItem ? pageStack.currentItem.objectName === "todoView" : false
        activeTags: root.filter && root.filter.tags ?
                    root.filter.tags : []
        onSearchTextChanged: {
            if(root.filter) {
                root.filter.name = searchText;
            } else {
                root.filter = {name: searchText};
            }
            root.filterChanged();
        }
        onCalendarClicked: if(todoMode) {
            root.filter ?
                root.filter.collectionId = collectionId :
                root.filter = {"collectionId" : collectionId};
            root.filterChanged();
            pageStack.currentItem.filterCollectionDetails = CalendarManager.getCollectionDetails(collectionId);
        }
        onCalendarCheckChanged: {
            CalendarManager.save();
            if(todoMode && collectionId === pageStack.currentItem.filterCollectionId) {
                pageStack.currentItem.filterCollectionDetails = CalendarManager.getCollectionDetails(pageStack.currentItem.filterCollectionId);
                // HACK: The Todo View should be able to detect change in collection filtering independently
            }
        }
        onTagClicked: root.toggleFilterTag(tagName)
        onViewAllTodosClicked: if(todoMode) {
            root.filter.collectionId = -1;
            root.filter.tags = [];
            root.filter.name = "";
            root.filterChanged();
        }
        onDeleteCalendar: {
            const openDialogWindow = pageStack.pushDialogLayer(deleteCalendarSheetComponent, {
                collectionId: collectionId,
                collectionDetails: collectionDetails
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 6
            });

            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
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

        activeTags: root.filter && root.filter.tags ?
                    root.filter.tags : []
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
            setUpEdit(incidencePtr);
            if (modal) { incidenceInfo.close() }
        }
        onDeleteIncidence: {
            setUpDelete(incidencePtr, deleteDate)
            if (modal) { incidenceInfo.close() }
        }
        onTagClicked: root.toggleFilterTag(tagName)

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
            todoMode: pageStack.currentItem && pageStack.currentItem.objectName === "todoView"
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

            readonly property bool show: header.todoMode || header.filter.tags.length > 0 || notifyMessage.visible
            readonly property alias messageItem: notifyMessage

            height: show ? headerLayout.implicitHeight + headerSeparator.height : 0
            // Adjust for margins
            clip: height === 0

            Behavior on height { NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            } }

            Rectangle {
                width: headerLayout.width
                height: headerLayout.height
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                color: Kirigami.Theme.backgroundColor
            }

            ColumnLayout {
                id: headerLayout
                anchors.fill: parent
                clip: true

                Kirigami.InlineMessage {
                    id: notifyMessage
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing
                    showCloseButton: true
                    visible: false
                }

                FilterHeader {
                    id: header
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    todoMode: pageStack.currentItem ? pageStack.currentItem.objectName === "todoView" : false
                    filter: root.filter ?
                        root.filter : {"tags": [], "collectionId": -1}
                    isDark: root.isDark
                    visible: todoMode || filter.tags.length > 0
                    clip: true

                    onRemoveFilterTag: {
                        root.filter.tags.splice(root.filter.tags.indexOf(tagName), 1);
                        root.filterChanged();
                    }
                    onResetFilterCollection: {
                        root.filter.collectionId = -1;
                        root.filterChanged();
                    }
                }
            }
            Kirigami.Separator {
                id: headerSeparator
                anchors.top: headerLayout.bottom
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

    FileDialog {
        id: importFileDialog

        property string selectedUrl: ""

        title: i18n("Import a calendar")
        folder: shortcuts.home
        nameFilters: ["Calendar files (*.ics *.vcs)"]
        onAccepted: {
            selectedUrl = fileUrl;
            const openDialogWindow = pageStack.pushDialogLayer(importChoicePageComponent, {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 8
            });

            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }
    }

    Component {
        id: importChoicePageComponent
        Kirigami.Page {
            id: importChoicePage
            title: i18n("Import Calendar")
            signal closed()

            ColumnLayout {
                anchors.fill: parent
                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: i18n("Would you like to merge this calendar file's events and tasks into one of your existing calendars, or would prefer to create a new calendar from this file?\n ")
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    QQC2.Button {
                        Layout.fillWidth: true
                        icon.name: "document-import"
                        text: i18n("Merge with existing calendar")
                        onClicked: {
                            closeDialog();
                            const openDialogWindow = pageStack.pushDialogLayer(importMergeCollectionPickerComponent, {
                                width: root.width
                            }, {
                                width: Kirigami.Units.gridUnit * 30,
                                height: Kirigami.Units.gridUnit * 30
                            });

                            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
                        }
                    }
                    QQC2.Button {
                        Layout.fillWidth: true
                        icon.name: "document-new"
                        text: i18n("Create new calendar")
                        onClicked: {
                            root.calendarImportInProgress = false;
                            KalendarApplication.importCalendarFromUrl(importFileDialog.selectedUrl, false);
                            closeDialog();
                        }
                    }
                    QQC2.Button {
                        icon.name: "gtk-cancel"
                        text: i18n("Cancel")
                        onClicked: {
                            root.calendarImportInProgress = false;
                            closeDialog();
                        }
                    }
                }
            }
        }
    }

    Component {
        id: importMergeCollectionPickerComponent
        CollectionPickerPage {
            onCollectionPicked: {
                KalendarApplication.importCalendarFromUrl(importFileDialog.selectedUrl, true, collectionId);
                root.calendarImportInProgress = false;
                closeDialog();
            }
            onCancel: {
                root.calendarImportInProgress = false;
                closeDialog()
            }
        }
    }

    function toggleFilterTag(tagName) {
        if(!root.filter || !root.filter.tags || !root.filter.tags.includes(tagName)) {
            root.filter ? root.filter.tags ?
                root.filter.tags.push(tagName) :
                root.filter.tags = [tagName] :
                root.filter = {"tags" : [tagName]};
            root.filterChanged();
            filterHeader.active = true;
            pageStack.currentItem.header = filterHeader.item;
        } else if (root.filter.tags.includes(tagName)) {
            root.filter.tags = root.filter.tags.filter((tag) => tag !== tagName);
            root.filterChanged();
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

    function setUpView(modelData) {
        incidenceInfo.incidenceData = modelData;
        incidenceInfo.open();
    }

    function setUpEdit(incidencePtr) {
        let editorToUse = root.editorToUse();
        editorToUse.incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}',
            editorToUse, "incidence");
        editorToUse.incidenceWrapper.incidenceItem = CalendarManager.incidenceItem(incidencePtr);
        editorToUse.incidenceWrapper.triggerEditMode();
        editorToUse.editMode = true;
    }

    function setUpDelete(incidencePtr, deleteDate) {
        let incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', root, "incidence");
        incidenceWrapper.incidenceItem = CalendarManager.incidenceItem(incidencePtr);

        const openDialogWindow = pageStack.pushDialogLayer(deleteIncidenceSheetComponent, {
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
            this, "incidence");

        todo.incidenceItem = CalendarManager.incidenceItem(incidencePtr);

        if(todo.incidenceType === IncidenceWrapper.TypeTodo) {
            todo.todoCompleted = !todo.todoCompleted;
            CalendarManager.editIncidence(todo);
        }
    }

    function setUpIncidenceDateChange(incidenceWrapper, startOffset, endOffset, occurrenceDate, caughtDelegate) {
        pageStack.currentItem.dragDropEnabled = false;

        if(pageStack.layers.currentItem && pageStack.layers.currentItem.dragDropEnabled) {
            pageStack.layers.currentItem.dragDropEnabled = false;
        }

        if(incidenceWrapper.recurrenceData.type === 0) {
            CalendarManager.updateIncidenceDates(incidenceWrapper, startOffset, endOffset);
        } else {
            const onClosingHandler = () => { caughtDelegate.caught = false; root.reenableDragOnCurrentView(); };
            const openDialogWindow = pageStack.pushDialogLayer(recurringIncidenceChangeSheetComponent, {
                incidenceWrapper: incidenceWrapper,
                startOffset: startOffset,
                endOffset: endOffset,
                occurrenceDate: occurrenceDate,
                caughtDelegate: caughtDelegate
            }, {
                width: Kirigami.Units.gridUnit * 34,
                height: Kirigami.Units.gridUnit * 6,
                onClosing: onClosingHandler()
            });

            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }
    }

    function reenableDragOnCurrentView() {
        pageStack.currentItem.dragDropEnabled = true;

        if(pageStack.layers.currentItem && pageStack.layers.currentItem.dragDropEnabled) {
            pageStack.layers.currentItem.dragDropEnabled = true;
        }
    }

    Connections {
        target: CalendarManager
        function onUpdateIncidenceDatesCompleted() { root.reenableDragOnCurrentView(); }
    }

    Component {
        id: deleteIncidenceSheetComponent
        DeleteIncidenceSheet {
            id: deleteIncidenceSheet

            onAddException: {
                if(incidenceInfo.incidenceWrapper && incidenceInfo.incidenceWrapper.incidenceId == deleteIncidenceSheet.incidenceWrapper.incidenceId &&
                    DateUtils.sameDay(incidenceInfo.incidenceData.startTime, exceptionDate)) {

                    incidenceInfo.incidenceData = undefined;
                    root.openOccurrence = undefined;
                }

                incidenceWrapper.recurrenceExceptionsModel.addExceptionDateTime(exceptionDate);
                CalendarManager.editIncidence(incidenceWrapper);
                closeDialog();
            }
            onAddRecurrenceEndDate: {
                // If occurrence is past the new recurrence end date, it has ben deleted so kill instance in incidence info
                if(incidenceInfo.incidenceWrapper && incidenceInfo.incidenceWrapper.incidenceId == deleteIncidenceSheet.incidenceWrapper.incidenceId &&
                    incidenceInfo.incidenceData.startTime >= endDate) {

                    incidenceInfo.incidenceData = undefined;
                    root.openOccurrence = undefined;
                }
                incidenceWrapper.setRecurrenceDataItem("endDateTime", endDate);
                CalendarManager.editIncidence(incidenceWrapper);
                closeDialog();
            }
            onDeleteIncidence: {
                // Deleting an incidence also means deleting all of its occurrences
                if(incidenceInfo.incidenceWrapper && incidenceInfo.incidenceWrapper.incidenceId == deleteIncidenceSheet.incidenceWrapper.incidenceId) {

                    incidenceInfo.incidenceData = undefined;
                    root.openOccurrence = undefined;
                }
                CalendarManager.deleteIncidence(incidencePtr);
                closeDialog();
            }
            onDeleteIncidenceWithChildren: {
                // TODO: Check if parent deleted too
                if(incidenceInfo.incidenceWrapper && incidenceInfo.incidenceWrapper.incidenceId == deleteIncidenceSheet.incidenceWrapper.incidenceId) {

                    incidenceInfo.incidenceData = undefined;
                    root.openOccurrence = undefined;
                }

                CalendarManager.deleteIncidence(incidencePtr, true);
                closeDialog();
            }
            onCancel: closeDialog()
        }
    }

    Component {
        id: deleteCalendarSheetComponent
        DeleteCalendarSheet {
            id: deleteCalendarSheet

            onDeleteCollection: {
                CalendarManager.deleteCollection(collectionId);
                closeDialog();
            }
            onCancel: closeDialog()
        }
    }

    Component {
        id: recurringIncidenceChangeSheetComponent
        RecurringIncidenceChangeSheet {
            id: recurringIncidenceChangeSheet

            onChangeAll: {
                CalendarManager.updateIncidenceDates(incidenceWrapper, startOffset, endOffset, IncidenceWrapper.AllOccurrences);
                closeDialog();
            }
            onChangeThis: {
                CalendarManager.updateIncidenceDates(incidenceWrapper, startOffset, endOffset, IncidenceWrapper.SelectedOccurrence, occurrenceDate);
                closeDialog();
            }
            onChangeThisAndFuture: {
                CalendarManager.updateIncidenceDates(incidenceWrapper, startOffset, endOffset, IncidenceWrapper.FutureOccurrences, occurrenceDate);
                closeDialog();
            }
            onCancel: {
                caughtDelegate.caught = false;
                root.reenableDragOnCurrentView();
                closeDialog();
            }
        }
    }

    Loader {
        id: monthScaleModelLoader
        active: Config.lastOpenedView === Config.MonthView || Config.lastOpenedView === Config.ScheduleView
        onStatusChanged: if(status === Loader.Ready) asynchronous = true
        sourceComponent: InfiniteCalendarViewModel {
            scale: InfiniteCalendarViewModel.MonthScale
            calendar: CalendarManager.calendar
            filter: root.filter
        }
    }

    Loader {
        id: weekScaleModelLoader
        active: Config.lastOpenedView === Config.WeekView
        onStatusChanged: if(status === Loader.Ready) asynchronous = true
        sourceComponent: InfiniteCalendarViewModel {
            scale: InfiniteCalendarViewModel.WeekScale
            calendar: CalendarManager.calendar
            filter: root.filter
        }
    }

    Loader {
        id: threeDayScaleModelLoader
        active: Config.lastOpenedView === Config.ThreeDayView
        onStatusChanged: if(status === Loader.Ready) asynchronous = true
        sourceComponent: InfiniteCalendarViewModel {
            scale: InfiniteCalendarViewModel.ThreeDayScale
            calendar: CalendarManager.calendar
            filter: root.filter
        }
    }

    Loader {
        id: dayScaleModelLoader
        active: Config.lastOpenedView === Config.DayView
        onStatusChanged: if(status === Loader.Ready) asynchronous = true
        sourceComponent: InfiniteCalendarViewModel {
            scale: InfiniteCalendarViewModel.DayScale
            calendar: CalendarManager.calendar
            filter: root.filter
        }
    }

    Component {
        id: monthViewComponent

        MonthView {
            id: monthView
            objectName: "monthView"

            titleDelegate: ViewTitleDelegate {
                titleDateButton.date: monthView.firstDayOfMonth
                titleDateButton.onClicked: dateChangeDrawer.visible = !dateChangeDrawer.visible
            }
            currentDate: root.currentDate
            openOccurrence: root.openOccurrence
            model: monthScaleModelLoader.item

            onAddIncidence: root.setUpAdd(type, addDate)
            onViewIncidence: root.setUpView(modelData)
            onEditIncidence: root.setUpEdit(incidencePtr)
            onDeleteIncidence: root.setUpDelete(incidencePtr, deleteDate)
            onCompleteTodo: root.completeTodo(incidencePtr)
            onAddSubTodo: root.setUpAddSubTodo(parentWrapper)
            onDeselect: incidenceInfo.close()
            onMoveIncidence: root.setUpIncidenceDateChange(incidenceWrapper, startOffset, startOffset, occurrenceDate, caughtDelegate)

            onMonthChanged: if(month !== root.selectedDate.getMonth() && !initialMonth) root.selectedDate = new Date (year, month, 1)
            onYearChanged: if(year !== root.selectedDate.getFullYear() && !initialMonth) root.selectedDate = new Date (year, month, 1)

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
                titleDateButton.onClicked: dateChangeDrawer.visible = !dateChangeDrawer.visible
            }
            selectedDate: root.selectedDate
            openOccurrence: root.openOccurrence
            model: monthScaleModelLoader.item

            onDayChanged: if(day !== root.selectedDate.getDate() && !initialMonth) root.selectedDate = new Date (year, month, day)
            onMonthChanged: if(month !== root.selectedDate.getMonth() && !initialMonth) root.selectedDate = new Date (year, month, day)
            onYearChanged: if(year !== root.selectedDate.getFullYear() && !initialMonth) root.selectedDate = new Date (year, month, day)

            onAddIncidence: root.setUpAdd(type, addDate)
            onViewIncidence: root.setUpView(modelData)
            onEditIncidence: root.setUpEdit(incidencePtr)
            onDeleteIncidence: root.setUpDelete(incidencePtr, deleteDate)
            onCompleteTodo: root.completeTodo(incidencePtr)
            onAddSubTodo: root.setUpAddSubTodo(parentWrapper)
            onDeselect: incidenceInfo.close()
            onMoveIncidence: root.setUpIncidenceDateChange(incidenceWrapper, startOffset, startOffset, occurrenceDate, caughtDelegate)

            actions.contextualActions: createAction
        }
    }

    Component {
        id: hourlyViewComponent

        HourlyView {
            id: hourlyView
            objectName: switch(daysToShow) {
                case 1:
                    return "dayView";
                case 3:
                    return "threeDayView";
                case 7:
                default:
                    return "weekView";
            }

            titleDelegate: ViewTitleDelegate {
                titleDateButton.range: true
                titleDateButton.date: hourlyView.startDate
                titleDateButton.lastDate: DateUtils.addDaysToDate(hourlyView.startDate, hourlyView.daysToShow - 1)
                titleDateButton.onClicked: dateChangeDrawer.visible = !dateChangeDrawer.visible
            }
            selectedDate: root.selectedDate
            currentDate: root.currentDate
            openOccurrence: root.openOccurrence
            model: switch(daysToShow) {
                case 1:
                    return dayScaleModelLoader.item;
                case 3:
                    return threeDayScaleModelLoader.item;
                case 7:
                default:
                    return weekScaleModelLoader.item;
            }
            onModelChanged: setToDate(root.selectedDate, true)

            onDayChanged: if(day !== root.selectedDate.getDate() && !initialWeek) root.selectedDate = new Date (year, month, day)
            onMonthChanged: if(month !== root.selectedDate.getMonth() && !initialWeek) root.selectedDate = new Date (year, month, day)
            onYearChanged: if(year !== root.selectedDate.getFullYear() && !initialWeek) root.selectedDate = new Date (year, month, day)

            onAddIncidence: root.setUpAdd(type, addDate, null, includeTime)
            onViewIncidence: root.setUpView(modelData)
            onEditIncidence: root.setUpEdit(incidencePtr)
            onDeleteIncidence: root.setUpDelete(incidencePtr, deleteDate)
            onCompleteTodo: root.completeTodo(incidencePtr)
            onAddSubTodo: root.setUpAddSubTodo(parentWrapper)
            onDeselect: incidenceInfo.close()
            onMoveIncidence: root.setUpIncidenceDateChange(incidenceWrapper, startOffset, startOffset, occurrenceDate, caughtDelegate) // We move the entire incidence
            onResizeIncidence: root.setUpIncidenceDateChange(incidenceWrapper, 0, endOffset, occurrenceDate, caughtDelegate)

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
                        if(sidebar.collapsed && !wideScreen) { // Collapsed due to narrow window
                            // We don't want to write to config as when narrow the button will only open the modal drawer
                            sidebar.collapsed = !sidebar.collapsed;
                        } else {
                            Config.forceCollapsedSidebar = !Config.forceCollapsedSidebar;
                            Config.save()
                        }
                    }

                    QQC2.ToolTip.text: sidebar.collapsed ? i18n("Expand Sidebar") : i18n("Collapse Sidebar")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
                Kirigami.Heading {
                    text: i18n("Tasks")
                }
            }

            filter: if(root.filter) root.filter

            onAddTodo: root.setUpAdd(IncidenceWrapper.TypeTodo, new Date(), collectionId)
            onViewTodo: root.setUpView(todoData)
            onEditTodo: root.setUpEdit(todoPtr)
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
