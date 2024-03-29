// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kalendar.calendar 1.0 as Calendar

RowLayout {
    id: root

    property alias titleDateButton: titleDateButton
    readonly property var openDateChangerAction: Calendar.CalendarApplication.action("open_date_changer")

    spacing: 0

    MainDrawerToggleButton {}

    TitleDateButton {
        id: titleDateButton

        onClicked: dateChangerLoader.active = !dateChangerLoader.active
    }

    Connections {
        target: Calendar.CalendarApplication

        function onOpenDateChanger() {
            dateChangerLoader.active = true;
        }
    }

    Loader {
        id: dateChangerLoader
        active: false
        visible: status === Loader.Ready
        onStatusChanged: if(status === Loader.Ready) item.open()
        sourceComponent: DateChanger {
            y: pageStack.globalToolBar.height - 1
            showDays: pageStack.currentItem && pageStack.currentItem.mode !== Calendar.CalendarApplication.MonthView
            date: Calendar.DateTimeState.selectedDate
            onDateSelected: if(visible) {
                Calendar.DateTimeState.selectedDate = date;
            }
        }
    }
}
