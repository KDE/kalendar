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

    signal viewDatesChanged(date startDate, date firstDayOfMonth)

    property bool dragDropEnabled: true
    property date currentDate: new Date()
    property date startDate: DateUtils.getFirstDayOfWeek(DateUtils.getFirstDayOfMonth(currentDate))
    property var openOccurrence: null

    function setToDate(date) {
        let monthDiff = date.getMonth() - currentItem.firstDayOfMonth.getMonth() + (12 * (date.getFullYear() - currentItem.firstDayOfMonth.getFullYear()))
        let newIndex = currentIndex + monthDiff;

        let firstItemDate = model.data(model.index(1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
        let lastItemDate = model.data(model.index(model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);

        while(firstItemDate >= date) {
            model.addDates(false)
            firstItemDate = model.data(model.index(1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
            newIndex = 0;
        }
        if(firstItemDate < date && newIndex === 0) {
            newIndex = date.getMonth() - firstItemDate.getMonth() + (12 * (date.getFullYear() - firstItemDate.getFullYear())) + 1;
        }

        while(lastItemDate <= date) {
            model.addDates(true)
            lastItemDate = model.data(model.index(model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
        }
        currentIndex = newIndex;

        viewDatesChanged(currentItem.startDate, currentItem.firstDayOfMonth);
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
        if(currentIndex >= count - 2) {
            model.addDates(true);
        } else if (currentIndex <= 1) {
            model.addDates(false);
            startIndex += model.datesToAdd;
        }
    }

    delegate: Loader {
        id: viewLoader

        readonly property date startDate: model.startDate
        readonly property date firstDayOfMonth: model.firstDay
        readonly property int month: model.selectedMonth - 1 // Convert QDateTime month to JS month
        readonly property int year: model.selectedYear

        readonly property bool isNextOrCurrentItem: index >= pathView.currentIndex -1 && index <= pathView.currentIndex + 1
        readonly property bool isCurrentItem: PathView.isCurrentItem

        active: isNextOrCurrentItem
        asynchronous: !isCurrentItem
        visible: status === Loader.Ready
        sourceComponent: BasicMonthGridView {
            width: pathView.width
            height: pathView.height

            isCurrentView: viewLoader.isCurrentItem
            dragDropEnabled: pathView.dragDropEnabled

            startDate: viewLoader.startDate
            firstDayOfMonth: viewLoader.firstDayOfMonth
            currentDate: pathView.currentDate

            openOccurrence: pathView.openOccurrence
        }
    }
}

