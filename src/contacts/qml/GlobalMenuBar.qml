// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

import Qt.labs.platform 1.1 as Labs

import QtQuick 2.15
import QtQuick.Window 2.15
import org.kde.kalendar.components 1.0

Labs.MenuBar {
    NativeFileMenu {}

    NativeEditMenu {}

    Labs.Menu {
        title: i18nc("@action:menu", "View")

        NativeMenuItemFromAction {
            action: ContactApplication.action('open_kcommand_bar')
        }

        NativeMenuItemFromAction {
            action: ContactApplication.action("refresh_all")
        }
    }

    Labs.Menu {
        title: i18nc("@action:menu", "Create")

        NativeMenuItemFromAction {
            action: ContactApplication.action("create_contact")
        }
        NativeMenuItemFromAction {
            action: ContactApplication.action("create_contact_group")
        }
    }

    NativeWindowMenu {}

    Labs.Menu {
        title: i18nc("@action:menu", "Settings")

        NativeMenuItemFromAction {
            action: ContactApplication.action('open_tag_manager')
        }

        Labs.MenuSeparator {}

        NativeMenuItemFromAction {
            action: ContactApplication.action('options_configure_keybinding')
        }
        NativeMenuItemFromAction {
            action: ContactApplication.action('options_configure')
        }
    }

    Labs.Menu {
        title: i18nc("@action:menu", "Help")

        NativeMenuItemFromAction {
            action: ContactApplication.action("open_about_page")
        }

        NativeMenuItemFromAction {
            action: ContactApplication.action("open_about_kde_page")
        }

        NativeMenuItemFromAction {
            text: i18nc("@action:menu", "Kalendar Handbook") // todo
            visible: false
        }
    }
}
