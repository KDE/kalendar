// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import QtGraphicalEffects 1.12

import org.kde.kalendar.calendar 1.0 as Calendar
import org.kde.kalendar.components 1.0
import org.kde.kalendar.utils 1.0

Kirigami.Page {
    id: root
    objectName: switch(daysToShow) {
        case 1:
            return "dayView";
        case 3:
            return "threeDayView";
        case 7:
        default:
            return "weekView";
    }

    required property var openOccurrence

    property int daysToShow: 7
    property bool dragDropEnabled: true

    readonly property var mode: switch(daysToShow) {
        case 1:
            return Calendar.CalendarApplication.Day;
        case 3:
            return Calendar.CalendarApplication.ThreeDay;
        case 7:
        default:
            return Calendar.CalendarApplication.Week;
    }

    readonly property Kirigami.Action previousAction: Kirigami.Action {
        icon.name: "go-previous"
        text: i18n("Previous Week")
        shortcut: StandardKey.MoveToPreviousPage
        onTriggered: Calendar.DateTimeState.addDays(-root.daysToShow)
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action nextAction: Kirigami.Action {
        icon.name: "go-next"
        text: i18n("Next Week")office/klevernotes/-/merge_requests/7#note_699373
        shortcut: StandardKey.MoveToNextPage
        onTriggered: Calendar.DateTimeState.addDays(root.daysToShow)
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action todayAction: Kirigami.Action {
        icon.name: "go-jump-today"
        text: i18n("Now")
        shortcut: StandardKey.MoveToStartOfLine
        onTriggered: Calendar.DateTimeState.resetTime();
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

    titleDelegate: ViewTitleDelegate {
        titleDateButton {
            range: true
            lastDate: Calendar.Utils.addDaysToDate(Calendar.DateTimeState.selectedDate, root.daysToShow - 1)
        }

        Kirigami.ActionToolBar {
            id: weekViewScaleToggles
            Layout.preferredWidth: weekViewScaleToggles.maximumContentWidth
            Layout.leftMargin: Kirigami.Units.largeSpacing
            visible: !Kirigami.Settings.isMobile

            actions: [
                KActionFromAction {
                    action: Calendar.CalendarApplication.action("open_week_view")
                    text: i18nc("@action:inmenu open week view", "Week")
                    checkable: true
                    checked: pageStack.currentItem && pageStack.currentItem.mode === Calendar.CalendarApplication.Week
                    onTriggered: weekViewAction.trigger()
                },
                KActionFromAction {
                    action: Calendar.CalendarApplication.action("open_threeday_view")
                    text: i18nc("@action:inmenu open 3 days view", "3 Days")
                    checkable: true
                    checked: pageStack.currentItem && pageStack.currentItem.mode === Calendar.CalendarApplication.ThreeDay
                },
                KActionFromAction {
                    action: Calendar.CalendarApplication.action("open_day_view")
                    text: i18nc("@action:inmenu open day view", "Day")
                    checkable: true
                    checked: pageStack.currentItem && pageStack.currentItem.mode === Calendar.CalendarApplication.Day
                }
            ]
        }
    }

    Loader {
        id: swipeableViewLoader

        anchors.fill: parent
        active: Calendar.Config.hourlyViewMode === Calendar.Config.SwipeableInternalHourlyView

        sourceComponent: SwipeableInternalHourlyView {
            anchors.fill: parent

            daysToShow: root.daysToShow
            dragDropEnabled: root.dragDropEnabled
            openOccurrence: root.openOccurrence
        }
    }

    Loader {
        id: basicViewLoader

        anchors.fill: parent
        active: Calendar.Config.hourlyViewMode === Calendar.Config.BasicInternalHourlyView

        sourceComponent: BasicInternalHourlyView {
            anchors.fill: parent

            daysToShow: root.daysToShow
            dragDropEnabled: root.dragDropEnabled
            openOccurrence: root.openOccurrence
        }
    }
}
