// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import QtGraphicalEffects 1.12

import org.kde.kalendar 1.0 as Kalendar
import org.kde.kalendar.utils 1.0
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

PathView {
    id: pathView

    property var openOccurrence: ({})

    property date currentDate: new Date() // Needs to get updated for marker to move, done from main.qml
    property date startDate: DateUtils.getFirstDayOfWeek(currentDate)

    property int daysToShow: 7
    property bool dragDropEnabled: true

    function setToDate(date, isInitialWeek = false, animate = false) {
        if(!pathView.currentItem) {
            return;
        }

        if(daysToShow % 7 === 0) {
            date = DateUtils.getFirstDayOfWeek(date);
        }

        startDate = date;

        const weekDiff = Math.round((date.getTime() - pathView.currentItem.startDate.getTime()) / (daysToShow * 24 * 60 * 60 * 1000));

        let position = pathView.currentItem.item.hourScrollView.getCurrentPosition();
        let newIndex = pathView.currentIndex + weekDiff;
        let firstItemDate = pathView.model.data(pathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
        let lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);

        while(firstItemDate >= date) {
            pathView.model.addDates(false)
            firstItemDate = pathView.model.data(pathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
            newIndex = 0;
        }
        if(firstItemDate < date && newIndex === 0) {
            newIndex = Math.round((date - firstItemDate) / (daysToShow * 24 * 60 * 60 * 1000)) + 1
        }

        while(lastItemDate <= date) {
            pathView.model.addDates(true)
            lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
        }
        pathView.currentIndex = newIndex;

        if(isInitialWeek) {
            pathView.currentItem.item.hourScrollView.setToCurrentTime(animate);
        } else {
            pathView.currentItem.item.hourScrollView.setPosition(position);
        }
    }

    flickDeceleration: Kirigami.Units.longDuration
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange
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

    Component {
        id: weekModel
        Kalendar.InfiniteCalendarViewModel {
            scale: Kalendar.InfiniteCalendarViewModel.WeekScale
        }
    }

    Component {
        id: threeDayModel
        Kalendar.InfiniteCalendarViewModel {
            scale: Kalendar.InfiniteCalendarViewModel.ThreeDayScale
        }
    }

    Component {
        id: dayModel
        Kalendar.InfiniteCalendarViewModel {
            scale: Kalendar.InfiniteCalendarViewModel.DayScale
        }
    }

    Loader {
        id: modelLoader
        sourceComponent: switch(pathView.daysToShow) {
                         case 1:
                             return dayModel;
                         case 3:
                             return threeDayModel;
                         case 7:
                         default:
                             return weekModel;
                         }
    }

    model: modelLoader.item

    property real scrollPosition
    onMovementStarted: {
        scrollPosition = pathView.currentItem.item.hourScrollView.getCurrentPosition();
    }

    onMovementEnded: {
        pathView.currentItem.item.hourScrollView.setPosition(scrollPosition);
    }

    property date dateToUse
    property int startIndex: count / 2;
    currentIndex: startIndex
    onCurrentIndexChanged: if(currentItem) {
        if(currentIndex >= count - 2) {
            model.addDates(true);
        } else if (currentIndex <= 1) {
            model.addDates(false);
            startIndex += model.weeksToAdd;
        }
    }

    delegate: Loader {
        id: viewLoader

        readonly property date startDate: model.startDate
        readonly property date endDate: DateUtils.addDaysToDate(model.startDate, pathView.daysToShow)

        readonly property int index: model.index
        readonly property bool isCurrentItem: PathView.isCurrentItem
        readonly property bool isNextOrCurrentItem: index >= pathView.currentIndex -1 && index <= pathView.currentIndex + 1
        property int multiDayLinesShown: 0

        active: isNextOrCurrentItem
        asynchronous: !isCurrentItem
        visible: status === Loader.Ready

        sourceComponent: BasicInternalHourlyView {
            width: pathView.width
            height: pathView.height

            openOccurrence: pathView.openOccurrence
            daysToShow: pathView.daysToShow
            currentDate: pathView.currentDate
            startDate: viewLoader.startDate
            dragDropEnabled: pathView.dragDropEnabled
            isCurrentItem: viewLoader.isCurrentItem
            // Not a model role but instead one of the model object's properties
            hourLabels: pathView.model.hourlyViewLocalisedLabels
        }
    }
}
