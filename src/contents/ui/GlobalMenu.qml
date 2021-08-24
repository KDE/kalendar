// SPDX-FileCopyrightText: 2021 Carson Black <uhhadd@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import Qt.labs.platform 1.1 as Labs

import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.10
import org.kde.kirigami 2.15 as Kirigami
import QtQuick.Window 2.15

Labs.MenuBar {
    property var parentWindow: null
    Labs.Menu {
        title: i18nc("@action:menu", "File")

        Labs.MenuItem {
            text: i18nc("@action:menu", "Import calendar") // todo
            visible: false
        }

        Labs.MenuItem {
            text: i18nc("@action:menu", "Quit Kalendar")

            shortcut: StandardKey.Quit
            onTriggered: Qt.quit()
        }
    }
    EditMenu {
        id: editMenu
        title: i18nc("@action:menu", "Edit")
        Connections {
            target: parentWindow
            onActiveFocusItemChanged: {
                if (parentWindow.activeFocusItem instanceof TextEdit || parentWindow.activeFocusItem instanceof TextInput) {
                    editMenu.field = parentWindow.activeFocusItem;
                }
            }
        }
        field: null
    }
    Labs.Menu {
        title: i18nc("@action:menu", "View")

        NativeMenuItemFromAction {
            kalendarAction: 'open_month_view'
        }

        NativeMenuItemFromAction {
            kalendarAction: 'open_schedule_view'
        }

        NativeMenuItemFromAction {
            kalendarAction: 'open_todo_view'
        }
    }
    Labs.Menu {
        title: i18nc("@action:menu", "Actions")

        NativeMenuItemFromAction {
            kalendarAction: 'create_event'
        }

        NativeMenuItemFromAction {
            kalendarAction: 'create_todo'
        }
    }
    Labs.Menu {
        title: i18nc("@action:menu", "Window")

        Labs.MenuItem {
            text: root.visibility === Window.FullScreen ? i18nc("@action:menu", "Exit Full Screen") : i18nc("@action:menu", "Enter Full Screen")
            onTriggered: root.visibility === Window.FullScreen ? root.showNormal() : root.showFullScreen()
        }
    }
    Labs.Menu {
        title: i18nc("@action:menu", "Settings")
        NativeMenuItemFromAction {
            kalendarAction: 'options_configure_keybinding'
        }
        NativeMenuItemFromAction {
            kalendarAction: 'options_configure'
        }
    }
    Labs.Menu {
        title: i18nc("@action:menu", "Help")

        Labs.MenuItem {
            text: i18nc("@action:menu", "Kalendar Handbook") // todo
            visible: false
        }
    }
}
