// Copyright (C) 2018 Michael Bohlender, <bohlender@kolabsys.com>
// Copyright (C) 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar.calendar 1.0 as Calendar
import org.kde.kalendar.components 1.0
import '../components' as CalendarComponents

import "../dateutils.js" as DateUtils

Kirigami.Page {
    id: root

    property bool initialMonth: true
    property var openOccurrence: null
    property date currentDate: Navigation.currentDate
    property date firstDayOfMonth: DateUtils.getFirstDayOfMonth(currentDate)
    property date startDate: DateUtils.getFirstDayOfWeek(firstDayOfMonth)

    readonly property int month: firstDayOfMonth.getMonth()
    readonly property int year: firstDayOfMonth.getFullYear()

    property bool dragDropEnabled: true

    readonly property var dayGrid: {
        switch (Calendar.Config.monthGridMode) {
        case Calendar.Config.BasicMonthGrid:
            return basicViewLoader.item;
        case Calendar.Config.SwipeableMonthGrid:
        default:
            return swipeableViewLoader.item;
        }
    }

    readonly property Kirigami.Action previousAction: Kirigami.Action {
        icon.name: "go-previous"
        text: i18n("Previous Month")
        shortcut: StandardKey.MoveToPreviousPage
        onTriggered: setToDate(DateUtils.addMonthsToDate(root.firstDayOfMonth, -1))
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action nextAction: Kirigami.Action {
        icon.name: "go-next"
        text: i18n("Next Month")
        shortcut: StandardKey.MoveToNextPage
        onTriggered: setToDate(DateUtils.addMonthsToDate(root.firstDayOfMonth, 1))
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action todayAction: Kirigami.Action {
        icon.name: "go-jump-today"
        text: i18n("Today")
        shortcut: StandardKey.MoveToStartOfLine
        onTriggered: setToDate(new Date())
    }

    function setToDate(date, isInitialMonth = false) {
        initialMonth = isInitialMonth;
        dayGrid.setToDate(date);
    }

    onMonthChanged: if (month !== root.selectedDate.getMonth() && !initialMonth) {
        Navigation.selectedDate = new Date(year, month, 1);
    }

    onYearChanged: if (year !== root.selectedDate.getFullYear() && !initialMonth) {
        Navigation.selectedDate = new Date(year, month, 1);
    }

    actions.contextualActions: {
        Qt.application.layoutDirection === Qt.RightToLeft ? nextAction : previousAction,
        todayAction,
        Qt.application.layoutDirection === Qt.RightToLeft ? previousAction : nextAction,
        applicationWindow().createAction
    }

    padding: 0

    titleDelegate: CalendarComponents.ViewTitleDelegate {
        titleDateButton {
            date: root.firstDayOfMonth
            onClicked: dateChangeDrawer.active = !dateChangeDrawer.active
        }
    }

    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    Loader {
        id: dateChangeDrawer
        active: false
        visible: status === Loader.Ready

        onStatusChanged: if (status === Loader.Ready) {
            item.open();
        }

        sourceComponent: CalendarComponents.DateChanger {
            y: Navigation.pageStack.globalToolBar.height - 1
            showDays: false
            date: Navigation.selectedDate
            onDateSelected: if (visible) {
                root.setToDate(date);
                Navigation.selectedDate = date;
            }
        }
    }

    Loader {
        id: swipeableViewLoader
        anchors.fill: parent
        active: Calendar.Config.monthGridMode === Calendar.Config.SwipeableMonthGrid
        sourceComponent: SwipeableMonthGridView {
            anchors.fill: parent

            dragDropEnabled: root.dragDropEnabled
            currentDate: root.currentDate
            openOccurrence: root.openOccurrence

            onViewDatesChanged: {
                root.startDate = startDate;
                root.firstDayOfMonth = firstDayOfMonth;
            }
        }
    }

    Loader {
        id: basicViewLoader
        anchors.fill: parent
        active: Calendar.Config.monthGridMode === Calendar.Config.BasicMonthGrid
        sourceComponent: BasicMonthGridView {
            anchors.fill: parent

            dragDropEnabled: root.dragDropEnabled
            startDate: root.startDate
            currentDate: root.currentDate
            openOccurrence: root.openOccurrence

            onViewDatesChanged: {
                root.startDate = startDate;
                root.firstDayOfMonth = firstDayOfMonth;
            }
        }
    }
}

