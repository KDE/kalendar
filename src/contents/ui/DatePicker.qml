// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0 as Kalendar

Item {
    id: datepicker

    signal datePicked(date pickedDate)

    property date selectedDate: new Date() // Decides calendar span
    property date clickedDate: new Date() // User's chosen date
    property date today: new Date()
    property int year: selectedDate.getFullYear()
    property int month: selectedDate.getMonth()
    property int day: selectedDate.getDate()
    property bool showDays: true

    onSelectedDateChanged: setToDate(selectedDate)
    onShowDaysChanged: if (!showDays) pickerView.currentIndex = 1;

    function setToDate(date) {
        const yearDiff = date.getFullYear() - yearPathView.currentItem.startDate.getFullYear();
        // For the decadeDiff we add one to the input date year so that we use e.g. 2021, making the pathview move to the grid that contains the 2020 decade
        // instead of staying within the 2010 decade, which contains a 2020 cell at the very end
        const decadeDiff = Math.floor((date.getFullYear() + 1 - decadePathView.currentItem.startDate.getFullYear()) / 12); // 12 years in one decade grid

        let newYearIndex = yearPathView.currentIndex + yearDiff;
        let newDecadeIndex = decadePathView.currentIndex + decadeDiff;

        let firstYearItemDate = yearPathView.model.data(yearPathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
        let lastYearItemDate = yearPathView.model.data(yearPathView.model.index(yearPathView.model.rowCount() - 2,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
        let firstDecadeItemDate = decadePathView.model.data(decadePathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
        let lastDecadeItemDate = decadePathView.model.data(decadePathView.model.index(decadePathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);

        if(showDays) { // Set to correct index, including creating new dates in model if needed, for the month view
            const monthDiff = date.getMonth() - monthPathView.currentItem.firstDayOfMonth.getMonth() + (12 * (date.getFullYear() - monthPathView.currentItem.firstDayOfMonth.getFullYear()));
            let newMonthIndex = monthPathView.currentIndex + monthDiff;
            let firstMonthItemDate = monthPathView.model.data(monthPathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
            let lastMonthItemDate = monthPathView.model.data(monthPathView.model.index(monthPathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);

            while(firstMonthItemDate >= date) {
                monthPathView.model.addDates(false)
                firstMonthItemDate = monthPathView.model.data(monthPathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
                newMonthIndex = 0;
            }
            if(firstMonthItemDate < date && newMonthIndex === 0) {
                newMonthIndex = date.getMonth() - firstMonthItemDate.getMonth() + (12 * (date.getFullYear() - firstMonthItemDate.getFullYear())) + 1;
            }

            while(lastMonthItemDate <= date) {
                monthPathView.model.addDates(true)
                lastMonthItemDate = monthPathView.model.data(monthPathView.model.index(monthPathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
            }

            monthPathView.currentIndex = newMonthIndex;
        }

        // Set to index and create dates if needed for year view
        while(firstYearItemDate >= date) {
            yearPathView.model.addDates(false)
            firstYearItemDate = yearPathView.model.data(yearPathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
            newYearIndex = 0;
        }
        if(firstYearItemDate < date && newYearIndex === 0) {
            newYearIndex = date.getFullYear() - firstYearItemDate.getFullYear() + 1;
        }

        while(lastYearItemDate <= date) {
            yearPathView.model.addDates(true)
            lastYearItemDate = yearPathView.model.data(yearPathView.model.index(yearPathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
        }

        // Set to index and create dates if needed for decade view
        while(firstDecadeItemDate >= date) {
            decadePathView.model.addDates(false)
            firstDecadeItemDate = decadePathView.model.data(decadePathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
            newDecadeIndex = 0;
        }
        if(firstDecadeItemDate < date && newDecadeIndex === 0) {
            newDecadeIndex = date.getFullYear() - firstDecadeItemDate.getFullYear() + 1;
        }

        while(lastDecadeItemDate.getFullYear() <= date.getFullYear()) {
            decadePathView.model.addDates(true)
            lastDecadeItemDate = decadePathView.model.data(decadePathView.model.index(decadePathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
        }

        yearPathView.currentIndex = newYearIndex;
        decadePathView.currentIndex = newDecadeIndex;
    }

    function prevMonth() {
        selectedDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth() - 1, selectedDate.getDate())
    }

    function nextMonth() {
        selectedDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth() + 1, selectedDate.getDate())
    }

    function prevYear() {
        selectedDate = new Date(selectedDate.getFullYear() - 1, selectedDate.getMonth(), selectedDate.getDate())
    }

    function nextYear() {
        selectedDate = new Date(selectedDate.getFullYear() + 1, selectedDate.getMonth(), selectedDate.getDate())
    }

    function prevDecade() {
        selectedDate = new Date(selectedDate.getFullYear() - 10, selectedDate.getMonth(), selectedDate.getDate())
    }

    function nextDecade() {
        selectedDate = new Date(selectedDate.getFullYear() + 10, selectedDate.getMonth(), selectedDate.getDate())
    }

    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            id: headingRow
            Layout.fillWidth: true

            Kirigami.Heading {
                id: monthLabel
                Layout.fillWidth: true
                text: i18nc("%1 is month name, %2 is year", "%1 %2", Qt.locale().standaloneMonthName(selectedDate.getMonth()), String(selectedDate.getFullYear()))
                level: 1
            }
            QQC2.ToolButton {
                icon.name: 'go-previous-view'
                onClicked: {
                    if (pickerView.currentIndex == 1) { // monthGrid index
                        prevYear()
                    } else if (pickerView.currentIndex == 2) { // yearGrid index
                        prevDecade()
                    } else { // dayGrid index
                        prevMonth()
                    }
                }
            }
            QQC2.ToolButton {
                icon.name: 'go-jump-today'
                onClicked: selectedDate = new Date()
            }
            QQC2.ToolButton {
                icon.name: 'go-next-view'
                onClicked: {
                    if (pickerView.currentIndex == 1) { // monthGrid index
                        nextYear()
                    } else if (pickerView.currentIndex == 2) { // yearGrid index
                        nextDecade()
                    } else { // dayGrid index
                        nextMonth()
                    }
                }
            }
        }

        QQC2.TabBar {
            id: rangeBar
            currentIndex: pickerView.currentIndex
            Layout.fillWidth: true

            QQC2.TabButton {
                id: daysViewCheck
                Layout.fillWidth: true
                text: i18n("Days")
                onClicked: pickerView.currentIndex = 0 // dayGrid is first item in pickerView
                visible: datepicker.showDays
                width: visible ? implicitWidth : 0
            }
            QQC2.TabButton {
                id: monthsViewCheck
                Layout.fillWidth: true
                text: i18n("Months")
                onClicked: pickerView.currentIndex = 1
            }
            QQC2.TabButton {
                id: yearsViewCheck
                Layout.fillWidth: true
                text: i18n("Years")
                onClicked: pickerView.currentIndex = 2
            }
        }

        QQC2.SwipeView {
            id: pickerView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            interactive: false

            PathView {
                id: monthPathView

                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: Kirigami.Units.gridUnit * 16
                flickDeceleration: Kirigami.Units.longDuration
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                snapMode: PathView.SnapToItem
                focus: true
                interactive: Kirigami.Settings.tabletMode
                clip: true

                path: Path {
                    startX: - monthPathView.width * monthPathView.count / 2 + monthPathView.width / 2
                    startY: monthPathView.height / 2
                    PathLine {
                        x: monthPathView.width * monthPathView.count / 2 + monthPathView.width / 2
                        y: monthPathView.height / 2
                    }
                }

                model: Kalendar.InfiniteCalendarViewModel {
                    scale: Kalendar.InfiniteCalendarViewModel.MonthScale
                    datesToAdd: 300
                }

                property int startIndex
                Component.onCompleted: {
                    startIndex = count / 2;
                    currentIndex = startIndex;
                }
                onCurrentIndexChanged: {
                    if(pickerView.currentIndex == 0) {
                        datepicker.selectedDate = new Date(currentItem.firstDayOfMonth.getFullYear(), currentItem.firstDayOfMonth.getMonth(), datepicker.selectedDate.getDate());
                    }

                    if(currentIndex >= count - 2) {
                        model.addDates(true);
                    } else if (currentIndex <= 1) {
                        model.addDates(false);
                        startIndex += model.datesToAdd;
                    }
                }

                delegate: Loader {
                    id: monthViewLoader
                    property date firstDayOfMonth: model.firstDay
                    property bool isNextOrCurrentItem: index >= monthPathView.currentIndex -1 && index <= monthPathView.currentIndex + 1

                    active: isNextOrCurrentItem && datepicker.showDays

                    sourceComponent: GridLayout {
                        id: dayGrid
                        columns: 7
                        rows: 6
                        width: monthPathView.width
                        height: monthPathView.height
                        Layout.topMargin: Kirigami.Units.smallSpacing

                        property var model: Loader {
                            asynchronous: true
                            sourceComponent: Kalendar.MonthModel {
                                year: firstDay.getFullYear()
                                month: firstDay.getMonth() + 1 // From pathview model
                            }
                        }

                        QQC2.ButtonGroup {
                            buttons: dayGrid.children
                        }

                        Repeater {
                            model: dayGrid.model.weekDays
                            delegate: QQC2.Label {
                                Layout.fillWidth: true
                                height: dayGrid / dayGrid.rows
                                horizontalAlignment: Text.AlignHCenter
                                opacity: 0.7
                                text: modelData
                            }
                        }

                        Repeater {
                            model: dayGrid.model.item

                            delegate: QQC2.Button {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                flat: true
                                highlighted: model.isToday
                                checkable: true
                                checked: date.getDate() === clickedDate.getDate() &&
                                    date.getMonth() === clickedDate.getMonth() &&
                                    date.getFullYear() === clickedDate.getFullYear()
                                opacity: sameMonth ? 1 : 0.7
                                text: model.dayNumber
                                onClicked: datePicked(model.date), clickedDate = model.date
                            }
                        }
                    }
                }
            }

            PathView {
                id: yearPathView

                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: Kirigami.Units.gridUnit * 9
                flickDeceleration: Kirigami.Units.longDuration
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                snapMode: PathView.SnapToItem
                focus: true
                interactive: Kirigami.Settings.tabletMode
                clip: true

                path: Path {
                    startX: - yearPathView.width * yearPathView.count / 2 + yearPathView.width / 2
                    startY: yearPathView.height / 2
                    PathLine {
                        x: yearPathView.width * yearPathView.count / 2 + yearPathView.width / 2
                        y: yearPathView.height / 2
                    }
                }

                model: Kalendar.InfiniteCalendarViewModel {
                    scale: Kalendar.InfiniteCalendarViewModel.YearScale
                }

                property int startIndex
                Component.onCompleted: {
                    startIndex = count / 2;
                    currentIndex = startIndex;
                }
                onCurrentIndexChanged: {
                    if(pickerView.currentIndex == 1) {
                        datepicker.selectedDate = new Date(currentItem.startDate.getFullYear(), datepicker.selectedDate.getMonth(), datepicker.selectedDate.getDate())
                    }

                    if(currentIndex >= count - 2) {
                        model.addDates(true);
                    } else if (currentIndex <= 1) {
                        model.addDates(false);
                        startIndex += model.datesToAdd;
                    }
                }

                delegate: Loader {
                    id: yearViewLoader
                    property date startDate: model.startDate
                    property bool isNextOrCurrentItem: index >= yearPathView.currentIndex -1 && index <= yearPathView.currentIndex + 1

                    active: isNextOrCurrentItem

                    sourceComponent: GridLayout {
                        id: yearGrid
                        columns: 3
                        rows: 4
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.topMargin: Kirigami.Units.smallSpacing

                        QQC2.ButtonGroup {
                            buttons: yearGrid.children
                        }

                        Repeater {
                            model: yearGrid.columns * yearGrid.rows
                            delegate: QQC2.Button {
                                property date date: new Date(startDate.getFullYear(), index)
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                flat: true
                                highlighted: date.getMonth() === new Date().getMonth() &&
                                    date.getFullYear() === new Date().getFullYear()
                                checkable: true
                                checked: date.getMonth() === clickedDate.getMonth() &&
                                    date.getFullYear() === clickedDate.getFullYear()
                                text: Qt.locale().standaloneMonthName(date.getMonth())
                                onClicked: {
                                    selectedDate = new Date(date);
                                    clickedDate = new Date(date);
                                    datepicker.datePicked(date);
                                    if(datepicker.showDays) pickerView.currentIndex = 0;
                                }
                            }
                        }
                    }
                }
            }

            PathView {
                id: decadePathView

                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: Kirigami.Units.gridUnit * 9
                flickDeceleration: Kirigami.Units.longDuration
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                snapMode: PathView.SnapToItem
                focus: true
                interactive: Kirigami.Settings.tabletMode
                clip: true

                path: Path {
                    startX: - decadePathView.width * decadePathView.count / 2 + decadePathView.width / 2
                    startY: decadePathView.height / 2
                    PathLine {
                        x: decadePathView.width * decadePathView.count / 2 + decadePathView.width / 2
                        y: decadePathView.height / 2
                    }
                }

                model: Kalendar.InfiniteCalendarViewModel {
                    scale: Kalendar.InfiniteCalendarViewModel.DecadeScale
                }

                property int startIndex
                Component.onCompleted: {
                    startIndex = count / 2;
                    currentIndex = startIndex;
                }
                onCurrentIndexChanged: {
                    if(pickerView.currentIndex == 2) {
                        // getFullYear + 1 because the startDate is e.g. 2019, but we want the 2020 decade to be selected
                        datepicker.selectedDate = new Date(currentItem.startDate.getFullYear() + 1, datepicker.selectedDate.getMonth(), datepicker.selectedDate.getDate())
                    }

                    if(currentIndex >= count - 2) {
                        model.addDates(true);
                    } else if (currentIndex <= 1) {
                        model.addDates(false);
                        startIndex += model.datesToAdd;
                    }
                }

                delegate: Loader {
                    id: decadeViewLoader
                    property date startDate: model.startDate
                    property bool isNextOrCurrentItem: index >= decadePathView.currentIndex -1 && index <= decadePathView.currentIndex + 1

                    active: isNextOrCurrentItem

                    sourceComponent: GridLayout {
                        id: decadeGrid
                        columns: 3
                        rows: 4
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.topMargin: Kirigami.Units.smallSpacing

                        QQC2.ButtonGroup {
                            buttons: decadeGrid.children
                        }

                        Repeater {
                            model: decadeGrid.columns * decadeGrid.rows
                            delegate: QQC2.Button {
                                property date date: new Date(startDate.getFullYear() + index, 0)
                                property bool sameDecade: Math.floor(date.getFullYear() / 10) == Math.floor(year / 10)
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                flat: true
                                highlighted: date.getFullYear() === new Date().getFullYear()
                                checkable: true
                                checked: date.getFullYear() === clickedDate.getFullYear()
                                opacity: sameDecade ? 1 : 0.7
                                text: date.getFullYear()
                                onClicked: {
                                    selectedDate = new Date(date);
                                    clickedDate = new Date(date);
                                    datepicker.datePicked(date);
                                    pickerView.currentIndex = 1;
                                }


                            }
                        }
                    }
                }
            }
        }
    }
}



