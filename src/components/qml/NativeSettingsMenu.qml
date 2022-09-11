// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import Qt.labs.platform 1.1 as Labs
import org.kde.kalendar.components 1.0

Labs.Menu {
    title: i18nc("@action:menu", "Settings")

    NativeMenuItemFromAction {
        kalendarAction: 'toggle_menubar'
        visible: !globalMenuLoader.active
    }
    NativeMenuItemFromAction {
        kalendarAction: 'open_tag_manager'
    }
    Labs.MenuSeparator {
    }
    NativeMenuItemFromAction {
        kalendarAction: 'options_configure_keybinding'
    }
    NativeMenuItemFromAction {
        kalendarAction: 'options_configure'
    }
}
