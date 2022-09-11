// SPDX-FileCopyrightText: 2021 Carson Black <uhhadd@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import Qt.labs.platform 1.1 as Labs

import QtQuick 2.15
import QtQuick.Window 2.15
import org.kde.kalendar 1.0
import org.kde.kalendar.components 1.0

Labs.MenuBar {
    id: bar

    NativeFileMenu {
        NativeMenuItemFromAction {
            kalendarAction: 'import_calendar'
        }
    }

    NativeEditMenu {
        id: editMenu

        NativeMenuItemFromAction {
            kalendarAction: 'edit_undo'
        }

        NativeMenuItemFromAction {
            kalendarAction: 'edit_redo'
        }

        Labs.MenuSeparator {
        }
    }

    NativeViewMenu {
        Labs.MenuSeparator {
        }

        Labs.Menu {
            title: i18nc("@action:menu", "Sort Tasks")
            enabled: mode === KalendarApplication.Todo

            NativeMenuItemFromAction {
                kalendarAction: 'todoview_sort_by_due_date'
            }

            NativeMenuItemFromAction {
                kalendarAction: 'todoview_sort_by_priority'
            }

            NativeMenuItemFromAction {
                kalendarAction: 'todoview_sort_alphabetically'
            }

            Labs.MenuSeparator {
            }

            NativeMenuItemFromAction {
                kalendarAction: 'todoview_order_ascending'
            }

            NativeMenuItemFromAction {
                kalendarAction: 'todoview_order_descending'
            }
        }

        NativeMenuItemFromAction {
            kalendarAction: 'todoview_show_completed'
            enabled: mode === KalendarApplication.Todo
        }

        Labs.MenuSeparator {
        }

        NativeMenuItemFromAction {
            text: i18n('Refresh All Calendars')
            kalendarAction: "refresh_all"
        }
    }

    Labs.Menu {
        title: i18nc("@action:menu", "Go")

        NativeMenuItemFromAction {
            kalendarAction: "move_view_backwards"
            enabled: mode & KalendarApplication.Event
        }
        NativeMenuItemFromAction {
            kalendarAction: "move_view_forwards"
            enabled: mode & KalendarApplication.Event
        }

        Labs.MenuSeparator {}

        NativeMenuItemFromAction {
            kalendarAction: "move_view_to_today"
            enabled: mode & KalendarApplication.Event
        }
        NativeMenuItemFromAction {
            kalendarAction: "open_date_changer"
            enabled: mode & KalendarApplication.Event
        }
    }

    Labs.Menu {
        title: i18nc("@action:menu", "Create")

        NativeMenuItemFromAction {
            kalendarAction: 'create_event'
        }

        NativeMenuItemFromAction {
            kalendarAction: 'create_todo'
        }
    }

    NativeWindowMenu {}

    NativeSettingsMenu {}

    NativeHelpMenu {}
}
