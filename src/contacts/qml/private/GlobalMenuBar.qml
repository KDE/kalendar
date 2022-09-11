// SPDX-FileCopyrightText: 2021 Carson Black <uhhadd@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import Qt.labs.platform 1.1 as Labs

import QtQuick 2.15
import QtQuick.Window 2.15
import org.kde.kalendar 1.0
import org.kde.kalendar.components 1.0

Labs.MenuBar {
    NativeFileMenu {}

    NativeEditMenu {}

    NativeViewMenu {}

    Labs.Menu {
        title: i18nc("@action:menu", "Create")

        NativeMenuItemFromAction {
            kalendarAction: 'create_mail'
        }
    }

    NativeWindowMenu {}

    NativeSettingsMenu {}

    NativeHelpMenu {}
}
