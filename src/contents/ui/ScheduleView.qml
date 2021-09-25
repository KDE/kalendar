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

    signal addIncidence(int type, date addDate)
    signal viewIncidence(var modelData, var collectionData)
    signal editIncidence(var incidencePtr, var collectionId)
    signal deleteIncidence(var incidencePtr, date deleteDate)
    signal completeTodo(var incidencePtr)
    signal addSubTodo(var parentWrapper)

    property var openOccurrence
    property date selectedDate: new Date()
    property date startDate: DateUtils.getFirstDayOfMonth(selectedDate)
    property int day: selectedDate.getDate()
    property int month: selectedDate.getMonth()
    property int year: selectedDate.getFullYear()
    property bool initialMonth: true
    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 30
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    onSelectedDateChanged: moveToSelected()

    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    function moveToSelected() {
        if (selectedDate.getDate() > 1) {
            pathView.currentItem.item.scheduleListView.positionViewAtIndex(selectedDate.getDate() - 1, ListView.Beginning);
        } else {
            pathView.currentItem.item.scheduleListView.positionViewAtBeginning()
        }
    }

    function setToDate(date, isInitialMonth = false) {
        root.initialMonth = isInitialMonth;
        let monthDiff = date.getMonth() - pathView.currentItem.firstDayOfMonth.getMonth() + (12 * (date.getFullYear() - pathView.currentItem.firstDayOfMonth.getFullYear()))
        let newIndex = pathView.currentIndex + monthDiff;

        let firstItemDate = pathView.model.data(pathView.model.index(1,0), Kalendar.MonthViewModel.FirstDayOfMonthRole);
        let lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1,0), Kalendar.MonthViewModel.FirstDayOfMonthRole);

        while(firstItemDate >= date) {
            pathView.model.addDates(false)
            firstItemDate = pathView.model.data(pathView.model.index(1,0), Kalendar.MonthViewModel.FirstDayOfMonthRole);
            newIndex = 0;
        }
        if(firstItemDate < date && newIndex === 0) {
            newIndex = date.getMonth() - firstItemDate.getMonth() + (12 * (date.getFullYear() - firstItemDate.getFullYear())) + 1;
        }

        while(lastItemDate <= date) {
            pathView.model.addDates(true)
            lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1,0), Kalendar.MonthViewModel.FirstDayOfMonthRole);
        }
        pathView.currentIndex = newIndex;
        selectedDate = date;
    }

    actions {
        left: Kirigami.Action {
            icon.name: "go-previous"
            text: i18n("Previous Month")
            shortcut: "Left"
            onTriggered: setToDate(DateUtils.addMonthsToDate(pathView.currentItem.firstDayOfMonth, -1))
            displayHint: Kirigami.DisplayHint.IconOnly
        }
        right: Kirigami.Action {
            icon.name: "go-next"
            text: i18n("Next Month")
            shortcut: "Right"
            onTriggered: setToDate(DateUtils.addMonthsToDate(pathView.currentItem.firstDayOfMonth, 1))
            displayHint: Kirigami.DisplayHint.IconOnly
        }
        main: Kirigami.Action {
            icon.name: "go-jump-today"
            text: i18n("Today")
            onTriggered: setToDate(new Date())
        }
    }

    padding: 0
    bottomPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

    PathView {
        id: pathView

        anchors.fill: parent
        flickDeceleration: Kirigami.Units.longDuration
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        snapMode: PathView.SnapToItem
        focus: true
        interactive: Kirigami.Settings.tabletMode

        path: Path {
            startX: - pathView.width * pathView.count / 2 + pathView.width / 2
            startY: pathView.height / 2
            PathLine {
                x: pathView.width * pathView.count / 2 + pathView.width / 2
                y: pathView.height / 2
            }
        }

        model: Kalendar.MonthViewModel {}

        property date dateToUse
        property int startIndex
        Component.onCompleted: {
            startIndex = count / 2;
            currentIndex = startIndex;
        }
        onCurrentIndexChanged: {
            root.startDate = currentItem.firstDayOfMonth;
            root.month = currentItem.month;
            root.year = currentItem.year;
            root.initialMonth = false;

            if(currentIndex >= count - 2) {
                model.addDates(true);
            } else if (currentIndex <= 1) {
                model.addDates(false);
                startIndex += model.datesToAdd;
            }
        }

        delegate: Loader {
            id: viewLoader

            property date startDate: model.startDate
            property date firstDayOfMonth: model.firstDay
            property int month: model.selectedMonth - 1 // Convert QDateTime month to JS month
            property int year: model.selectedYear

            property int index: model.index
            property bool isCurrentItem: PathView.isCurrentItem
            property bool isNextOrCurrentItem: index >= pathView.currentIndex -1 && index <= pathView.currentIndex + 1

            active: isNextOrCurrentItem
            //asynchronous: true
            sourceComponent: QQC2.ScrollView {
                width: pathView.width
                height: pathView.height
                contentWidth: availableWidth
                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
                property alias scheduleListView: scheduleListView

                ListView {
                    id: scheduleListView

                    spacing: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing
                    /* Spacing in this view works thus:
                     * 1. scheduleListView's spacing adds space between each day delegate component (including separators)
                     * 2. Weekly listSectionHeader has spacing of the day delegate column removed from bottom margin
                     * 3. Delegate's Separator's spacing gives same space (minus some adjustment) between it and dayGrid
                     */
                    Layout.bottomMargin: Kirigami.Units.largeSpacing * 5
                    highlightRangeMode: ListView.ApplyRange
                    onCountChanged: if(root.initialMonth) root.moveToSelected()

                    Component {
                        id: monthHeaderComponent
                        Kirigami.ItemViewHeader {
                            //backgroundImage.source: "../banner.jpg"
                            title: Qt.locale().monthName(viewLoader.month)
                            visible: Kalendar.Config.showMonthHeader
                        }
                    }

                    header: Kalendar.Config.showMonthHeader ? monthHeaderComponent : null

                    Loader {
                        id: modelLoader
                        asynchronous: true
                        sourceComponent: Kalendar.MultiDayIncidenceModel {
                            periodLength: 1
                            model: Kalendar.IncidenceOccurrenceModel {
                                id: occurrenceModel
                                objectName: "incidenceOccurrenceModel"
                                start: viewLoader.firstDayOfMonth
                                length: new Date(start.getFullYear(), start.getMonth(), 0).getDate()
                                filter: root.filter ? root.filter : {}
                                calendar: Kalendar.CalendarManager.calendar
                            }
                        }
                    }

                    model: modelLoader.item

                    delegate: DayMouseArea {
                        id: dayMouseArea

                        width: dayColumn.width
                        height: dayColumn.height

                        addDate: periodStartDate
                        onAddNewIncidence: addIncidence(type, addDate)

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.left: parent.left
                            height: Kirigami.Settings.isMobile ? // Mobile adds extra padding
                            parent.height + Kirigami.Units.largeSpacing * 2 : parent.height + Kirigami.Units.largeSpacing
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                            color: Kirigami.Theme.activeBackgroundColor
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

                                Layout.fillWidth: true
                                Layout.bottomMargin: -dayColumn.spacing

                                text: {
                                    let nextDay = DateUtils.getLastDayOfWeek( DateUtils.nextWeek(periodStartDate) );
                                    if (nextDay.getMonth() !== periodStartDate.getMonth()) {
                                        nextDay = new Date(nextDay.getFullYear(), nextDay.getMonth(), 0);
                                    }

                                    return periodStartDate.toLocaleDateString(Qt.locale(), "dddd <b>dd</b>") + " - " + nextDay.toLocaleDateString(Qt.locale(), "dddd <b>dd</b> MMMM");
                                }
                                visible: Kalendar.Config.showWeekHeaders &&
                                periodStartDate !== undefined &&
                                (periodStartDate.getDay() === Qt.locale().firstDayOfWeek || index === 0)
                            }

                            Kirigami.Separator {
                                id: topSeparator
                                Layout.fillWidth: true
                                Layout.bottomMargin: scheduleListView.spacing - Kirigami.Units.smallSpacing
                                z: 1
                            }

                            // Day + incidences
                            GridLayout {
                                id: dayGrid

                                columns: 2
                                rows: 2

                                Layout.leftMargin: Kirigami.Units.largeSpacing
                                Layout.rightMargin: Kirigami.Units.largeSpacing

                                property real dayLabelWidth: Kirigami.Units.gridUnit * 4
                                property bool isToday: new Date(periodStartDate).setHours(0,0,0,0) === new Date().setHours(0,0,0,0)

                                QQC2.Label {
                                    id: smallDayLabel

                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.maximumWidth: dayGrid.dayLabelWidth
                                    Layout.minimumWidth: dayGrid.dayLabelWidth
                                    padding: Kirigami.Units.smallSpacing
                                    rightPadding: Kirigami.Units.largeSpacing
                                    horizontalAlignment: Text.AlignRight

                                    visible: !cardsColumn.visible
                                    text: periodStartDate.toLocaleDateString(Qt.locale(), "ddd <b>dd</b>")
                                    color: Kirigami.Theme.disabledTextColor
                                }

                                QQC2.Label {
                                    id: emptyDayText

                                    Layout.alignment: Qt.AlignVCenter
                                    visible: !cardsColumn.visible
                                    text: i18n("Clear day.")
                                    color: Kirigami.Theme.disabledTextColor
                                }

                                Kirigami.Heading {
                                    id: largeDayLabel

                                    Layout.alignment: Qt.AlignTop
                                    Layout.maximumWidth: dayGrid.dayLabelWidth
                                    Layout.minimumWidth: dayGrid.dayLabelWidth
                                    Layout.fillHeight: true
                                    padding: Kirigami.Units.smallSpacing
                                    rightPadding: Kirigami.Units.largeSpacing
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignTop

                                    level: dayGrid.isToday ? 1 : 3
                                    textFormat: Text.StyledText
                                    wrapMode: Text.Wrap
                                    color: dayGrid.isToday ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                    text: periodStartDate.toLocaleDateString(Qt.locale(), "ddd<br><b>dd</b>")
                                    visible: incidences.length || dayGrid.isToday
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

                                        contentItem: QQC2.Label {
                                            property string selectMethod: Kirigami.Settings.isMobile ? i18n("Tap") : i18n("Click")
                                            text: i18n("Nothing on the books today. %1 to add something.", selectMethod)
                                            wrapMode: Text.Wrap
                                        }

                                        onClicked: root.addIncidence(Kalendar.IncidenceWrapper.TypeEvent, periodStartDate)
                                    }

                                    Repeater {
                                        model: incidences
                                        Repeater {
                                            id: incidencesRepeater
                                            model: modelData

                                            Kirigami.AbstractCard {
                                                id: incidenceCard

                                                Layout.fillWidth: true

                                                Kirigami.Theme.inherit: false
                                                Kirigami.Theme.colorSet: Kirigami.Theme.View
                                                Kirigami.Theme.backgroundColor: isOpenOccurrence ? modelData.color :
                                                    LabelUtils.getIncidenceBackgroundColor(modelData.color, root.isDark)
                                                Kirigami.Theme.highlightColor: Qt.darker(Kirigami.Theme.backgroundColor, 3)

                                                property real paddingSize: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing

                                                topPadding: paddingSize
                                                bottomPadding: paddingSize

                                                showClickFeedback: true

                                                property bool isOpenOccurrence: root.openOccurrence ?
                                                    root.openOccurrence.incidenceId === modelData.incidenceId : false
                                                property bool multiday: modelData.startTime.getDate() !== modelData.endTime.getDate()
                                                property int incidenceDays: DateUtils.fullDaysBetweenDates(modelData.startTime, modelData.endTime)
                                                property int dayOfMultidayIncidence: DateUtils.fullDaysBetweenDates(modelData.startTime, periodStartDate)

                                                contentItem: GridLayout {
                                                    id: cardContents

                                                    columns: root.isLarge ? 3 : 2
                                                    rows: root.isLarge ? 1 : 2

                                                    property color textColor: LabelUtils.getIncidenceLabelColor(modelData.color, root.isDark)

                                                    RowLayout {
                                                        Kirigami.Icon {
                                                            Layout.fillHeight: true
                                                            source: modelData.incidenceTypeIcon
                                                            color: cardContents.textColor
                                                        }

                                                        QQC2.Label {
                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true
                                                            Layout.column: 0
                                                            Layout.row: 0
                                                            Layout.columnSpan: root.isLarge ? 2 : 1

                                                            color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                            cardContents.textColor
                                                            text: {
                                                                if(incidenceCard.multiday) {
                                                                    return i18n("%1 (Day %2 of %3)", modelData.text, incidenceCard.dayOfMultidayIncidence, incidenceCard.incidenceDays);
                                                                } else {
                                                                    return modelData.text;
                                                                }
                                                            }
                                                            elide: Text.ElideRight
                                                            font.weight: Font.Medium
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
                                                            source: "appointment-recurring"
                                                            isMask: true
                                                            color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                            cardContents.textColor
                                                            visible: modelData.recurs
                                                        }
                                                        Kirigami.Icon {
                                                            id: reminderIcon
                                                            Layout.fillHeight: true
                                                            source: "appointment-reminder"
                                                            isMask: true
                                                            color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                            cardContents.textColor
                                                            visible: modelData.hasReminders
                                                        }
                                                    }


                                                    QQC2.Label {
                                                        Layout.fillHeight: true
                                                        // This way all the icons are aligned
                                                        Layout.maximumWidth: Kirigami.Units.gridUnit * 7
                                                        Layout.minimumWidth: Kirigami.Units.gridUnit * 7
                                                        Layout.column: root.isLarge ? 2 : 0
                                                        Layout.row: root.isLarge ? 0 : 1

                                                        horizontalAlignment: root.isLarge ? Text.AlignRight : Text.AlignLeft
                                                        color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                        cardContents.textColor
                                                        text: {
                                                            if (modelData.allDay) {
                                                                i18n("Runs all day")
                                                            } else if (modelData.startTime.getTime() === modelData.endTime.getTime()) {
                                                                modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
                                                            } else if (!incidenceCard.multiday) {
                                                                i18nc("Displays times between incidence start and end", "%1 - %2",
                                                                      modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat), modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                            } else if (incidenceCard.dayOfMultidayIncidence === 1) {
                                                                i18n("Starts at %1", modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                            } else if (incidenceCard.dayOfMultidayIncidence === incidenceCard.incidenceDays) {
                                                                i18n("Ends at %1", modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                            } else { // In between multiday start/finish
                                                                i18n("Runs All Day")
                                                            }
                                                        }
                                                    }
                                                }

                                                IncidenceMouseArea {
                                                    id: incidenceMouseArea

                                                    incidenceData: modelData
                                                    collectionId: modelData.collectionId

                                                    onViewClicked: root.viewIncidence(modelData, collectionData)
                                                    onEditClicked: root.editIncidence(incidencePtr, collectionId)
                                                    onDeleteClicked: root.deleteIncidence(incidencePtr, deleteDate)
                                                    onTodoCompletedClicked: root.completeTodo(incidencePtr)
                                                    onAddSubTodoClicked: root.addSubTodo(parentWrapper)
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

    NavigationMouseArea {}
}
