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
    property var parentWindow: null
    property int mode: KalendarApplication.Event

    QQC2.Menu {
        title: i18nc("@action:menu", "File")

        KActionFromAction {
            kalendarAction: "import_calendar"
        }

        Kirigami.Action {
            text: i18nc("@action:menu", "Quit Kalendar")
            icon.name: "application-exit"
            shortcut: StandardKey.Quit
            onTriggered: Qt.quit()
        }
    }
    QQC2.Menu {
        id: editMenu
        title: i18nc("@action:menu", "Edit")
        Connections {
            target: parentWindow
            function onActiveFocusItemChanged() {
                if (parentWindow.activeFocusItem instanceof TextEdit || parentWindow.activeFocusItem instanceof TextInput) {
                    editMenu.field = parentWindow.activeFocusItem;
                }
            }
        }
        field: null

        required property Item field

        KActionFromAction {
            kalendarAction: "edit_undo"
        }

        KActionFromAction {
            kalendarAction: "edit_redo"
        }

        QQC2.MenuSeparator {
        }

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canUndo
            text: i18nc("text editing menu action", "Undo Text")
            onTriggered: {
                editMenu.field.undo()
                editMenu.close()
            }
        }

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canRedo
            text: i18nc("text editing menu action", "Redo Text")
            onTriggered: {
                editMenu.field.undo()
                editMenu.close()
            }
        }

        QQC2.MenuSeparator {
        }

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText
            text: i18nc("text editing menu action", "Cut")
            onTriggered: {
                editMenu.field.cut()
                editMenu.close()
            }
        }

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText
            text: i18nc("text editing menu action", "Copy")
            onTriggered: {
                editMenu.field.copy()
                editMenu.close()
            }
        }

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canPaste
            text: i18nc("text editing menu action", "Paste")
            onTriggered: {
                editMenu.field.paste()
                editMenu.close()
            }
        }

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText !== ""
            text: i18nc("text editing menu action", "Delete")
            onTriggered: {
                editMenu.field.remove(editMenu.field.selectionStart, editMenu.field.selectionEnd)
                editMenu.close()
            }
        }

        QQC2.MenuSeparator {
        }

        QQC2.MenuItem {
            enabled: editMenu.field !== null
            text: i18nc("text editing menu action", "Select All")
            onTriggered: {
                editMenu.field.selectAll()
                editMenu.close()
            }
        }
    }
    QQC2.Menu {
        title: i18nc("@action:menu", "View")

        KActionFromAction {
            kalendarAction: "open_month_view"
        }
        KActionFromAction {
            kalendarAction: "open_week_view"
        }
        KActionFromAction {
            kalendarAction: "open_threeday_view"
        }
        KActionFromAction {
            kalendarAction: "open_day_view"
        }

        KActionFromAction {
            kalendarAction: "open_schedule_view"
        }
        KActionFromAction {
            kalendarAction: "open_todo_view"
        }
        KActionFromAction {
            kalendarAction: "open_contact_view"
        }
        KActionFromAction {
            kalendarAction: 'open_kcommand_bar'
        }

        QQC2.MenuSeparator {
        }

        QQC2.Menu {
            title: i18n("Sort Tasks")
            enabled: mode === KalendarApplication.Todo

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
            text: switch(mode) {
            case KalendarApplication.Contact:
                return i18n('Refresh All Address Books')
            default:
                return i18n('Refresh All Calendars')
            }
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
    QQC2.Menu {
        title: i18nc("@action:menu", "Window")

        Kirigami.Action {
            text: root.visibility === Window.FullScreen ? i18nc("@action:menu", "Exit Full Screen") : i18nc("@action:menu", "Enter Full Screen")
            icon.name: "view-fullscreen"
            shortcut: "F11"
            onTriggered: root.visibility === Window.FullScreen ? root.showNormal() : root.showFullScreen()
        }
    }
    QQC2.Menu {
        title: i18nc("@action:menu", "Settings")

        KActionFromAction {
            kalendarAction: "open_tag_manager"
        }

        QQC2.MenuSeparator {
        }

        KActionFromAction {
            kalendarAction: "toggle_menubar"
        }

        KActionFromAction {
            kalendarAction: 'options_configure_keybinding'
        }

        KActionFromAction {
            kalendarAction: "options_configure"
        }
    }
    QQC2.Menu {
        title: i18nc("@action:menu", "Help")

        KActionFromAction {
            kalendarAction: "open_about_page"
            enabled: pageStack.layers.currentItem.objectName != "aboutPage"
        }

        QQC2.MenuItem {
            text: i18nc("@action:menu", "Kalendar Handbook") // todo
            visible: false
        }
    }
}
