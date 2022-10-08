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
    property int month: startDate.month()
    property int year: startDate.getFullYear()
    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 40
    readonly property bool isTiny: width < Kirigami.Units.gridUnit * 18
    readonly property int mode: Kalendar.KalendarApplication.Month

    property bool dragDropEnabled: true

    property alias dayGrid: swipeableViewLoader.item

    function setToDate(date, isInitialMonth = false) {
        dayGrid.setToDate(date, isInitialMonth);
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
    actions {
        left: Qt.application.layoutDirection === Qt.RightToLeft ? nextAction : previousAction
        right: Qt.application.layoutDirection === Qt.RightToLeft ? previousAction : nextAction
        main: todayAction
    }

    Loader {
        id: swipeableViewLoader
        anchors.fill: parent
        active: true
        sourceComponent: SwipeableMonthGridView {
            anchors.fill: parent

            initialMonth: monthPage.initialMonth
            isLarge: monthPage.isLarge
            isTiny: monthPage.isTiny
            dragDropEnabled: monthPage.dragDropEnabled
            currentDate: monthPage.currentDate
            openOccurrence: monthPage.openOccurrence

            onViewDatesChanged: {
                monthPage.startDate = startDate;
                monthPage.firstDayOfMonth = firstDayOfMonth;
                monthPage.month = month;
                monthPage.year = year;
            }
        }
    }

    Loader {
        id: basicViewLoader
        anchors.fill: parent
        active: false
        sourceComponent: BasicMonthGridView {
            anchors.fill: parent

            isLarge: monthPage.isLarge
            isTiny: monthPage.isTiny
            dragDropEnabled: monthPage.dragDropEnabled
            startDate: monthPage.startDate
            currentDate: monthPage.currentDate
            openOccurrence: monthPage.openOccurrence

            onViewDatesChanged: {
                monthPage.startDate = startDate;
                monthPage.firstDayOfMonth = firstDayOfMonth;
                monthPage.month = month;
                monthPage.year = year;
            }
        }
    }
}

