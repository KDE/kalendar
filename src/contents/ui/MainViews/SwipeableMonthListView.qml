// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar 1.0 as Kalendar
import org.kde.kalendar.utils 1.0
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

PathView {
    id: pathView

    property bool initialMonth: true
    property var openOccurrence
    property date currentDate: new Date()
    property date startDate: DateUtils.getFirstDayOfMonth(currentDate)

    onStartDateChanged: {
        if (pathView.currentItem) {
            pathView.currentItem.item.savedYScrollPos = 0;
            moveToSelected();
        }
    }

    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 30
    readonly property bool isDark: KalendarUiUtils.darkMode
    property real maxTimeLabelWidth: 0
    property bool dragDropEnabled: true

    function addIncidence(type, addDate) {
        pathView.currentItem.item.savedYScrollPos = pathView.currentItem.item.QQC2.ScrollBar.vertical.visualPosition;
        KalendarUiUtils.setUpAdd(type, addDate);
    }

    function viewIncidence(modelData, incidenceItem) {
        pathView.currentItem.item.savedYScrollPos = pathView.currentItem.item.QQC2.ScrollBar.vertical.visualPosition;
        KalendarUiUtils.setUpView(modelData, incidenceItem);
    }

    function editIncidence(incidencePtr) {
        pathView.currentItem.item.savedYScrollPos = pathView.currentItem.item.QQC2.ScrollBar.vertical.visualPosition;
        KalendarUiUtils.setUpEdit(incidencePtr);
    }

    function deleteIncidence(incidencePtr, deleteDate) {
        pathView.currentItem.item.savedYScrollPos = pathView.currentItem.item.QQC2.ScrollBar.vertical.visualPosition;
        KalendarUiUtils.setUpDelete(incidencePtr, deleteDate);
    }

    function completeTodo(incidencePtr) {
        pathView.currentItem.item.savedYScrollPos = pathView.currentItem.item.QQC2.ScrollBar.vertical.visualPosition;
        KalendarUiUtils.completeTodo(incidencePtr);
    }

    function addSubTodo(parentWrapper) {
        pathView.currentItem.item.savedYScrollPos = pathView.currentItem.item.QQC2.ScrollBar.vertical.visualPosition;
        KalendarUiUtils.setUpAddSubTodo(parentWrapper);
    }

    function moveIncidence(startOffset, occurrenceDate, incidenceWrapper, caughtDelegate) {
        pathView.currentItem.item.savedYScrollPos = pathView.currentItem.item.QQC2.ScrollBar.vertical.visualPosition;
        KalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, startOffset, startOffset, occurrenceDate, caughtDelegate);
    }

    function setToDate(date, isInitialMonth = false) {
        initialMonth = isInitialMonth;
        let monthDiff = date.getMonth() - pathView.currentItem.firstDayOfMonth.getMonth() + (12 * (date.getFullYear() - pathView.currentItem.firstDayOfMonth.getFullYear()))
        let newIndex = pathView.currentIndex + monthDiff;

        let firstItemDate = pathView.model.data(pathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
        let lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);

        while(firstItemDate >= date) {
            pathView.model.addDates(false)
            firstItemDate = pathView.model.data(pathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
            newIndex = 0;
        }
        if(firstItemDate < date && newIndex === 0) {
            newIndex = date.getMonth() - firstItemDate.getMonth() + (12 * (date.getFullYear() - firstItemDate.getFullYear())) + 1;
        }

        while(lastItemDate <= date) {
            pathView.model.addDates(true)
            lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
        }
        pathView.currentIndex = newIndex;
        startDate = date;
    }

    function moveToSelected() {
        if (!pathView.currentItem || !pathView.currentItem.item) {
            return;
        }

        if (pathView.currentItem.item.savedYScrollPos > 0) {
            pathView.currentItem.item.QQC2.ScrollBar.vertical.position = pathView.currentItem.item.savedYScrollPos;
            return;
        }

        if (startDate.getDate() > 1) {
            pathView.currentItem.item.scheduleListView.positionViewAtIndex(startDate.getDate() - 1, ListView.Beginning);
        } else {
            pathView.currentItem.item.scheduleListView.positionViewAtBeginning()
        }
    }

    flickDeceleration: Kirigami.Units.longDuration
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    snapMode: PathView.SnapToItem
    focus: true
    interactive: Kirigami.Settings.tabletMode

    pathItemCount: 3
    path: Path {
        startX: - pathView.width * pathView.pathItemCount / 2 + pathView.width / 2
        startY: pathView.height / 2
        PathLine {
            x: pathView.width * pathView.pathItemCount / 2 + pathView.width / 2
            y: pathView.height / 2
        }
    }

    model: Kalendar.InfiniteCalendarViewModel {
        scale: Kalendar.InfiniteCalendarViewModel.MonthScale
    }

    property date dateToUse
    property int startIndex
    Component.onCompleted: {
        startIndex = count / 2;
        currentIndex = startIndex;
    }
    onCurrentIndexChanged: {
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
        property int daysInMonth: new Date(firstDayOfMonth.getFullYear(), firstDayOfMonth.getMonth(), 0).getDate()
        property int month: model.selectedMonth - 1 // Convert QDateTime month to JS month
        property int year: model.selectedYear

        property int index: model.index
        property bool isCurrentItem: PathView.isCurrentItem
        property bool isNextOrCurrentItem: index >= pathView.currentIndex -1 && index <= pathView.currentIndex + 1

        active: isNextOrCurrentItem
        asynchronous: !isCurrentItem
        visible: status === Loader.Ready
        sourceComponent: QQC2.ScrollView {
            id: scrollView
            width: pathView.width
            height: pathView.height
            contentWidth: availableWidth
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

            readonly property alias scheduleListView: scheduleListView
            property real savedYScrollPos

            ListView {
                id: scheduleListView

                /* Spacing in this view works thus:
                 * 1. scheduleListView's spacing adds space between each day delegate component (including separators)
                 * 2. Weekly listSectionHeader has spacing of the day delegate column removed from bottom margin
                 * 3. Delegate's Separator's spacing gives same space (minus some adjustment) between it and dayGrid
                 */
                spacing: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing
                highlightRangeMode: ListView.ApplyRange

                onCountChanged: if(pathView.initialMonth) pathView.moveToSelected();

                model: Kalendar.MultiDayIncidenceModel {
                   periodLength: 1
                   model: Kalendar.IncidenceOccurrenceModel {
                       start: viewLoader.firstDayOfMonth
                       length: viewLoader.daysInMonth
                       calendar: Kalendar.CalendarManager.calendar
                       filter: Kalendar.Filter
                   }
               }

                delegate: DayMouseArea {
                    id: dayMouseArea

                    width: dayColumn.width
                    height: model.index === scheduleListView.count - 1 ? dayColumn.height + Kirigami.Units.largeSpacing : dayColumn.height

                    addDate: periodStartDate
                    onAddNewIncidence: addIncidence(type, addDate)
                    onDeselect: KalendarUiUtils.appMain.incidenceInfoViewer.close()

                    Rectangle {
                        id: backgroundRectangle
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.left: parent.left
                        height: Kirigami.Settings.isMobile ? // Mobile adds extra padding
                                parent.height + Kirigami.Units.largeSpacing * 2 :
                                parent.height + Kirigami.Units.largeSpacing
                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                        color: incidenceDropArea.containsDrag ? Kirigami.Theme.positiveBackgroundColor :
                               dayGrid.isToday ? Kirigami.Theme.activeBackgroundColor :
                               Kirigami.Theme.backgroundColor
                        z: 0
                    }

                    DropArea {
                        id: incidenceDropArea
                        anchors.fill: parent
                        z: 9999
                        onDropped: if(viewLoader.isCurrentItem) {
                            scrollView.savedYScrollPos = scrollView.QQC2.ScrollBar.vertical.visualPosition;

                            const pos = mapToItem(pathView, backgroundRectangle.x, backgroundRectangle.y);
                            drop.source.caughtX = pos.x + dayGrid.dayLabelWidth + Kirigami.Units.largeSpacing;
                            drop.source.caughtY = pos.y + dayColumn.spacing + Kirigami.Units.largeSpacing;
                            drop.source.caught = true;

                            const incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', incidenceDropArea, "incidence");
                            incidenceWrapper.incidenceItem = Kalendar.CalendarManager.incidenceItem(drop.source.incidencePtr);

                            let sameTimeOnDate = new Date(dayMouseArea.addDate);
                            sameTimeOnDate = new Date(sameTimeOnDate.setHours(drop.source.occurrenceDate.getHours(), drop.source.occurrenceDate.getMinutes()));
                            const offset = sameTimeOnDate.getTime() - drop.source.occurrenceDate.getTime();
                            pathView.moveIncidence(offset, drop.source.occurrenceDate, incidenceWrapper, drop.source);
                        }
                    }

                    ColumnLayout {
                        // Tip: do NOT hide an entire delegate.
                        // This will very much screw up use of positionViewAtIndex.

                        id: dayColumn
                        width: scheduleListView.width

                        Kirigami.ListSectionHeader {
                            id: weekHeading

                            Layout.fillWidth: true
                            Layout.bottomMargin: -dayColumn.spacing // Remove default spacing, bring week header right down to day square

                            text: {
                                let nextDay = DateUtils.getLastDayOfWeek( DateUtils.nextWeek(periodStartDate) );
                                if (nextDay.getMonth() !== periodStartDate.getMonth()) {
                                    nextDay = new Date(nextDay.getFullYear(), nextDay.getMonth(), 0);
                                }

                                return periodStartDate.toLocaleDateString(Qt.locale(), "dddd <b>dd</b>") + "–" + nextDay.toLocaleDateString(Qt.locale(), "dddd <b>dd</b> MMMM");
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

                            QQC2.Button {
                                id: dayButton
                                Layout.fillHeight: true
                                Layout.maximumWidth: dayGrid.dayLabelWidth
                                Layout.minimumWidth: dayGrid.dayLabelWidth
                                padding: Kirigami.Units.smallSpacing
                                rightPadding: Kirigami.Units.largeSpacing

                                flat: true
                                onClicked: KalendarUiUtils.openDayLayer(periodStartDate)

                                property Item smallDayLabel: QQC2.Label {
                                    id: smallDayLabel

                                    Layout.alignment: Qt.AlignVCenter
                                    width: dayButton.width
                                    horizontalAlignment: Text.AlignRight

                                    visible: !cardsColumn.visible
                                    wrapMode: Text.Wrap
                                    text: periodStartDate.toLocaleDateString(Qt.locale(), "ddd <b>dd</b>")
                                    color: Kirigami.Theme.disabledTextColor
                                }


                                property Item largeDayLabel: Kirigami.Heading {
                                    id: largeDayLabel

                                    width: dayButton.width
                                    Layout.alignment: Qt.AlignTop
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignTop

                                    level: dayGrid.isToday ? 1 : 3
                                    textFormat: Text.StyledText
                                    wrapMode: Text.Wrap
                                    color: dayGrid.isToday ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                    text: periodStartDate.toLocaleDateString(Qt.locale(), "ddd<br><b>dd</b>")
                                }


                                contentItem: incidences.length || dayGrid.isToday ? largeDayLabel : smallDayLabel
                            }

                            QQC2.Label {
                                id: emptyDayText

                                Layout.alignment: Qt.AlignVCenter
                                visible: !cardsColumn.visible
                                text: i18nc("Date has no events or tasks set", "Clear day.")
                                color: Kirigami.Theme.disabledTextColor
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

                                    onClicked: pathView.addIncidence(Kalendar.IncidenceWrapper.TypeEvent, periodStartDate)
                                }

                                Repeater {
                                    model: incidences
                                    Repeater {
                                        id: incidencesRepeater
                                        model: modelData

                                        Kirigami.AbstractCard {
                                            id: incidenceCard

                                            property real paddingSize: Kirigami.Settings.isMobile ?
                                                Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing
                                            property bool isOpenOccurrence: pathView.openOccurrence ?
                                                pathView.openOccurrence.incidenceId === modelData.incidenceId : false
                                            property bool multiday: modelData.startTime.getDate() !== modelData.endTime.getDate()
                                            property int incidenceDays: DateUtils.fullDaysBetweenDates(modelData.startTime, modelData.endTime)
                                            property int dayOfMultidayIncidence: DateUtils.fullDaysBetweenDates(modelData.startTime, periodStartDate)

                                            property alias mouseArea: incidenceMouseArea
                                            property var incidencePtr: modelData.incidencePtr
                                            property date occurrenceDate: modelData.startTime
                                            property date occurrenceEndDate: modelData.endTime
                                            property bool repositionAnimationEnabled: false
                                            property bool caught: false
                                            property real caughtX: 0
                                            property real caughtY: 0

                                            Drag.active: mouseArea.drag.active
                                            Drag.hotSpot.x: mouseArea.mouseX
                                            Drag.hotSpot.y: mouseArea.mouseY

                                            Layout.fillWidth: true
                                            topPadding: paddingSize
                                            bottomPadding: paddingSize

                                            showClickFeedback: true
                                            background: IncidenceDelegateBackground {
                                                id: incidenceDelegateBackground
                                                isOpenOccurrence: parent.isOpenOccurrence
                                                isDark: pathView.isDark
                                            }

                                            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }

                                            // Drag reposition animations -- when the incidence goes to the section of the view
                                            Behavior on x {
                                                enabled: repositionAnimationEnabled
                                                NumberAnimation {
                                                    duration: Kirigami.Units.shortDuration
                                                    easing.type: Easing.OutCubic
                                                }
                                            }

                                            Behavior on y {
                                                enabled: repositionAnimationEnabled
                                                NumberAnimation {
                                                    duration: Kirigami.Units.shortDuration
                                                    easing.type: Easing.OutCubic
                                                }
                                            }

                                            states: [
                                                State {
                                                    when: incidenceCard.mouseArea.drag.active
                                                    ParentChange { target: incidenceCard; parent: pathView }
                                                    PropertyChanges { target: incidenceCard; isOpenOccurrence: true }
                                                },
                                                State {
                                                    when: incidenceCard.caught
                                                    ParentChange { target: incidenceCard; parent: pathView }
                                                    PropertyChanges {
                                                        target: incidenceCard
                                                        repositionAnimationEnabled: true
                                                        x: caughtX
                                                        y: caughtY
                                                        opacity: 0
                                                    }
                                                }
                                            ]

                                            contentItem: GridLayout {
                                                id: cardContents

                                                columns: pathView.isLarge ? 3 : 2
                                                rows: pathView.isLarge ? 1 : 2

                                                property color textColor: LabelUtils.getIncidenceLabelColor(modelData.color, pathView.isDark)

                                                RowLayout {
                                                    Kirigami.Icon {
                                                        Layout.fillHeight: true
                                                        source: modelData.incidenceTypeIcon
                                                        isMask: true
                                                        color: incidenceCard.isOpenOccurrence ?
                                                            (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                            cardContents.textColor
                                                        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                                    }

                                                    QQC2.Label {
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        Layout.column: 0
                                                        Layout.row: 0
                                                        Layout.columnSpan: pathView.isLarge ? 2 : 1

                                                        color: incidenceCard.isOpenOccurrence ?
                                                            (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                            cardContents.textColor
                                                        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                                        text: {
                                                            if(incidenceCard.multiday) {
                                                                return i18nc("%1 is the name of the event", "%1 (Day %2 of %3)", modelData.text, incidenceCard.dayOfMultidayIncidence, incidenceCard.incidenceDays);
                                                            } else {
                                                                return modelData.text;
                                                            }
                                                        }
                                                        elide: Text.ElideRight
                                                        font.weight: Font.Medium
                                                        font.strikeout: modelData.todoCompleted
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
                                                        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                                        visible: modelData.recurs
                                                    }
                                                    Kirigami.Icon {
                                                        id: reminderIcon
                                                        Layout.fillHeight: true
                                                        source: "appointment-reminder"
                                                        isMask: true
                                                        color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                            cardContents.textColor
                                                        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                                        visible: modelData.hasReminders
                                                    }
                                                }


                                                QQC2.Label {
                                                    Layout.fillHeight: true
                                                    // This way all the icons are aligned
                                                    Layout.maximumWidth: pathView.maxTimeLabelWidth
                                                    Layout.minimumWidth: pathView.maxTimeLabelWidth
                                                    Layout.column: pathView.isLarge ? 2 : 0
                                                    Layout.row: pathView.isLarge ? 0 : 1

                                                    horizontalAlignment: pathView.isLarge ? Text.AlignRight : Text.AlignLeft
                                                    color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                        cardContents.textColor
                                                    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
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
                                                    Component.onCompleted: if(implicitWidth > pathView.maxTimeLabelWidth) pathView.maxTimeLabelWidth = implicitWidth
                                                }
                                            }

                                            IncidenceMouseArea {
                                                id: incidenceMouseArea

                                                preventStealing: !Kirigami.Settings.tabletMode && !Kirigami.Settings.isMobile
                                                incidenceData: modelData
                                                collectionId: modelData.collectionId

                                                drag.target: !Kirigami.Settings.isMobile && !modelData.isReadOnly && pathView.dragDropEnabled ? incidenceCard : undefined
                                                onReleased: incidenceCard.Drag.drop()

                                                onViewClicked: pathView.viewIncidence(modelData, incidenceCard)
                                                onEditClicked: pathView.editIncidence(incidencePtr)
                                                onDeleteClicked: pathView.deleteIncidence(incidencePtr, deleteDate)
                                                onTodoCompletedClicked: pathView.completeTodo(incidencePtr)
                                                onAddSubTodoClicked: pathView.addSubTodo(parentWrapper)
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
