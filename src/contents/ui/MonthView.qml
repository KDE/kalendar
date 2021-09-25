// Copyright (C) 2018 Michael Bohlender, <bohlender@kolabsys.com>
// Copyright (C) 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar

import "dateutils.js" as DateUtils

Kirigami.Page {
    id: monthPage

    signal addIncidence(int type, date addDate)
    signal viewIncidence(var modelData, var collectionData)
    signal editIncidence(var incidencePtr, var collectionId)
    signal deleteIncidence(var incidencePtr, date deleteDate)
    signal completeTodo(var incidencePtr)
    signal addSubTodo(var parentWrapper)

    property var openOccurrence
    property date startDate
    property date currentDate
    property date firstDayOfMonth
    property var calendarFilter
    property int month
    property int year
    property bool initialMonth: true
    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 40
    readonly property bool isTiny: width < Kirigami.Units.gridUnit * 18

    function setToDate(date, isInitialMonth = false) {
        monthPage.initialMonth = isInitialMonth;
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
    }

    padding: 0

    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
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

        property int startIndex
        Component.onCompleted: {
            startIndex = count / 2;
            currentIndex = startIndex;
        }
        onCurrentIndexChanged: {
            monthPage.startDate = currentItem.startDate;
            monthPage.firstDayOfMonth = currentItem.firstDayOfMonth;
            monthPage.month = currentItem.month;
            monthPage.year = currentItem.year;

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

            property bool isNextOrCurrentItem: index >= pathView.currentIndex -1 && index <= pathView.currentIndex + 1

            active: isNextOrCurrentItem
            //asynchronous: true
            sourceComponent: MultiDayView {
                id: dayView
                objectName: "monthView"
                width: pathView.width
                height: pathView.height
                loadModel: viewLoader.isNextOrCurrentItem

                startDate: model.startDate
                currentDate: monthPage.currentDate
                month: model.firstDay.getMonth()

                dayHeaderDelegate: QQC2.Control {
                    Layout.maximumHeight: Kirigami.Units.gridUnit * 2
                    contentItem: Kirigami.Heading {
                        text: {
                            let longText = day.toLocaleString(Qt.locale(), "dddd");
                            let midText = day.toLocaleString(Qt.locale(), "ddd");
                            let shortText = midText.slice(0,1);
                            switch(Kalendar.Config.weekdayLabelLength) { // HACK: Ideally should use config enum
                                case 0: // Full
                                    let chosenFormat = "dddd"
                                    return monthPage.isLarge ? longText : monthPage.isTiny ? shortText : midText;
                                case 1: // Abbr
                                    return monthPage.isTiny ? shortText : midText;
                                case 2: // Letter
                                default:
                                    return shortText;
                            }
                        }
                        level: 2
                        leftPadding: Kirigami.Units.smallSpacing
                        rightPadding: Kirigami.Units.smallSpacing
                        horizontalAlignment: {
                            switch(Kalendar.Config.weekdayLabelAlignment) { // HACK: Ideally should use config enum
                                case 0: // Left
                                    return Text.AlignLeft;
                                case 1: // Center
                                    return Text.AlignHCenter;
                                case 2: // Right
                                    return Text.AlignRight;
                                default:
                                    return Text.AlignHCenter;
                            }
                        }
                    }
                }

                weekHeaderDelegate: QQC2.Label {
                    padding: Kirigami.Units.smallSpacing
                    verticalAlignment: Qt.AlignTop
                    horizontalAlignment: Qt.AlignHCenter
                    text: DateUtils.getWeek(startDate, Qt.locale().firstDayOfWeek)
                    background: Rectangle {
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                        color: Kirigami.Theme.backgroundColor
                    }
                }

                openOccurrence: monthPage.openOccurrence

                onAddIncidence: monthPage.addIncidence(type, addDate)
                onViewIncidence: monthPage.viewIncidence(modelData, collectionData)
                onEditIncidence: monthPage.editIncidence(incidencePtr, collectionId)
                onDeleteIncidence: monthPage.deleteIncidence(incidencePtr, deleteDate)
                onCompleteTodo: monthPage.completeTodo(incidencePtr)
                onAddSubTodo: monthPage.addSubTodo(parentWrapper)
            }
        }
    }

    NavigationMouseArea {}
}

