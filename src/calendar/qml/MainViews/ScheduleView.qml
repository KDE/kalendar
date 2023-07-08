// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar.calendar 1.0 as Calendar
import org.kde.kalendar.utils 1.0

Kirigami.Page {
    id: root

    required property QQC2.Action createEventAction
    property bool initialMonth: true
    property var openOccurrence

    property bool dragDropEnabled: true
    readonly property int mode: Calendar.CalendarApplication.Schedule

    readonly property Kirigami.Action previousAction: Kirigami.Action {
        icon.name: "go-previous"
        text: i18n("Previous Month")
        shortcut: StandardKey.MoveToPreviousPage
        onTriggered: Calendar.DateTimeState.selectPreviousMonth()
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action nextAction: Kirigami.Action {
        icon.name: "go-next"
        text: i18n("Next Month")
        shortcut: StandardKey.MoveToNextPage
        onTriggered: Calendar.DateTimeState.selectNextMonth()
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action todayAction: Kirigami.Action {
        icon.name: "go-jump-today"
        text: i18n("Today")
        shortcut: StandardKey.MoveToStartOfLine
        onTriggered: Calendar.DateTimeState.resetTime();
    }

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    titleDelegate: ViewTitleDelegate {}

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
    }

    actions: [previousAction, nextAction, todayAction]

    padding: 0

    Loader {
        id: swipeableViewLoader
        anchors.fill: parent
        active: Calendar.Config.monthListMode === Calendar.Config.SwipeableMonthList
        sourceComponent: SwipeableMonthListView {
            anchors.fill: parent

            openOccurrence: root.openOccurrence
            dragDropEnabled: root.dragDropEnabled
        }
    }

    Loader {
        id: basicViewLoader
        anchors.fill: parent
        active: Calendar.Config.monthListMode === Calendar.Config.BasicMonthList
        sourceComponent: BasicMonthListView {
            anchors.fill: parent
            openOccurrence: root.openOccurrence
            dragDropEnabled: root.dragDropEnabled
            isCurrentItem: true
        }
    }
}
