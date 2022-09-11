// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.10
import org.kde.kirigami 2.15 as Kirigami
import QtQuick.Window 2.15
import org.kde.kalendar 1.0
import org.kde.kalendar.components 1.0

QQC2.MenuBar {
    id: bar

    FileMenu {
        QQC2.MenuItem {
            action: KActionFromAction {
                kalendarAction: "import_calendar"
            }
        }
    }

    EditMenu {
        QQC2.MenuItem {
            action: KActionFromAction {
                kalendarAction: "edit_undo"
            }
        }

        QQC2.MenuItem {
            action: KActionFromAction {
                kalendarAction: "edit_redo"
            }
        }

        QQC2.MenuSeparator {
        }
    }

    ViewMenu {
        QQC2.MenuSeparator {
        }

        QQC2.Menu {
            title: i18n("Sort Tasks")
            enabled: applicationWindow().mode === KalendarApplication.Todo

            KActionFromAction {
                kalendarAction: "todoview_sort_by_due_date"
            }
            KActionFromAction {
                kalendarAction: "todoview_sort_by_priority"
            }
            KActionFromAction {
                kalendarAction: "todoview_sort_alphabetically"
            }

            QQC2.MenuSeparator {
            }

            KActionFromAction {
                kalendarAction: "todoview_order_ascending"
            }
            KActionFromAction {
                kalendarAction: "todoview_order_descending"
            }
        }

        KActionFromAction {
            kalendarAction: "todoview_show_completed"
            enabled: mode === KalendarApplication.Todo
        }

        QQC2.MenuSeparator {
        }

        KActionFromAction {
            text: i18n('Refresh All Calendars')
            kalendarAction: "refresh_all"
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Go")

        KActionFromAction {
            kalendarAction: "move_view_backwards"
            enabled: mode & KalendarApplication.Event
        }
        KActionFromAction {
            kalendarAction: "move_view_forwards"
            enabled: mode & KalendarApplication.Event
        }

        QQC2.MenuSeparator {}

        KActionFromAction {
            kalendarAction: "move_view_to_today"
            enabled: mode & KalendarApplication.Event
        }
        KActionFromAction {
            kalendarAction: "open_date_changer"
            enabled: mode & KalendarApplication.Event
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Create")

        KActionFromAction {
            kalendarAction: "create_event"
        }
        KActionFromAction {
            kalendarAction: "create_todo"
        }
    }

    WindowMenu {}

    SettingsMenu {}

    HelpMenu {}
}
