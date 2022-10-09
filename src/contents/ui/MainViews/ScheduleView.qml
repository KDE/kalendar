// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar 1.0 as Kalendar
import org.kde.kalendar.utils 1.0
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Kirigami.Page {
    id: root

    property bool initialMonth: true
    property var openOccurrence
    property date currentDate: new Date()
    property date startDate: DateUtils.getFirstDayOfMonth(currentDate)

    readonly property int month: startDate.getMonth()
    readonly property int year: startDate.getFullYear()

    property bool dragDropEnabled: true
    readonly property int mode: Kalendar.KalendarApplication.Schedule

    readonly property var dayList: {
        switch (Kalendar.Config.monthListMode) {
        case Kalendar.Config.BasicMonthList:
            return basicViewLoader.item;
        case Kalendar.Config.SwipeableMonthList:
        default:
            return swipeableViewLoader.item;
        }
    }

    readonly property Kirigami.Action previousAction: Kirigami.Action {
        icon.name: "go-previous"
        text: i18n("Previous Month")
        shortcut: StandardKey.MoveToPreviousPage
        onTriggered: setToDate(DateUtils.addMonthsToDate(startDate, -1))
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action nextAction: Kirigami.Action {
        icon.name: "go-next"
        text: i18n("Next Month")
        shortcut: StandardKey.MoveToNextPage
        onTriggered: setToDate(DateUtils.addMonthsToDate(startDate, 1))
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action todayAction: Kirigami.Action {
        icon.name: "go-jump-today"
        text: i18n("Today")
        shortcut: StandardKey.MoveToStartOfLine
        onTriggered: setToDate(new Date(), true)
    }

    function setToDate(date, isInitialMonth = false) {
        initialMonth = isInitialMonth;
        dayList.setToDate(date, isInitialMonth);
    }

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
    }

    actions {
        left: Qt.application.layoutDirection === Qt.RightToLeft ? nextAction : previousAction
        right: Qt.application.layoutDirection === Qt.RightToLeft ? previousAction : nextAction
        main: todayAction
    }

    padding: 0

    Loader {
        id: swipeableViewLoader
        anchors.fill: parent
        active: Kalendar.Config.monthListMode === Kalendar.Config.SwipeableMonthList
        sourceComponent: SwipeableMonthListView {
            anchors.fill: parent
            initialMonth: root.initialMonth
            openOccurrence: root.openOccurrence
            currentDate: root.currentDate
            startDate: root.startDate
            dragDropEnabled: root.dragDropEnabled

            onStartDateChanged: root.startDate = startDate
        }
    }

    Loader {
        id: basicViewLoader
        anchors.fill: parent
        active: Kalendar.Config.monthListMode === Kalendar.Config.BasicMonthList
        sourceComponent: BasicMonthListView {
            anchors.fill: parent
            initialMonth: root.initialMonth
            openOccurrence: root.openOccurrence
            currentDate: root.currentDate
            startDate: root.startDate
            dragDropEnabled: root.dragDropEnabled

            onStartDateChanged: root.startDate = startDate
        }
    }
}
