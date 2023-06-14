// SPDX-FileCopyrightText: 2021 Carson Black <uhhadd@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import Qt.labs.platform 1.1 as Labs

import QtQuick 2.15
import QtQuick.Window 2.15
import org.kde.kalendar.calendar 1.0
import org.kde.kalendar.components 1.0

Labs.MenuBar {
    id: bar

    NativeFileMenu {
        NativeMenuItemFromAction {
            action: CalendarApplication.action("import_calendar")
        }
    }

    NativeEditMenu {
        id: editMenu

        NativeMenuItemFromAction {
            action: CalendarApplication.action("edit_undo")
        }

        NativeMenuItemFromAction {
            action: CalendarApplication.action("edit_redo")
        }

        Labs.MenuSeparator {
        }
    }

    Labs.Menu {
        title: i18nc("@action:menu", "View")

        NativeMenuItemFromAction {
            action: CalendarApplication.action("open_month_view")
        }

        NativeMenuItemFromAction {
            action: CalendarApplication.action("open_week_view")
        }

        NativeMenuItemFromAction {
            action: CalendarApplication.action("open_threeday_view")
        }

        NativeMenuItemFromAction {
            action: CalendarApplication.action("open_day_view")
        }

        NativeMenuItemFromAction {
            action: CalendarApplication.action("open_schedule_view")
        }

        NativeMenuItemFromAction {
            action: CalendarApplication.action("open_todo_view")
        }

        NativeMenuItemFromAction {
            action: CalendarApplication.action("open_contact_view")
        }

        NativeMenuItemFromAction {
            action: CalendarApplication.action("open_kcommand_bar")
        }

        Labs.MenuSeparator {
        }

        Labs.Menu {
            title: i18nc("@action:menu", "Sort Tasks")
            enabled: mode === CalendarApplication.Todo

            NativeMenuItemFromAction {
                action: CalendarApplication.action("todoview_sort_by_due_date")
            }

            NativeMenuItemFromAction {
                action: CalendarApplication.action("todoview_sort_by_priority")
            }

            NativeMenuItemFromAction {
                action: CalendarApplication.action("todoview_sort_alphabetically")
            }

            Labs.MenuSeparator {
            }

            NativeMenuItemFromAction {
                action: CalendarApplication.action("todoview_order_ascending")
            }

            NativeMenuItemFromAction {
                action: CalendarApplication.action("todoview_order_descending")
            }
        }

        NativeMenuItemFromAction {
            action: CalendarApplication.action("todoview_show_completed")
            enabled: mode === CalendarApplication.Todo
        }

        Labs.MenuSeparator {
        }

        NativeMenuItemFromAction {
            text: i18n('Refresh All Calendars')
            action: CalendarApplication.action("refresh_all")
        }
    }

    Labs.Menu {
        title: i18nc("@action:menu", "Go")

        NativeMenuItemFromAction {
            action: CalendarApplication.action("move_view_backwards")
            enabled: mode & CalendarApplication.Event
        }
        NativeMenuItemFromAction {
            action: CalendarApplication.action("move_view_forwards")
            enabled: mode & CalendarApplication.Event
        }

        Labs.MenuSeparator {}

        NativeMenuItemFromAction {
            action: CalendarApplication.action("move_view_to_today")
            enabled: mode & CalendarApplication.Event
        }
        NativeMenuItemFromAction {
            action: CalendarApplication.action("open_date_changer")
            enabled: mode & CalendarApplication.Event
        }
    }

    Labs.Menu {
        title: i18nc("@action:menu", "Create")

        NativeMenuItemFromAction {
            action: CalendarApplication.action("create_event")
        }

        NativeMenuItemFromAction {
            action: CalendarApplication.action("create_todo")
        }
    }

    NativeWindowMenu {}

    Labs.Menu {
        title: i18nc("@action:menu", "Settings")

        NativeMenuItemFromAction {
            action: CalendarApplication.action('open_tag_manager')
        }

        Labs.MenuSeparator {}

        NativeMenuItemFromAction {
            action: CalendarApplication.action('options_configure_keybinding')
        }
        NativeMenuItemFromAction {
            action: CalendarApplication.action('options_configure')
        }
    }

    Labs.Menu {
        title: i18nc("@action:menu", "Help")

        NativeMenuItemFromAction {
            action: CalendarApplication.action("open_about_page")
        }

        NativeMenuItemFromAction {
            action: CalendarApplication.action("open_about_kde_page")
        }

        NativeMenuItemFromAction {
            text: i18nc("@action:menu", "Kalendar Handbook") // todo
            visible: false
        }
    }
}
