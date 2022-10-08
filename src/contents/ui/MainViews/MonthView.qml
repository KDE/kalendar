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

    property bool initialMonth: true
    property var openOccurrence: null
    property date currentDate: new Date()
    property date firstDayOfMonth: DateUtils.getFirstDayOfMonth(currentDate)
    property date startDate: DateUtils.getFirstDayOfWeek(firstDayOfMonth)

    readonly property int month: firstDayOfMonth.getMonth()
    readonly property int year: firstDayOfMonth.getFullYear()

    readonly property int mode: Kalendar.KalendarApplication.Month

    property bool dragDropEnabled: true

    readonly property var dayGrid: {
        switch (Kalendar.Config.monthGridMode) {
        case Kalendar.Config.BasicMonthGrid:
            return basicViewLoader.item;
        case Kalendar.Config.SwipeableMonthGrid:
        default:
            return swipeableViewLoader.item;
        }
    }

    readonly property Kirigami.Action previousAction: Kirigami.Action {
        icon.name: "go-previous"
        text: i18n("Previous Month")
        shortcut: StandardKey.MoveToPreviousPage
        onTriggered: setToDate(DateUtils.addMonthsToDate(monthPage.firstDayOfMonth, -1))
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action nextAction: Kirigami.Action {
        icon.name: "go-next"
        text: i18n("Next Month")
        shortcut: StandardKey.MoveToNextPage
        onTriggered: setToDate(DateUtils.addMonthsToDate(monthPage.firstDayOfMonth, 1))
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

    actions {
        left: Qt.application.layoutDirection === Qt.RightToLeft ? nextAction : previousAction
        right: Qt.application.layoutDirection === Qt.RightToLeft ? previousAction : nextAction
        main: todayAction
    }

    padding: 0

    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    Loader {
        id: swipeableViewLoader
        anchors.fill: parent
        active: Kalendar.Config.monthGridMode === Kalendar.Config.SwipeableMonthGrid
        sourceComponent: SwipeableMonthGridView {
            anchors.fill: parent

            dragDropEnabled: monthPage.dragDropEnabled
            currentDate: monthPage.currentDate
            openOccurrence: monthPage.openOccurrence

            onViewDatesChanged: {
                monthPage.startDate = startDate;
                monthPage.firstDayOfMonth = firstDayOfMonth;
            }
        }
    }

    Loader {
        id: basicViewLoader
        anchors.fill: parent
        active: Kalendar.Config.monthGridMode === Kalendar.Config.BasicMonthGrid
        sourceComponent: BasicMonthGridView {
            anchors.fill: parent

            dragDropEnabled: monthPage.dragDropEnabled
            startDate: monthPage.startDate
            currentDate: monthPage.currentDate
            openOccurrence: monthPage.openOccurrence

            onViewDatesChanged: {
                monthPage.startDate = startDate;
                monthPage.firstDayOfMonth = firstDayOfMonth;
            }
        }
    }
}

