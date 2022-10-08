// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar

import "dateutils.js" as DateUtils

PathView {
    id: pathView

    signal viewDatesChanged(date startDate, date firstDayOfMonth, int month, int year)

    property bool initialMonth: true
    property bool isLarge: true
    property bool isTiny: false
    property bool dragDropEnabled: true
    property date currentDate: new Date()
    property var openOccurrence: null

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

    property int startIndex
    Component.onCompleted: {
        startIndex = count / 2;
        currentIndex = startIndex;
    }
    onCurrentIndexChanged: {
        pathView.viewDatesChanged(currentItem.startDate, currentItem.firstDayOfMonth, currentItem.month, currentItem.year);

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
            isCurrentView: viewLoader.isCurrentItem
            dragDropEnabled: pathView.dragDropEnabled

            startDate: viewLoader.startDate
            currentDate: pathView.currentDate
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
                                return pathView.isLarge ? longText : pathView.isTiny ? shortText : midText;
                            case Kalendar.Config.Abbreviated:
                                return pathView.isTiny ? shortText : midText;
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

            openOccurrence: pathView.openOccurrence
        }
    }
}

