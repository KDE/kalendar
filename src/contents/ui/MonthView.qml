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
    property date currentDate
    property var filter: {
        "tags": []
    }
    property date firstDayOfMonth
    property bool initialMonth: true
    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 40
    readonly property bool isTiny: width < Kirigami.Units.gridUnit * 18
    property int month
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
    property date startDate
    readonly property Kirigami.Action todayAction: Kirigami.Action {
        icon.name: "go-jump-today"
        text: i18n("Today")

        onTriggered: setToDate(new Date())
    }
    property int year

    padding: 0

    signal addIncidence(int type, date addDate)
    signal addSubTodo(var parentWrapper)
    signal completeTodo(var incidencePtr)
    signal deleteIncidence(var incidencePtr, date deleteDate)
    signal deselect
    signal editIncidence(var incidencePtr, var collectionId)
    function setToDate(date, isInitialMonth = false) {
        monthPage.initialMonth = isInitialMonth;
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
    }
    signal viewIncidence(var modelData, var collectionData)

    actions {
        left: Qt.application.layoutDirection === Qt.RightToLeft ? nextAction : previousAction
        main: todayAction
        right: Qt.application.layoutDirection === Qt.RightToLeft ? previousAction : nextAction
    }
    PathView {
        id: pathView
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
            monthPage.startDate = currentItem.startDate;
            monthPage.firstDayOfMonth = currentItem.firstDayOfMonth;
            monthPage.month = currentItem.month;
            monthPage.year = currentItem.year;
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
            property bool isNextOrCurrentItem: index >= pathView.currentIndex - 1 && index <= pathView.currentIndex + 1
            property int month: model.selectedMonth - 1 // Convert QDateTime month to JS month
            property date startDate: model.startDate
            property int year: model.selectedYear

            active: isNextOrCurrentItem

            //asynchronous: true
            sourceComponent: MultiDayView {
                id: dayView
                currentDate: monthPage.currentDate
                filter: monthPage.filter
                height: pathView.height
                loadModel: viewLoader.isNextOrCurrentItem
                month: model.firstDay.getMonth()
                objectName: "monthView"
                openOccurrence: monthPage.openOccurrence
                startDate: model.startDate
                width: pathView.width

                onAddIncidence: monthPage.addIncidence(type, addDate)
                onAddSubTodo: monthPage.addSubTodo(parentWrapper)
                onCompleteTodo: monthPage.completeTodo(incidencePtr)
                onDeleteIncidence: monthPage.deleteIncidence(incidencePtr, deleteDate)
                onDeselect: monthPage.deselect()
                onEditIncidence: monthPage.editIncidence(incidencePtr, collectionId)
                onViewIncidence: monthPage.viewIncidence(modelData, collectionData)

                dayHeaderDelegate: QQC2.Control {
                    Layout.maximumHeight: Kirigami.Units.gridUnit * 2

                    contentItem: Kirigami.Heading {
                        horizontalAlignment: {
                            switch (Kalendar.Config.weekdayLabelAlignment) {
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
                        leftPadding: Kirigami.Units.smallSpacing
                        level: 2
                        rightPadding: Kirigami.Units.smallSpacing
                        text: {
                            let longText = day.toLocaleString(Qt.locale(), "dddd");
                            let midText = day.toLocaleString(Qt.locale(), "ddd");
                            let shortText = midText.slice(0, 1);
                            switch (Kalendar.Config.weekdayLabelLength) {
                            case Kalendar.Config.Full:
                                let chosenFormat = "dddd";
                                return monthPage.isLarge ? longText : monthPage.isTiny ? shortText : midText;
                            case Kalendar.Config.Abbreviated:
                                return monthPage.isTiny ? shortText : midText;
                            case Kalendar.Config.Letter:
                            default:
                                return shortText;
                            }
                        }
                    }
                }
                weekHeaderDelegate: QQC2.Label {
                    horizontalAlignment: Qt.AlignHCenter
                    padding: Kirigami.Units.smallSpacing
                    text: DateUtils.getWeek(startDate, Qt.locale().firstDayOfWeek)
                    verticalAlignment: Qt.AlignTop

                    background: Rectangle {
                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                        Kirigami.Theme.inherit: false
                        color: Kirigami.Theme.backgroundColor
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
