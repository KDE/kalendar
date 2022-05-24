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
    signal viewIncidence(var modelData)
    signal editIncidence(var incidencePtr)
    signal deleteIncidence(var incidencePtr, date deleteDate)
    signal completeTodo(var incidencePtr)
    signal addSubTodo(var parentWrapper)
    signal deselect()
    signal moveIncidence(int startOffset, date occurrenceDate, var incidenceWrapper, Item caughtDelegate)
    signal openDayView(date selectedDate)

    property var openOccurrence
    property var model
    property date startDate
    property date currentDate
    property date firstDayOfMonth
    property int month
    property int year
    property bool initialMonth: true
    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 40
    readonly property bool isTiny: width < Kirigami.Units.gridUnit * 18
    readonly property int mode: Kalendar.KalendarApplication.Event

    property bool dragDropEnabled: true

    function setToDate(date, isInitialMonth = false) {
        monthPage.initialMonth = isInitialMonth;
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
    }

    padding: 0

    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    readonly property Kirigami.Action previousAction: Kirigami.Action {
        icon.name: "go-previous"
        text: i18n("Previous Month")
        shortcut: "Left"
        onTriggered: setToDate(DateUtils.addMonthsToDate(pathView.currentItem.firstDayOfMonth, -1))
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action nextAction: Kirigami.Action {
        icon.name: "go-next"
        text: i18n("Next Month")
        shortcut: "Right"
        onTriggered: setToDate(DateUtils.addMonthsToDate(pathView.currentItem.firstDayOfMonth, 1))
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action todayAction: Kirigami.Action {
        icon.name: "go-jump-today"
        text: i18n("Today")
        onTriggered: setToDate(new Date())
    }
    actions {
        left: Qt.application.layoutDirection === Qt.RightToLeft ? nextAction : previousAction
        right: Qt.application.layoutDirection === Qt.RightToLeft ? previousAction : nextAction
        main: todayAction
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

        model: monthPage.model

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
            property bool isCurrentItem: PathView.isCurrentItem

            active: isNextOrCurrentItem
            asynchronous: !isCurrentItem
            visible: status === Loader.Ready
            sourceComponent: DayGridView {
                id: dayView
                objectName: "monthView"
                width: pathView.width
                height: pathView.height
                model: monthViewModel // from monthPage model
                isCurrentView: viewLoader.isCurrentItem
                dragDropEnabled: monthPage.dragDropEnabled

                startDate: viewLoader.startDate
                currentDate: monthPage.currentDate
                month: viewLoader.month

                dayHeaderDelegate: QQC2.Control {
                    Layout.maximumHeight: Kirigami.Units.gridUnit * 2
                    contentItem: Kirigami.Heading {
                        text: {
                            let longText = day.toLocaleString(Qt.locale(), "dddd");
                            let midText = day.toLocaleString(Qt.locale(), "ddd");
                            let shortText = midText.slice(0,1);
                            switch(Kalendar.Config.weekdayLabelLength) {
                                case Kalendar.Config.Full:
                                    let chosenFormat = "dddd"
                                    return monthPage.isLarge ? longText : monthPage.isTiny ? shortText : midText;
                                case Kalendar.Config.Abbreviated:
                                    return monthPage.isTiny ? shortText : midText;
                                case Kalendar.Config.Letter:
                                default:
                                    return shortText;
                            }
                        }
                        level: 2
                        leftPadding: Kirigami.Units.smallSpacing
                        rightPadding: Kirigami.Units.smallSpacing
                        horizontalAlignment: {
                            switch(Kalendar.Config.weekdayLabelAlignment) {
                                case Kalendar.Config.Left:
                                    return Text.AlignLeft;
                                case Kalendar.Config.Center:
                                    return Text.AlignHCenter;
                                case Kalendar.Config.Right:
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
                onViewIncidence: monthPage.viewIncidence(modelData)
                onEditIncidence: monthPage.editIncidence(incidencePtr)
                onDeleteIncidence: monthPage.deleteIncidence(incidencePtr, deleteDate)
                onCompleteTodo: monthPage.completeTodo(incidencePtr)
                onAddSubTodo: monthPage.addSubTodo(parentWrapper)
                onDeselect: monthPage.deselect()
                onMoveIncidence: monthPage.moveIncidence(startOffset, occurrenceDate, incidenceWrapper, caughtDelegate)
                onOpenDayView: monthPage.openDayView(selectedDate)
            }
        }
    }
}

