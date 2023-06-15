// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15

RowLayout {
    id: root

    property alias titleDateButton: titleDataButton

    spacing: 0

    MainDrawerToggleButton {}

    TitleDateButton {
        id: titleDataButton

        onClicked: dateChangerLoader.active = !dateChangerLoader.active
    }

    Loader {
        id: dateChangerLoader
        active: false
        visible: status === Loader.Ready
        onStatusChanged: if(status === Loader.Ready) item.open()
        sourceComponent: DateChanger {
            y: pageStack.globalToolBar.height - 1
            showDays: pageStack.currentItem && pageStack.currentItem.mode !== CalendarApplication.MonthView
            date: DateTimeState.selectedDate
            onDateSelected: if(visible) {
                pageStack.currentItem.setToDate(date);
                DateTimeState.selectedDate = date;
            }
        }
    }
}
