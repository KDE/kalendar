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
import org.kde.kalendar.mail 1.0
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

    readonly property var monthViewAction: KalendarApplication.action("open_month_view")
    readonly property var weekViewAction: KalendarApplication.action("open_week_view")
    readonly property var threeDayViewAction: KalendarApplication.action("open_threeday_view")
    readonly property var dayViewAction: KalendarApplication.action("open_day_view")
    readonly property var scheduleViewAction: KalendarApplication.action("open_schedule_view")
    readonly property var contactViewAction: KalendarApplication.action("open_contact_view")
    readonly property var todoViewAction: KalendarApplication.action("open_todo_view")
    readonly property var mailViewAction: KalendarApplication.action("open_mail_view")
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

        if (Config.lastOpenedView === -1) {
            Kirigami.Settings.isMobile ? scheduleViewAction.trigger() : monthViewAction.trigger();
            return;
        }

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
            case Config.MailView:
                mailViewAction.trigger();
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
            if(contextDrawer && contextDrawer.visible) {
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
                KalendarUiUtils.setUpDelete(root.openOccurrence.incidencePtr,
                                            root.openOccurrence.startTime);
            }
        }
    }

    KBMNavigationMouseArea {
        id: kbmNavigationMouseArea
        anchors.fill: parent
    }

    Connections {
        target: KalendarApplication
        function onOpenMonthView() {
            if(pageStack.currentItem.mode !== KalendarApplication.Month || root.ignoreCurrentPage) {
                KalendarUiUtils.switchView(monthViewComponent);
            }
        }

        function onOpenWeekView() {
            if(pageStack.currentItem.mode !== KalendarApplication.Week || root.ignoreCurrentPage) {
                KalendarUiUtils.switchView(hourlyViewComponent);
            }
        }

        function onOpenThreeDayView() {
            if(pageStack.currentItem.mode !== KalendarApplication.ThreeDay || root.ignoreCurrentPage) {
                KalendarUiUtils.switchView(hourlyViewComponent, { daysToShow: 3 });
            }
        }

        function onOpenDayView() {
            if(pageStack.currentItem.mode !== KalendarApplication.Day || root.ignoreCurrentPage) {
                KalendarUiUtils.switchView(hourlyViewComponent, { daysToShow: 1 });
            }
        }

        function onOpenScheduleView() {
            if(pageStack.currentItem.mode !== KalendarApplication.Schedule || root.ignoreCurrentPage) {
                KalendarUiUtils.switchView(scheduleViewComponent);
            }
        }

        function onOpenContactView() {
            if(pageStack.currentItem.mode !== KalendarApplication.Contact || root.ignoreCurrentPage) {
                KalendarUiUtils.switchView("qrc:/LazyContactView.qml");
            }
        }

        function onOpenMailView() {
            if(pageStack.currentItem.mode !== KalendarApplication.Mail || root.ignoreCurrentPage) {
                KalendarUiUtils.switchView("qrc:/LazyMailView.qml");
            }
        }

        function onOpenTodoView() {
            if(pageStack.currentItem.mode !== KalendarApplication.Todo) {
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
            // Switch to an event view if the current view is not compatible with the current incidence type
            if (pageStack.currentItem.mode & (KalendarApplication.Todo | KalendarApplication.Event) ||
                (pageStack.currentItem.mode === KalendarApplication.Todo && incidenceData.incidenceType !== IncidenceWrapper.TypeTodo)) {

                Kirigami.Settings.isMobile ? dayViewAction.trigger() : weekViewAction.trigger();
            }

            KalendarUiUtils.setUpView(incidenceData);

            if (pageStack.currentItem.mode !== KalendarApplication.Todo) {
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
        switch (pageStack.currentItem.mode) {
            case KalendarApplication.Month:
                return i18n("Month");
                break;
            case KalendarApplication.Week:
                return i18n("Week");
                break;
            case KalendarApplication.ThreeDay:
                return i18n("3 Days");
                break;
            case KalendarApplication.Day:
                return i18n("Day");
                break;
            case KalendarApplication.Schedule:
                return i18n("Schedule");
                break;
            case KalendarApplication.Todo:
                return i18n("Tasks");
                break;
            case KalendarApplication.Contact:
                return i18n("Contacts");
                break;
            case KalendarApplication.Mail:
                return i18n("Mail");
                break;
            default:
                // Should not happen
                return 'Kalendar';
        }
    } else {
        return 'Kalendar';
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
        mode: pageStack.currentItem ? pageStack.currentItem.mode : KalendarApplication.Event

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

    contextDrawer: incidenceInfoDrawerEnabled ? incidenceInfoDrawer : null

    readonly property var incidenceInfoViewer: incidenceInfoDrawerEnabled ? incidenceInfoDrawer :
        incidenceInfoPopupEnabled ? incidenceInfoPopup :
        null

    property bool incidenceInfoDrawerEnabled: Kirigami.Settings.isMobile || !Config.useIncidenceInfoPopup
    readonly property alias incidenceInfoDrawer: incidenceInfoDrawerLoader.item
    Loader {
        id: incidenceInfoDrawerLoader
        active: root.incidenceInfoDrawerEnabled
        sourceComponent: IncidenceInfoDrawer {
            id: incidenceInfoDrawer

            readonly property int minWidth: Kirigami.Units.gridUnit * 15
            readonly property int maxWidth: Kirigami.Units.gridUnit * 25
            readonly property int defaultWidth: Kirigami.Units.gridUnit * 20
            property int actualWidth: {
                if (Config.incidenceInfoDrawerDrawerWidth && Config.incidenceInfoDrawerDrawerWidth === -1) {
                    return defaultWidth;
                } else {
                    return Config.incidenceInfoDrawerDrawerWidth;
                }
            }

            width: Kirigami.Settings.isMobile ? parent.width : actualWidth
            height: Kirigami.Settings.isMobile ? applicationWindow().height * 0.6 : parent.height
            bottomPadding: menuLoader.active ? menuLoader.height : 0

            modal: !root.wideScreen || !enabled
            onEnabledChanged: drawerOpen = enabled && !modal
            onModalChanged: drawerOpen = !modal
            enabled: incidenceData != undefined && pageStack.currentItem.mode !== KalendarApplication.Contact
            handleVisible: enabled
            interactive: Kirigami.Settings.isMobile // Otherwise get weird bug where drawer gets dragged around despite no click

            onIncidenceDataChanged: root.openOccurrence = incidenceData;
            onVisibleChanged: visible ? root.openOccurrence = incidenceData : root.openOccurrence = null

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
    }

    property bool incidenceInfoPopupEnabled: !Kirigami.Settings.isMobile && Config.useIncidenceInfoPopup
    readonly property alias incidenceInfoPopup: incidenceInfoPopupLoader.item
    Loader {
        id: incidenceInfoPopupLoader
        active: incidenceInfoPopupEnabled
        sourceComponent: IncidenceInfoPopup {
            id: incidenceInfoPopup

            // HACK: This is called on mouse events by the KBMNavigationMouseArea in root
            // so that we can react to scrolling in the different views, as there is no
            // way to track the assigned incidence item delegate in a global sense.
            // Remember that when a delegate is scrolled within a scroll view, the
            // delegate's own relative x and y values do not change
            function reposition() {
                calculatePositionTimer.start();
            }

            function calculateIncidenceItemPosition() {
                if (!openingIncidenceItem) {
                    console.log("Can't calculate incidence item position for popup, no opening incidence item is set");
                    close();
                    return;
                }

                // We need to compensate for the x and y local adjustments used, for instance,
                // in the day grid view to position the incidence item delegates
                incidenceItemPosition = openingIncidenceItem.mapToItem(root.pageStack.currentItem,
                                                                       openingIncidenceItem.x,
                                                                       openingIncidenceItem.y);
                incidenceItemPosition.x -= openingIncidenceItem.x;
                incidenceItemPosition.y -= openingIncidenceItem.y;
            }

            property Item openingIncidenceItem: null
            onOpeningIncidenceItemChanged: reposition()

            property point incidenceItemPosition
            property point clickPosition
            property int incidenceItemMidXPoint: incidenceItemPosition && openingIncidenceItem ?
                incidenceItemPosition.x + openingIncidenceItem.width / 2 : 0
            property bool positionBelowIncidenceItem: incidenceItemPosition &&
                incidenceItemPosition.y < root.pageStack.currentItem.height / 2;
            property bool positionAtIncidenceItemCenter: openingIncidenceItem &&
                openingIncidenceItem.width < width
            property int maxXPosition: root.pageStack.currentItem.width - width

            // HACK:
            // If we reposition immediately we often end up updating the position of the popup
            // before the assigned delegate has finished changing position itself. Even with
            // this tiny interval, we avoid the problem and 2ms is not enough to be noticeable
            Timer {
                id: calculatePositionTimer
                interval: 2
                onTriggered: incidenceInfoPopup.calculateIncidenceItemPosition()
            }

            Connections {
                target: incidenceInfoPopup.openingIncidenceItem
                function onXChanged() { incidenceInfoPopup.reposition(); }
                function onYChanged() { incidenceInfoPopup.reposition(); }
                function onWidthChanged() { incidenceInfoPopup.reposition(); }
                function onHeightChanged() { incidenceInfoPopup.reposition(); }
            }

            x: {
                if(positionAtIncidenceItemCenter) {
                    // Center the popup on the incidence item if possible, but also ensure
                    // it is not going further left or right than the left and right edges
                    // of the current view
                    return Math.max(0, Math.min(incidenceItemMidXPoint - width / 2, maxXPosition));

                } else if(openingIncidenceItem) {
                    const itemLeft = mapFromItem(openingIncidenceItem, 0, 0).x;
                    const itemRight = mapFromItem(openingIncidenceItem, openingIncidenceItem.width, 0).x;

                    return Math.max(itemLeft, Math.min(clickPosition.x, itemRight - width));
                }

                return 0;
            }
            // Make sure not to cover up the incidence item
            y: positionBelowIncidenceItem && openingIncidenceItem ? incidenceItemPosition.y + openingIncidenceItem.height : incidenceItemPosition.y - height;

            width: Math.min(pageStack.currentItem.width, Kirigami.Units.gridUnit * 30)
            height: Math.min(Kirigami.Units.gridUnit * 16, implicitHeight)

            onIncidenceDataChanged: root.openOccurrence = incidenceData
            onVisibleChanged: {
                if (visible) {
                    clickPosition = mapFromItem(kbmNavigationMouseArea, kbmNavigationMouseArea.mouseX, 0);
                    root.openOccurrence = incidenceData;
                    reposition();
                } else {
                    root.openOccurrence = null;
                    // Unlike the drawer we are not going to reopen the popup without selecting an incidence
                    incidenceData = null;
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
            showDays: pageStack.currentItem && pageStack.currentItem.mode !== KalendarApplication.MonthView
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
                                         Filter.tags.length > 0 ||
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
                    isDark: KalendarUiUtils.darkMode
                    clip: true
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

    Connections {
        target: CalendarManager
        function onUpdateIncidenceDatesCompleted() { KalendarUiUtils.reenableDragOnCurrentView(); }
    }

    property alias deleteIncidencePageComponent: deleteIncidencePageComponent
    Component {
        id: deleteIncidencePageComponent
        DeleteIncidencePage {
            id: deleteIncidencePage

            function closeOpenIncidenceIfSame() {
                const deletingIncidenceIsOpen = incidenceWrapper &&
                                                root.incidenceInfoViewer &&
                                                root.incidenceInfoViewer.incidenceWrapper &&
                                                root.incidenceInfoViewer.incidenceWrapper.uid === incidenceWrapper.uid;

                if (deletingIncidenceIsOpen) {
                    root.incidenceInfoViewer.incidenceData = undefined;
                    root.openOccurrence = undefined;
                }
            }

            onAddException: {
                if (root.openOccurrence && DateUtils.sameDay(root.openOccurrence.incidenceData.startTime, exceptionDate)) {
                    closeOpenIncidenceIfSame()
                }

                incidenceWrapper.recurrenceExceptionsModel.addExceptionDateTime(exceptionDate);
                CalendarManager.editIncidence(incidenceWrapper);
                closeDialog();
            }
            onAddRecurrenceEndDate: {
                // If occurrence is past the new recurrence end date, it has ben deleted so kill instance in incidence info
                if (root.openOccurrence && root.openOccurrence.startTime >= endDate) {
                    closeOpenIncidenceIfSame();
                }

                incidenceWrapper.setRecurrenceDataItem("endDateTime", endDate);
                CalendarManager.editIncidence(incidenceWrapper);
                closeDialog();
            }
            onDeleteIncidence: {
                // Deleting an incidence also means deleting all of its occurrences
                closeOpenIncidenceIfSame()
                CalendarManager.deleteIncidence(incidencePtr);
                closeDialog();
            }
            onDeleteIncidenceWithChildren: {
                // TODO: Check if parent deleted too
                closeOpenIncidenceIfSame();
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
            currentDate: root.currentDate
            openOccurrence: root.openOccurrence

            onMonthChanged: if(month !== root.selectedDate.getMonth() && !initialMonth) root.selectedDate = new Date (year, month, 1)
            onYearChanged: if(year !== root.selectedDate.getFullYear() && !initialMonth) root.selectedDate = new Date (year, month, 1)

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
                            text: i18nc("@action:inmenu open week view", "Week")
                            checkable: true
                            checked: pageStack.currentItem && pageStack.currentItem.mode === KalendarApplication.Week
                            onTriggered: weekViewAction.trigger()
                        },
                        Kirigami.Action {
                            text: i18nc("@action:inmenu open 3 days view", "3 Days")
                            checkable: true
                            checked: pageStack.currentItem && pageStack.currentItem.mode === KalendarApplication.ThreeDay
                            onTriggered: threeDayViewAction.trigger()
                        },
                        Kirigami.Action {
                            text: i18nc("@action:inmenu open day view", "Day")
                            checkable: true
                            checked: pageStack.currentItem && pageStack.currentItem.mode === KalendarApplication.Day
                            onTriggered: dayViewAction.trigger()
                        }
                    ]
                }
            }
            currentDate: root.currentDate
            openOccurrence: root.openOccurrence

            onDayChanged: if(day !== root.selectedDate.getDate() && !initialWeek) root.selectedDate = new Date (year, month, day)
            onMonthChanged: if(month !== root.selectedDate.getMonth() && !initialWeek) root.selectedDate = new Date (year, month, day)
            onYearChanged: if(year !== root.selectedDate.getFullYear() && !initialWeek) root.selectedDate = new Date (year, month, day)

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
