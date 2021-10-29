// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Kirigami.Page {
    id: root
    property int day: selectedDate.getDate()
    property var filter: {
        "tags": []
    }
    property bool initialMonth: true
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)
    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 30
    property int month: selectedDate.getMonth()
    readonly property Kirigami.Action nextAction: Kirigami.Action {
        displayHint: Kirigami.DisplayHint.IconOnly
        icon.name: "go-next"
        shortcut: "Right"
        text: i18n("Next Month")

        onTriggered: setToDate(DateUtils.addMonthsToDate(pathView.currentItem.firstDayOfMonth, 1))
    }
    property var openOccurrence
    readonly property Kirigami.Action previousAction: Kirigami.Action {
        displayHint: Kirigami.DisplayHint.IconOnly
        icon.name: "go-previous"
        shortcut: "Left"
        text: i18n("Previous Month")

        onTriggered: setToDate(DateUtils.addMonthsToDate(pathView.currentItem.firstDayOfMonth, -1))
    }
    property date selectedDate: new Date()
    property date startDate: DateUtils.getFirstDayOfMonth(selectedDate)
    readonly property Kirigami.Action todayAction: Kirigami.Action {
        icon.name: "go-jump-today"
        text: i18n("Today")

        onTriggered: setToDate(new Date())
    }
    property int year: selectedDate.getFullYear()

    bottomPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing
    padding: 0

    signal addIncidence(int type, date addDate)
    signal addSubTodo(var parentWrapper)
    signal completeTodo(var incidencePtr)
    signal deleteIncidence(var incidencePtr, date deleteDate)
    signal deselect
    signal editIncidence(var incidencePtr, var collectionId)
    function moveToSelected() {
        if (!pathView.currentItem || !pathView.currentItem.item) {
            return;
        }
        if (selectedDate.getDate() > 1) {
            pathView.currentItem.item.scheduleListView.positionViewAtIndex(selectedDate.getDate() - 1, ListView.Beginning);
        } else {
            pathView.currentItem.item.scheduleListView.positionViewAtBeginning();
        }
    }
    function setToDate(date, isInitialMonth = false) {
        root.initialMonth = isInitialMonth;
        let monthDiff = date.getMonth() - pathView.currentItem.firstDayOfMonth.getMonth() + (12 * (date.getFullYear() - pathView.currentItem.firstDayOfMonth.getFullYear()));
        let newIndex = pathView.currentIndex + monthDiff;
        let firstItemDate = pathView.model.data(pathView.model.index(1, 0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
        let lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1, 0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
        while (firstItemDate >= date) {
            pathView.model.addDates(false);
            firstItemDate = pathView.model.data(pathView.model.index(1, 0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
            newIndex = 0;
        }
        if (firstItemDate < date && newIndex === 0) {
            newIndex = date.getMonth() - firstItemDate.getMonth() + (12 * (date.getFullYear() - firstItemDate.getFullYear())) + 1;
        }
        while (lastItemDate <= date) {
            pathView.model.addDates(true);
            lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1, 0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
        }
        pathView.currentIndex = newIndex;
        selectedDate = date;
    }
    signal viewIncidence(var modelData, var collectionData)

    onSelectedDateChanged: moveToSelected()

    actions {
        left: Qt.application.layoutDirection === Qt.RightToLeft ? nextAction : previousAction
        main: todayAction
        right: Qt.application.layoutDirection === Qt.RightToLeft ? previousAction : nextAction
    }
    PathView {
        id: pathView
        property date dateToUse
        property int startIndex

        anchors.fill: parent
        flickDeceleration: Kirigami.Units.longDuration
        focus: true
        interactive: Kirigami.Settings.tabletMode
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        snapMode: PathView.SnapToItem

        Component.onCompleted: {
            startIndex = count / 2;
            currentIndex = startIndex;
        }
        onCurrentIndexChanged: {
            root.startDate = currentItem.firstDayOfMonth;
            root.month = currentItem.month;
            root.year = currentItem.year;
            if (currentIndex >= count - 2) {
                model.addDates(true);
            } else if (currentIndex <= 1) {
                model.addDates(false);
                startIndex += model.datesToAdd;
            }
        }

        delegate: Loader {
            id: viewLoader
            property date firstDayOfMonth: model.firstDay
            property int index: model.index
            property bool isCurrentItem: PathView.isCurrentItem
            property bool isNextOrCurrentItem: index >= pathView.currentIndex - 1 && index <= pathView.currentIndex + 1
            property int month: model.selectedMonth - 1 // Convert QDateTime month to JS month
            property date startDate: model.startDate
            property int year: model.selectedYear

            active: isNextOrCurrentItem

            //asynchronous: true
            sourceComponent: QQC2.ScrollView {
                property alias scheduleListView: scheduleListView

                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
                contentWidth: availableWidth
                height: pathView.height
                width: pathView.width

                ListView {
                    id: scheduleListView
                    /* Spacing in this view works thus:
                     * 1. scheduleListView's spacing adds space between each day delegate component (including separators)
                     * 2. Weekly listSectionHeader has spacing of the day delegate column removed from bottom margin
                     * 3. Delegate's Separator's spacing gives same space (minus some adjustment) between it and dayGrid
                     */
                    Layout.bottomMargin: Kirigami.Units.largeSpacing * 5
                    header: Kalendar.Config.showMonthHeader ? monthHeaderComponent : null
                    highlightRangeMode: ListView.ApplyRange
                    model: modelLoader.item
                    spacing: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                    onCountChanged: if (root.initialMonth)
                        root.moveToSelected()

                    Component {
                        id: monthHeaderComponent
                        Kirigami.ItemViewHeader {
                            //backgroundImage.source: "../banner.jpg"
                            title: Qt.locale().monthName(viewLoader.month)
                            visible: Kalendar.Config.showMonthHeader
                        }
                    }
                    Loader {
                        id: modelLoader
                        asynchronous: true

                        sourceComponent: Kalendar.MultiDayIncidenceModel {
                            periodLength: 1

                            model: Kalendar.IncidenceOccurrenceModel {
                                id: occurrenceModel
                                calendar: Kalendar.CalendarManager.calendar
                                filter: root.filter ? root.filter : {}
                                length: new Date(start.getFullYear(), start.getMonth(), 0).getDate()
                                objectName: "incidenceOccurrenceModel"
                                start: viewLoader.firstDayOfMonth
                            }
                        }
                    }

                    delegate: DayMouseArea {
                        id: dayMouseArea
                        addDate: periodStartDate
                        height: dayColumn.height
                        width: dayColumn.width

                        onAddNewIncidence: addIncidence(type, addDate)
                        onDeselect: root.deselect()

                        Rectangle {
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            color: Kirigami.Theme.activeBackgroundColor
                            height: Kirigami.Settings.isMobile ? // Mobile adds extra padding
                            parent.height + Kirigami.Units.largeSpacing * 2 : parent.height + Kirigami.Units.largeSpacing
                            visible: dayGrid.isToday
                            z: 0
                        }
                        ColumnLayout {
                            // Tip: do NOT hide an entire delegate.
                            // This will very much screw up use of positionViewAtIndex.
                            id: dayColumn
                            width: scheduleListView.width

                            Kirigami.ListSectionHeader {
                                id: weekHeading
                                Layout.bottomMargin: -dayColumn.spacing
                                Layout.fillWidth: true
                                text: {
                                    let nextDay = DateUtils.getLastDayOfWeek(DateUtils.nextWeek(periodStartDate));
                                    if (nextDay.getMonth() !== periodStartDate.getMonth()) {
                                        nextDay = new Date(nextDay.getFullYear(), nextDay.getMonth(), 0);
                                    }
                                    return periodStartDate.toLocaleDateString(Qt.locale(), "dddd <b>dd</b>") + " - " + nextDay.toLocaleDateString(Qt.locale(), "dddd <b>dd</b> MMMM");
                                }
                                visible: Kalendar.Config.showWeekHeaders && periodStartDate !== undefined && (periodStartDate.getDay() === Qt.locale().firstDayOfWeek || index === 0)
                            }
                            Kirigami.Separator {
                                id: topSeparator
                                Layout.bottomMargin: scheduleListView.spacing - Kirigami.Units.smallSpacing
                                Layout.fillWidth: true
                                z: 1
                            }

                            // Day + incidences
                            GridLayout {
                                id: dayGrid
                                property real dayLabelWidth: Kirigami.Units.gridUnit * 4
                                property bool isToday: new Date(periodStartDate).setHours(0, 0, 0, 0) === new Date().setHours(0, 0, 0, 0)

                                Layout.leftMargin: Kirigami.Units.largeSpacing
                                Layout.rightMargin: Kirigami.Units.largeSpacing
                                columns: 2
                                rows: 2

                                QQC2.Label {
                                    id: smallDayLabel
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.maximumWidth: dayGrid.dayLabelWidth
                                    Layout.minimumWidth: dayGrid.dayLabelWidth
                                    color: Kirigami.Theme.disabledTextColor
                                    horizontalAlignment: Text.AlignRight
                                    padding: Kirigami.Units.smallSpacing
                                    rightPadding: Kirigami.Units.largeSpacing
                                    text: periodStartDate.toLocaleDateString(Qt.locale(), "ddd <b>dd</b>")
                                    visible: !cardsColumn.visible
                                }
                                QQC2.Label {
                                    id: emptyDayText
                                    Layout.alignment: Qt.AlignVCenter
                                    color: Kirigami.Theme.disabledTextColor
                                    text: i18n("Clear day.")
                                    visible: !cardsColumn.visible
                                }
                                Kirigami.Heading {
                                    id: largeDayLabel
                                    Layout.alignment: Qt.AlignTop
                                    Layout.fillHeight: true
                                    Layout.maximumWidth: dayGrid.dayLabelWidth
                                    Layout.minimumWidth: dayGrid.dayLabelWidth
                                    color: dayGrid.isToday ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                    horizontalAlignment: Text.AlignRight
                                    level: dayGrid.isToday ? 1 : 3
                                    padding: Kirigami.Units.smallSpacing
                                    rightPadding: Kirigami.Units.largeSpacing
                                    text: periodStartDate.toLocaleDateString(Qt.locale(), "ddd<br><b>dd</b>")
                                    textFormat: Text.StyledText
                                    verticalAlignment: Text.AlignTop
                                    visible: incidences.length || dayGrid.isToday
                                    wrapMode: Text.Wrap
                                }
                                ColumnLayout {
                                    id: cardsColumn
                                    Layout.fillWidth: true
                                    visible: incidences.length || dayGrid.isToday

                                    Kirigami.AbstractCard {
                                        id: suggestCard
                                        Layout.fillWidth: true
                                        showClickFeedback: true
                                        visible: !incidences.length && dayGrid.isToday

                                        onClicked: root.addIncidence(Kalendar.IncidenceWrapper.TypeEvent, periodStartDate)

                                        contentItem: QQC2.Label {
                                            property string selectMethod: Kirigami.Settings.isMobile ? i18n("Tap") : i18n("Click")

                                            text: i18n("Nothing on the books today. %1 to add something.", selectMethod)
                                            wrapMode: Text.Wrap
                                        }
                                    }
                                    Repeater {
                                        model: incidences

                                        Repeater {
                                            id: incidencesRepeater
                                            model: modelData

                                            Kirigami.AbstractCard {
                                                id: incidenceCard
                                                property int dayOfMultidayIncidence: DateUtils.fullDaysBetweenDates(modelData.startTime, periodStartDate)
                                                property int incidenceDays: DateUtils.fullDaysBetweenDates(modelData.startTime, modelData.endTime)
                                                property bool isOpenOccurrence: root.openOccurrence ? root.openOccurrence.incidenceId === modelData.incidenceId : false
                                                property bool multiday: modelData.startTime.getDate() !== modelData.endTime.getDate()
                                                property real paddingSize: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing

                                                Layout.fillWidth: true
                                                bottomPadding: paddingSize
                                                showClickFeedback: true
                                                topPadding: paddingSize

                                                IncidenceMouseArea {
                                                    id: incidenceMouseArea
                                                    collectionId: modelData.collectionId
                                                    incidenceData: modelData

                                                    onAddSubTodoClicked: root.addSubTodo(parentWrapper)
                                                    onDeleteClicked: root.deleteIncidence(incidencePtr, deleteDate)
                                                    onEditClicked: root.editIncidence(incidencePtr, collectionId)
                                                    onTodoCompletedClicked: root.completeTodo(incidencePtr)
                                                    onViewClicked: root.viewIncidence(modelData, collectionData)
                                                }

                                                background: IncidenceBackground {
                                                    id: incidenceBackground
                                                    isDark: root.isDark
                                                    isOpenOccurrence: parent.isOpenOccurrence
                                                }
                                                contentItem: GridLayout {
                                                    id: cardContents
                                                    property color textColor: LabelUtils.getIncidenceLabelColor(modelData.color, root.isDark)

                                                    columns: root.isLarge ? 3 : 2
                                                    rows: root.isLarge ? 1 : 2

                                                    RowLayout {
                                                        Kirigami.Icon {
                                                            Layout.fillHeight: true
                                                            color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") : cardContents.textColor
                                                            isMask: true
                                                            source: modelData.incidenceTypeIcon
                                                        }
                                                        QQC2.Label {
                                                            Layout.column: 0
                                                            Layout.columnSpan: root.isLarge ? 2 : 1
                                                            Layout.fillHeight: true
                                                            Layout.fillWidth: true
                                                            Layout.row: 0
                                                            color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") : cardContents.textColor
                                                            elide: Text.ElideRight
                                                            font.weight: Font.Medium
                                                            text: {
                                                                if (incidenceCard.multiday) {
                                                                    return i18n("%1 (Day %2 of %3)", modelData.text, incidenceCard.dayOfMultidayIncidence, incidenceCard.incidenceDays);
                                                                } else {
                                                                    return modelData.text;
                                                                }
                                                            }
                                                        }
                                                    }
                                                    RowLayout {
                                                        id: additionalIcons
                                                        Layout.column: 1
                                                        Layout.row: 0
                                                        visible: modelData.hasReminders || modelData.recurs

                                                        Kirigami.Icon {
                                                            id: recurringIcon
                                                            Layout.fillHeight: true
                                                            color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") : cardContents.textColor
                                                            isMask: true
                                                            source: "appointment-recurring"
                                                            visible: modelData.recurs
                                                        }
                                                        Kirigami.Icon {
                                                            id: reminderIcon
                                                            Layout.fillHeight: true
                                                            color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") : cardContents.textColor
                                                            isMask: true
                                                            source: "appointment-reminder"
                                                            visible: modelData.hasReminders
                                                        }
                                                    }
                                                    QQC2.Label {
                                                        Layout.column: root.isLarge ? 2 : 0
                                                        Layout.fillHeight: true
                                                        // This way all the icons are aligned
                                                        Layout.maximumWidth: Kirigami.Units.gridUnit * 7
                                                        Layout.minimumWidth: Kirigami.Units.gridUnit * 7
                                                        Layout.row: root.isLarge ? 0 : 1
                                                        color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") : cardContents.textColor
                                                        horizontalAlignment: root.isLarge ? Text.AlignRight : Text.AlignLeft
                                                        text: {
                                                            if (modelData.allDay) {
                                                                i18n("Runs all day");
                                                            } else if (modelData.startTime.getTime() === modelData.endTime.getTime()) {
                                                                modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
                                                            } else if (!incidenceCard.multiday) {
                                                                i18nc("Displays times between incidence start and end", "%1 - %2", modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat), modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                            } else if (incidenceCard.dayOfMultidayIncidence === 1) {
                                                                i18n("Starts at %1", modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                            } else if (incidenceCard.dayOfMultidayIncidence === incidenceCard.incidenceDays) {
                                                                i18n("Ends at %1", modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                            } else {
                                                                // In between multiday start/finish
                                                                i18n("Runs All Day");
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        model: Kalendar.InfiniteCalendarViewModel {
            scale: Kalendar.InfiniteCalendarViewModel.MonthScale
        }
        path: Path {
            startX: -pathView.width * pathView.count / 2 + pathView.width / 2
            startY: pathView.height / 2

            PathLine {
                x: pathView.width * pathView.count / 2 + pathView.width / 2
                y: pathView.height / 2
            }
        }
    }
    NavigationMouseArea {
    }

    background: Rectangle {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.inherit: false
        color: Kirigami.Theme.backgroundColor
    }
}
