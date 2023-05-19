// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
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

Kirigami.Page {
    id: root

    property var openOccurrence: ({})

    property date currentDate: new Date() // Needs to get updated for marker to move, done from main.qml
    property date startDate: DateUtils.getFirstDayOfWeek(currentDate)
    readonly property int day: startDate.getDate()
    readonly property int month: startDate.getMonth()
    readonly property int year: startDate.getFullYear()

    property bool initialWeek: true
    property int daysToShow: 7
    property bool dragDropEnabled: true

    readonly property var internalHourlyView: {
        switch (Kalendar.Config.hourlyViewMode) {
        case Kalendar.Config.BasicInternalHourlyView:
            return basicViewLoader.item;
        case Kalendar.Config.SwipeableInternalHourlyView:
        default:
            return swipeableViewLoader.item;
        }
    }

    readonly property var mode: switch(daysToShow) {
        case 1:
            return Kalendar.KalendarApplication.Day;
        case 3:
            return Kalendar.KalendarApplication.ThreeDay;
        case 7:
        default:
            return Kalendar.KalendarApplication.Week;
    }

    readonly property Kirigami.Action previousAction: Kirigami.Action {
        icon.name: "go-previous"
        text: i18n("Previous Week")
        shortcut: StandardKey.MoveToPreviousPage
        onTriggered: setToDate(DateUtils.addDaysToDate(root.startDate, -root.daysToShow))
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action nextAction: Kirigami.Action {
        icon.name: "go-next"
        text: i18n("Next Week")
        shortcut: StandardKey.MoveToNextPage
        onTriggered: setToDate(DateUtils.addDaysToDate(root.startDate, root.daysToShow))
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action todayAction: Kirigami.Action {
        icon.name: "go-jump-today"
        text: i18n("Now")
        shortcut: StandardKey.MoveToStartOfLine
        onTriggered: setToDate(new Date(), true, true);
    }

    function setToDate(date, isInitialWeek = false, animate = false) {
        initialWeek = isInitialWeek;
        internalHourlyView.setToDate(date, isInitialWeek, animate);
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
        active: Kalendar.Config.hourlyViewMode === Kalendar.Config.SwipeableInternalHourlyView
        sourceComponent: SwipeableInternalHourlyView {
            anchors.fill: parent

            daysToShow: root.daysToShow
            dragDropEnabled: root.dragDropEnabled
            startDate: root.startDate
            currentDate: root.currentDate
            openOccurrence: root.openOccurrence

            onStartDateChanged: root.startDate = startDate
        }
    }

    Loader {
        id: basicViewLoader
        anchors.fill: parent
        active: Kalendar.Config.hourlyViewMode === Kalendar.Config.BasicInternalHourlyView
        sourceComponent: BasicInternalHourlyView {
            anchors.fill: parent

            daysToShow: root.daysToShow
            dragDropEnabled: root.dragDropEnabled
            startDate: root.startDate
            currentDate: root.currentDate
            openOccurrence: root.openOccurrence

            onStartDateChanged: root.startDate = startDate
        }
    }
}
