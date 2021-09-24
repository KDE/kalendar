// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2020 Han Young <hanyoung@protonmail.com>
// SPDX-FileCopyrightText: 2020-2021 Devin Lin <espidev@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick 2.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kalendar 1.0

Kirigami.NavigationTabBar {
    actions: [
        KActionFromAction {
            kalendarAction: "open_month_view"
            property string name: "monthView"
        },
        KActionFromAction {
            kalendarAction: "open_schedule_view"
            property string name: "scheduleView"
        },
        KActionFromAction {
            kalendarAction: "open_todo_view"
            property string name: "todoView"
        }
    ]
}
