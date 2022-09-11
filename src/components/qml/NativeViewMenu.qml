// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-3.0-or-later

import Qt.labs.platform 1.1 as Labs

import QtQuick 2.15
import QtQuick.Window 2.15
import org.kde.kalendar 1.0
import org.kde.kalendar.components 1.0

Labs.Menu {
    title: i18nc("@action:menu", "View")

    NativeMenuItemFromAction {
        kalendarAction: 'open_month_view'
    }

    NativeMenuItemFromAction {
        kalendarAction: 'open_week_view'
    }

    NativeMenuItemFromAction {
        kalendarAction: "open_threeday_view"
    }

    NativeMenuItemFromAction {
        kalendarAction: "open_day_view"
    }

    NativeMenuItemFromAction {
        kalendarAction: 'open_schedule_view'
    }

    NativeMenuItemFromAction {
        kalendarAction: 'open_todo_view'
    }

    NativeMenuItemFromAction {
        kalendarAction: 'open_contact_view'
    }

    NativeMenuItemFromAction {
        kalendarAction: 'open_kcommand_bar'
    }
}
