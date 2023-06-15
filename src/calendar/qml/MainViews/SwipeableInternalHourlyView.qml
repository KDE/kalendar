// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import QtGraphicalEffects 1.12

import org.kde.kalendar.calendar 1.0 as Calendar
import org.kde.kalendar.utils 1.0

PathView {
    id: root

    required property var openOccurrence
    required property int daysToShow
    required property bool dragDropEnabled
    property real scrollPosition

    readonly property date selectedDate: if (daysToShow === 7) {
        Calendar.DateTimeState.firstDayOfWeek
    } else {
        Calendar.DateTimeState.selectedDate
    }

    property bool initialWeek: true

    onSelectedDateChanged: {
        if (!root.currentItem) {
            return;
        }

        let position = root.currentItem.item.hourScrollView.getCurrentPosition();
        root.currentIndex = root.model.moveToDate(root.selectedDate, root.currentItem.startDate, root.currentIndex);

        if (initialWeek) {
            root.currentItem.item.hourScrollView.setToCurrentTime(true);
            initialWeek = false;
        } else {
            root.currentItem.item.hourScrollView.setPosition(position);
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
        startX: - root.width * root.pathItemCount / 2 + root.width / 2
        startY: root.height / 2
        PathLine {
            x: root.width * root.pathItemCount / 2 + root.width / 2
            y: root.height / 2
        }
    }

    model: Calendar.InfiniteCalendarViewModel {
        scale: switch(root.daysToShow) {
        case 1:
            return Calendar.InfiniteCalendarViewModel.DayScale;
        case 3:
            return Calendar.InfiniteCalendarViewModel.ThreeDayScale;
        case 7:
        default:
            return Calendar.InfiniteCalendarViewModel.WeekScale;
        }
    }

    onMovementStarted: scrollPosition = root.currentItem.item.hourScrollView.getCurrentPosition();
    onMovementEnded: root.currentItem.item.hourScrollView.setPosition(scrollPosition);

    Component.onCompleted: currentIndex = count / 2;
    onCurrentIndexChanged: if(currentIndex >= count - 2) {
        model.addDates(true);
    } else if (currentIndex <= 1) {
        model.addDates(false);
    }

    delegate: Loader {
        id: viewLoader

        required property int index
        required property date startDate

        readonly property date endDate: Calendar.Utils.addDaysToDate(startDate, root.daysToShow)

        readonly property bool isCurrentItem: PathView.isCurrentItem
        readonly property bool isNextOrCurrentItem: index >= root.currentIndex -1 && index <= root.currentIndex + 1
        property int multiDayLinesShown: 0

        active: isNextOrCurrentItem
        asynchronous: !isCurrentItem
        visible: status === Loader.Ready

        sourceComponent: BasicInternalHourlyView {
            width: root.width
            height: root.height

            openOccurrence: root.openOccurrence
            daysToShow: root.daysToShow
            startDate: viewLoader.startDate
            dragDropEnabled: root.dragDropEnabled
            isCurrentItem: viewLoader.isCurrentItem
            // Not a model role but instead one of the model object's properties
            hourLabels: root.model.hourlyViewLocalisedLabels
        }
    }
}
