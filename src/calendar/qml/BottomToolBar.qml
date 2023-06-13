// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2020 Han Young <hanyoung@protonmail.com>
// SPDX-FileCopyrightText: 2020-2021 Devin Lin <espidev@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick 2.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kalendar.components 1.0
import org.kde.kalendar.calendar 1.0 as Calendar

Kirigami.NavigationTabBar {
    actions: [
        KActionFromAction {
            action: Calendar.CalendarApplication.action("open_month_view")
            property string name: "monthView"
        },
        KActionFromAction {
            action: Calendar.CalendarApplication.action("open_threeday_view")
            property string name: "threeDayView"
        },
        KActionFromAction {
            action: Calendar.CalendarApplication.action("open_day_view")
            property string name: "dayView"
        },
        KActionFromAction {
            action: Calendar.CalendarApplication.action("open_schedule_view")
            property string name: "scheduleView"
        },
        KActionFromAction {
            action: Calendar.CalendarApplication.action("open_todo_view")
            property string name: "todoView"
        }
    ]
}
