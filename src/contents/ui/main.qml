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
import org.kde.kalendar.contact 1.0
import org.kde.kalendar.utils 1.0

Kirigami.ApplicationWindow {
    id: root

    width: Kirigami.Units.gridUnit * 65

    minimumWidth: Kirigami.Units.gridUnit * 25
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
    onFilterChanged: if(pageStack.currentItem.mode === KalendarApplication.Todo) {
        pageStack.currentItem.filter = filter
    }

    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    readonly property var monthViewAction: KalendarApplication.action("open_month_view")
    readonly property var weekViewAction: KalendarApplication.action("open_week_view")
    readonly property var threeDayViewAction: KalendarApplication.action("open_threeday_view")
    readonly property var dayViewAction: KalendarApplication.action("open_day_view")
    readonly property var scheduleViewAction: KalendarApplication.action("open_schedule_view")
    readonly property var contactViewAction: KalendarApplication.action("open_contact_view")
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
    readonly property var refreshAllAction: KalendarApplication.action("refresh_all")

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

    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.ToolBar
    pageStack.initialPage: scheduleViewComponent

    property bool ignoreCurrentPage: true // HACK: ideally we just push an empty page here and save ourselves the trouble,
    // but we have had issues with pushing empty Kirigami pages somehow causing mobile controls to show up on desktop.
    // We use this property to temporarily allow a view to be replaced by a view of the same type

    Component.onCompleted: {
        KalendarUiUtils.appMain = root; // Most of our util functions use things defined here in main
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
            case Config.ContactView:
                contactViewAction.trigger();
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
                KalendarUiUtils.setUpDelete(incidenceInfoDrawer.incidenceData.incidencePtr, incidenceInfoDrawer.incidenceData.startTime);
            }
        }
    }

    KBMNavigationMouseArea { anchors.fill: parent }

    Connections {
        target: KalendarApplication
        function onOpenMonthView() {
            if(pageStack.currentItem.objectName !== "monthView" || root.ignoreCurrentPage) {
                monthScaleModelLoader.active = true;
                KalendarUiUtils.switchView(monthViewComponent);
            }
        }

        function onOpenWeekView() {
            if(pageStack.currentItem.objectName !== "weekView" || root.ignoreCurrentPage) {
                weekScaleModelLoader.active = true;
                KalendarUiUtils.switchView(hourlyViewComponent);
            }
        }

        function onOpenThreeDayView() {
            if(pageStack.currentItem.objectName !== "threeDayView" || root.ignoreCurrentPage) {
                threeDayScaleModelLoader.active = true;
                KalendarUiUtils.switchView(hourlyViewComponent, { daysToShow: 3 });
            }
        }

        function onOpenDayView() {
            if(pageStack.currentItem.objectName !== "dayView" || root.ignoreCurrentPage) {
                dayScaleModelLoader.active = true;
                KalendarUiUtils.switchView(hourlyViewComponent, { daysToShow: 1 });
            }
        }

        function onOpenScheduleView() {
            if(pageStack.currentItem.objectName !== "scheduleView" || root.ignoreCurrentPage) {
                monthScaleModelLoader.active = true;
                KalendarUiUtils.switchView(scheduleViewComponent);
            }
        }

        function onOpenContactView() {
            if(pageStack.currentItem.objectName !== "contactView" || root.ignoreCurrentPage) {
                KalendarUiUtils.switchView("qrc:/LazyContactView.qml");
            }
        }

        function onOpenTodoView() {
            if(pageStack.currentItem.objectName !== "todoView") {
                filterHeaderBar.active = true;
                KalendarUiUtils.switchView(todoViewComponent);
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
            dateChangeDrawer.active = true;
        }

        function onOpenAboutPage() {
            pageStack.layers.push("AboutPage.qml")
        }

        function onToggleMenubar() {
            Config.showMenubar = !Config.showMenubar;
            Config.save();
        }

        function onCreateNewEvent() {
            KalendarUiUtils.setUpAdd(IncidenceWrapper.TypeEvent);
        }

        function onCreateNewTodo() {
            KalendarUiUtils.setUpAdd(IncidenceWrapper.TypeTodo);
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
            filterHeaderBar.active = true;
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
            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }

        function onImportIntoExistingFinished(success, total) {
            filterHeaderBar.active = true;
            pageStack.currentItem.header = filterHeaderBar.item;

            if(success) {
                filterHeaderBar.item.messageItem.type = Kirigami.MessageType.Positive;
                filterHeaderBar.item.messageItem.text = i18nc("%1 is a number", "%1 incidences were imported successfully.", total);
            } else {
                filterHeaderBar.item.messageItem.type = Kirigami.MessageType.Error;
                filterHeaderBar.item.messageItem.text = i18nc("%1 is the error message", "An error occurred importing incidences: %1", KalendarApplication.importErrorMessage);
            }

            filterHeaderBar.item.messageItem.visible = true;
        }

        function onImportIntoNewFinished(success) {
            filterHeaderBar.active = true;
            pageStack.currentItem.header = filterHeaderBar.item;

            if(success) {
                filterHeaderBar.item.messageItem.type = Kirigami.MessageType.Positive;
                filterHeaderBar.item.messageItem.text = i18n("New calendar  created from imported file successfully.");
            } else {
                filterHeaderBar.item.messageItem.type = Kirigami.MessageType.Error;
                filterHeaderBar.item.messageItem.text = i18nc("%1 is the error message", "An error occurred importing incidences: %1", KalendarApplication.importErrorMessage);
            }

            filterHeaderBar.item.messageItem.visible = true;
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

        function onRefreshAll() {
            if (pageStack.currentItem.mode === KalendarApplication.Contact) {
                ContactManager.updateAllCollections();
            } else {
                CalendarManager.updateAllCollections();
            }
        }

        function onOpenIncidence(incidenceData, occurrenceDate) {
            if(pageStack.currentItem.mode === KalendarApplication.Todo && incidenceData.incidenceType !== IncidenceWrapper.TypeTodo) {
                Kirigami.Settings.isMobile ? dayViewAction.trigger() : weekViewAction.trigger();
            }

            KalendarUiUtils.setUpView(incidenceData);

            if(pageStack.currentItem.objectName !== "todoView") {
                pageStack.currentItem.setToDate(occurrenceDate);
            }
        }
    }

    Loader {
        id: kcommandbarLoader
        active: false
        source: 'qrc:/KQuickCommandBarPage.qml'
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
            case "contactView":
                return i18n("Contacts View");
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
            mode: applicationWindow().pageStack.currentItem ? applicationWindow().pageStack.currentItem.mode : KalendarApplication.Event
            Kirigami.Theme.colorSet: Kirigami.Theme.Header
        }
    }

    footer: Loader {
        id: bottomLoader
        active: Kirigami.Settings.isMobile
        visible: pageStack.currentItem && pageStack.currentItem.objectName !== "settingsPage"

        source: Qt.resolvedUrl("qrc:/BottomToolBar.qml")
    }

    globalDrawer: MainDrawer {
        id: mainDrawer
        bottomPadding: menuLoader.active ? menuLoader.height : 0
        mode: pageStack.currentItem ? pageStack.currentItem.mode : KalendarApplication.Event
        activeTags: root.filter && root.filter.tags ?
                    root.filter.tags : []
        onSearchTextChanged: {
            if (mode === KalendarApplication.Contact) {
                ContactManager.filteredContacts.setFilterFixedString(searchText)
                return;
            }
            if(root.filter) {
                root.filter.name = searchText;
            } else {
                root.filter = {name: searchText};
            }
            root.filterChanged();
        }
        onCalendarClicked: if (mode === KalendarApplication.Todo) {
            root.filter ?
                root.filter.collectionId = collectionId :
                root.filter = {"collectionId" : collectionId};
            root.filterChanged();
            pageStack.currentItem.filterCollectionDetails = CalendarManager.getCollectionDetails(collectionId);
        }
        onCalendarCheckChanged: {
            CalendarManager.save();
            if(mode === KalendarApplication.Todo && collectionId === pageStack.currentItem.filterCollectionId) {
                pageStack.currentItem.filterCollectionDetails = CalendarManager.getCollectionDetails(pageStack.currentItem.filterCollectionId);
                // HACK: The Todo View should be able to detect change in collection filtering independently
            }
        }
        onTagClicked: root.toggleFilterTag(tagName)
        onViewAllTodosClicked: if(mode === KalendarApplication.Todo) {
            root.filter.collectionId = -1;
            root.filter.tags = [];
            root.filter.name = "";
            root.filterChanged();
        }
        onDeleteCalendar: {
            const openDialogWindow = pageStack.pushDialogLayer(deleteCalendarPageComponent, {
                collectionId: collectionId,
                collectionDetails: collectionDetails
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 6
            });

            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }
    }

    contextDrawer: IncidenceInfoDrawer {
        id: incidenceInfoDrawer

        bottomPadding: menuLoader.active ? menuLoader.height : 0
        width: actualWidth
        modal: !root.wideScreen || !enabled
        onEnabledChanged: drawerOpen = enabled && !modal
        onModalChanged: drawerOpen = !modal
        enabled: incidenceData != undefined && pageStack.currentItem.mode !== KalendarApplication.Contact
        handleVisible: enabled
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
            KalendarUiUtils.setUpAddSubTodo(parentWrapper);
            if (modal) { incidenceInfoDrawer.close() }
        }
        onEditIncidence: {
            KalendarUiUtils.setUpEdit(incidencePtr);
            if (modal) { incidenceInfoDrawer.close() }
        }
        onDeleteIncidence: {
            KalendarUiUtils.setUpDelete(incidencePtr, deleteDate)
            if (modal) { incidenceInfoDrawer.close() }
        }
        onTagClicked: root.toggleFilterTag(tagName)

        readonly property int minWidth: Kirigami.Units.gridUnit * 15
        readonly property int maxWidth: Kirigami.Units.gridUnit * 25
        readonly property int defaultWidth: Kirigami.Units.gridUnit * 20
        property int actualWidth: {
            if (Config.incidenceInfoDrawerDrawerWidth === -1) {
                return defaultWidth;
            } else {
                return Config.incidenceInfoDrawerDrawerWidth;
            }
        }

        ResizerSeparator {
            anchors.left: if(Qt.application.layoutDirection !== Qt.RightToLeft) parent.left
            anchors.leftMargin: if(Qt.application.layoutDirection !== Qt.RightToLeft) -1 // Cover up the natural separator on the drawer
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: if(Qt.application.layoutDirection === Qt.RightToLeft) parent.right
            anchors.rightMargin: if(Qt.application.layoutDirection === Qt.RightToLeft) -1
            width: 1
            oversizeMouseAreaHorizontal: 5
            z: 500

            function savePos() {
                Config.incidenceInfoDrawerDrawerWidth = incidenceInfoDrawer.actualWidth;
                Config.save();
            }

            onDragBegin: savePos()
            onDragReleased: savePos()

            onDragPositionChanged: {
                if (Qt.application.layoutDirection === Qt.RightToLeft) {
                    incidenceInfoDrawer.actualWidth = Math.min(incidenceInfoDrawer.maxWidth, Math.max(incidenceInfoDrawer.minWidth, Config.incidenceInfoDrawerDrawerWidth + changeX));
                } else {
                    incidenceInfoDrawer.actualWidth = Math.min(incidenceInfoDrawer.maxWidth, Math.max(incidenceInfoDrawer.minWidth, Config.incidenceInfoDrawerDrawerWidth - changeX));
                }
            }
        }
    }

    Loader {
        id: dateChangeDrawer
        active: false
        visible: status === Loader.Ready
        onStatusChanged: if(status === Loader.Ready) item.open()
        sourceComponent: DateChanger {
            y: pageStack.globalToolBar.height - 1
            showDays: pageStack.currentItem && pageStack.currentItem.objectName !== "monthView"
            date: root.selectedDate
            onDateSelected: if(visible) {
                pageStack.currentItem.setToDate(date);
                root.selectedDate = date;
            }
        }
    }

    IncidenceEditorPage {
        id: incidenceEditorPage
        onAdded: CalendarManager.addIncidence(incidenceWrapper)
        onEdited: CalendarManager.editIncidence(incidenceWrapper)
        onCancel: pageStack.layers.pop()
    }

    Loader {
        id: globalMenuLoader
        active: !Kirigami.Settings.isMobile
        sourceComponent: GlobalMenu {
            mode: pageStack.currentItem ? pageStack.currentItem.mode : KalendarApplication.Event
        }
        onLoaded: item.parentWindow = root;
    }

    property alias editorWindowedLoaderItem: editorWindowedLoader
    Loader {
        id: editorWindowedLoader
        active: false
        sourceComponent: Kirigami.ApplicationWindow {
            id: root

            width: Kirigami.Units.gridUnit * 40
            height: Kirigami.Units.gridUnit * 32

            flags: Qt.Dialog | Qt.WindowCloseButtonHint

            // Probably a more elegant way of accessing the editor from outside than this.
            property var incidenceEditorPage: incidenceEditorPageInLoader

            pageStack.initialPage: incidenceEditorPageInLoader

            Loader {
                active: !Kirigami.Settings.isMobile
                source: Qt.resolvedUrl("qrc:/GlobalMenu.qml")
                onLoaded: item.parentWindow = root
            }

            IncidenceEditorPage {
                id: incidenceEditorPageInLoader
                onAdded: CalendarManager.addIncidence(incidenceWrapper)
                onEdited: CalendarManager.editIncidence(incidenceWrapper)
                onCancel: root.close()
                Keys.onEscapePressed: root.close()
            }

            visible: true
            onClosing: editorWindowedLoader.active = false
        }
    }

    property alias filterHeaderBarLoaderItem: filterHeaderBar
    Loader {
        id: filterHeaderBar
        active: false
        sourceComponent: Item {
            readonly property bool show: header.mode === KalendarApplication.Todo ||
                                         header.filter.tags.length > 0 ||
                                         notifyMessage.visible
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

                FilterHeaderBar {
                    id: header
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    mode: pageStack.currentItem ? pageStack.currentItem.mode : KalendarApplication.Event
                    filter: root.filter ?
                        root.filter : {"tags": [], "collectionId": -1, "name": ""}
                    isDark: root.isDark
                    visible: mode === KalendarApplication.Todo || filter.tags.length > 0
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

    property alias importMergeCollectionPickerComponent: importMergeCollectionPickerComponent
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
            filterHeaderBar.active = true;
            pageStack.currentItem.header = filterHeaderBar.item;
        } else if (root.filter.tags.includes(tagName)) {
            root.filter.tags = root.filter.tags.filter((tag) => tag !== tagName);
            root.filterChanged();
        }
    }

    Connections {
        target: CalendarManager
        function onUpdateIncidenceDatesCompleted() { KalendarUiUtils.reenableDragOnCurrentView(); }
    }

    property alias deleteIncidencePageComponent: deleteIncidencePageComponent
    Component {
        id: deleteIncidencePageComponent
        DeleteIncidencePage {
            id: deleteIncidencePage

            onAddException: {
                if(incidenceInfoDrawer.incidenceWrapper && incidenceInfoDrawer.incidenceWrapper.incidenceId == deleteIncidencePage.incidenceWrapper.incidenceId &&
                    DateUtils.sameDay(incidenceInfoDrawer.incidenceData.startTime, exceptionDate)) {

                    incidenceInfoDrawer.incidenceData = undefined;
                    root.openOccurrence = undefined;
                }

                incidenceWrapper.recurrenceExceptionsModel.addExceptionDateTime(exceptionDate);
                CalendarManager.editIncidence(incidenceWrapper);
                closeDialog();
            }
            onAddRecurrenceEndDate: {
                // If occurrence is past the new recurrence end date, it has ben deleted so kill instance in incidence info
                if(incidenceInfoDrawer.incidenceWrapper && incidenceInfoDrawer.incidenceWrapper.incidenceId == deleteIncidencePage.incidenceWrapper.incidenceId &&
                    incidenceInfoDrawer.incidenceData.startTime >= endDate) {

                    incidenceInfoDrawer.incidenceData = undefined;
                    root.openOccurrence = undefined;
                }
                incidenceWrapper.setRecurrenceDataItem("endDateTime", endDate);
                CalendarManager.editIncidence(incidenceWrapper);
                closeDialog();
            }
            onDeleteIncidence: {
                // Deleting an incidence also means deleting all of its occurrences
                if(incidenceInfoDrawer.incidenceWrapper && incidenceInfoDrawer.incidenceWrapper.incidenceId == deleteIncidencePage.incidenceWrapper.incidenceId) {

                    incidenceInfoDrawer.incidenceData = undefined;
                    root.openOccurrence = undefined;
                }
                CalendarManager.deleteIncidence(incidencePtr);
                closeDialog();
            }
            onDeleteIncidenceWithChildren: {
                // TODO: Check if parent deleted too
                if(incidenceInfoDrawer.incidenceWrapper && incidenceInfoDrawer.incidenceWrapper.incidenceId == deleteIncidencePage.incidenceWrapper.incidenceId) {

                    incidenceInfoDrawer.incidenceData = undefined;
                    root.openOccurrence = undefined;
                }

                CalendarManager.deleteIncidence(incidencePtr, true);
                closeDialog();
            }
            onCancel: closeDialog()
        }
    }

    property alias deleteCalendarPageComponent: deleteCalendarPageComponent
    Component {
        id: deleteCalendarPageComponent
        DeleteCalendarPage {
            id: deleteCalendarPage

            onDeleteCollection: {
                CalendarManager.deleteCollection(collectionId);
                closeDialog();
            }
            onCancel: closeDialog()
        }
    }

    property alias recurringIncidenceChangePageComponent: recurringIncidenceChangePageComponent
    Component {
        id: recurringIncidenceChangePageComponent
        RecurringIncidenceChangePage {
            id: recurringIncidenceChangePage

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
                KalendarUiUtils.reenableDragOnCurrentView();
                closeDialog();
            }
        }
    }

    property alias monthScaleModelLoaderItem: monthScaleModelLoader
    Loader {
        id: monthScaleModelLoader
        active: Config.lastOpenedView === Config.MonthView || Config.lastOpenedView === Config.ScheduleView
        sourceComponent: InfiniteCalendarViewModel {
            scale: InfiniteCalendarViewModel.MonthScale
            calendar: CalendarManager.calendar
            filter: root.filter
        }
    }

    property alias weekScaleModelLoaderItem: weekScaleModelLoader
    Loader {
        id: weekScaleModelLoader
        active: Config.lastOpenedView === Config.WeekView
        sourceComponent: InfiniteCalendarViewModel {
            maxLiveModels: 20
            scale: InfiniteCalendarViewModel.WeekScale
            calendar: CalendarManager.calendar
            filter: root.filter
        }
    }

    property alias threeDayScaleModelLoaderItem: threeDayScaleModelLoader
    Loader {
        id: threeDayScaleModelLoader
        active: Config.lastOpenedView === Config.ThreeDayView
        sourceComponent: InfiniteCalendarViewModel {
            scale: InfiniteCalendarViewModel.ThreeDayScale
            calendar: CalendarManager.calendar
            filter: root.filter
        }
    }

    property alias dayScaleModelLoaderItem: dayScaleModelLoader
    Loader {
        id: dayScaleModelLoader
        active: Config.lastOpenedView === Config.DayView
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
                titleDateButton.onClicked: dateChangeDrawer.active = !dateChangeDrawer.active
            }
            currentDate: root.currentDate
            openOccurrence: root.openOccurrence
            model: monthScaleModelLoader.item

            onAddIncidence: KalendarUiUtils.setUpAdd(type, addDate)
            onViewIncidence: KalendarUiUtils.setUpView(modelData)
            onEditIncidence: KalendarUiUtils.setUpEdit(incidencePtr)
            onDeleteIncidence: KalendarUiUtils.setUpDelete(incidencePtr, deleteDate)
            onCompleteTodo: KalendarUiUtils.completeTodo(incidencePtr)
            onAddSubTodo: KalendarUiUtils.setUpAddSubTodo(parentWrapper)
            onDeselect: incidenceInfoDrawer.close()
            onMoveIncidence: KalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, startOffset, startOffset, occurrenceDate, caughtDelegate)
            onOpenDayView: KalendarUiUtils.openDayLayer(selectedDate)

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
                titleDateButton.onClicked: dateChangeDrawer.active = !dateChangeDrawer.active
            }
            selectedDate: root.selectedDate
            openOccurrence: root.openOccurrence
            model: monthScaleModelLoader.item

            onDayChanged: if(day !== root.selectedDate.getDate() && !initialMonth) root.selectedDate = new Date (year, month, day)
            onMonthChanged: if(month !== root.selectedDate.getMonth() && !initialMonth) root.selectedDate = new Date (year, month, day)
            onYearChanged: if(year !== root.selectedDate.getFullYear() && !initialMonth) root.selectedDate = new Date (year, month, day)

            onAddIncidence: KalendarUiUtils.setUpAdd(type, addDate)
            onViewIncidence: KalendarUiUtils.setUpView(modelData)
            onEditIncidence: KalendarUiUtils.setUpEdit(incidencePtr)
            onDeleteIncidence: KalendarUiUtils.setUpDelete(incidencePtr, deleteDate)
            onCompleteTodo: KalendarUiUtils.completeTodo(incidencePtr)
            onAddSubTodo: KalendarUiUtils.setUpAddSubTodo(parentWrapper)
            onDeselect: incidenceInfoDrawer.close()
            onMoveIncidence: KalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, startOffset, startOffset, occurrenceDate, caughtDelegate)
            onOpenDayView: KalendarUiUtils.openDayLayer(selectedDate)

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
                titleDateButton.onClicked: dateChangeDrawer.active = !dateChangeDrawer.active

                Kirigami.ActionToolBar {
                    id: weekViewScaleToggles
                    Layout.preferredWidth: weekViewScaleToggles.maximumContentWidth
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    visible: !Kirigami.Settings.isMobile

                    actions: [
                        Kirigami.Action {
                            text: "Week"
                            checkable: true
                            checked: pageStack.currentItem && pageStack.currentItem.objectName == "weekView"
                            onTriggered: weekViewAction.trigger()
                        },
                        Kirigami.Action {
                            text: "3 Days"
                            checkable: true
                            checked: pageStack.currentItem && pageStack.currentItem.objectName == "threeDayView"
                            onTriggered: threeDayViewAction.trigger()
                        },
                        Kirigami.Action {
                            text: "Day"
                            checkable: true
                            checked: pageStack.currentItem && pageStack.currentItem.objectName == "dayView"
                            onTriggered: dayViewAction.trigger()
                        }
                    ]
                }
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

            onAddIncidence: KalendarUiUtils.setUpAdd(type, addDate, null, includeTime)
            onViewIncidence: KalendarUiUtils.setUpView(modelData)
            onEditIncidence: KalendarUiUtils.setUpEdit(incidencePtr)
            onDeleteIncidence: KalendarUiUtils.setUpDelete(incidencePtr, deleteDate)
            onCompleteTodo: KalendarUiUtils.completeTodo(incidencePtr)
            onAddSubTodo: KalendarUiUtils.setUpAddSubTodo(parentWrapper)
            onDeselect: incidenceInfoDrawer.close()
            onMoveIncidence: KalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, startOffset, startOffset, occurrenceDate, caughtDelegate) // We move the entire incidence
            onConvertIncidence: KalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, startOffset, endOffset, occurrenceDate, caughtDelegate, allDay) // We convert incidence from/to allDay
            onResizeIncidence: KalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, 0, endOffset, occurrenceDate, caughtDelegate)
            onOpenDayView: KalendarUiUtils.openDayLayer(selectedDate)

            actions.contextualActions: createAction
        }
    }

    Component {
        id: todoViewComponent

        TodoView {
            id: todoView
            objectName: "todoView"

            titleDelegate: RowLayout {
                spacing: 0
                QQC2.ToolButton {
                    visible: !Kirigami.Settings.isMobile
                    icon.name: mainDrawer.collapsed ? "sidebar-expand" : "sidebar-collapse"
                    onClicked: {
                        if(mainDrawer.collapsed && !wideScreen) { // Collapsed due to narrow window
                            // We don't want to write to config as when narrow the button will only open the modal drawer
                            mainDrawer.collapsed = !mainDrawer.collapsed;
                        } else {
                            Config.forceCollapsedMainDrawer = !Config.forceCollapsedMainDrawer;
                            Config.save()
                        }
                    }

                    QQC2.ToolTip.text: mainDrawer.collapsed ? i18n("Expand MainDrawer") : i18n("Collapse MainDrawer")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
                Kirigami.Heading {
                    text: i18n("Tasks")
                }
            }

            filter: root.filter

            onAddTodo: KalendarUiUtils.setUpAdd(IncidenceWrapper.TypeTodo, new Date(), collectionId)
            onViewTodo: KalendarUiUtils.setUpView(todoData)
            onEditTodo: KalendarUiUtils.setUpEdit(todoPtr)
            onDeleteTodo: KalendarUiUtils.setUpDelete(todoPtr, deleteDate)
            onCompleteTodo: KalendarUiUtils.completeTodo(todoPtr)
            onAddSubTodo: KalendarUiUtils.setUpAddSubTodo(parentWrapper)
            onDeselect: incidenceInfoDrawer.close()
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
