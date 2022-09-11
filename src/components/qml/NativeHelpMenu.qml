// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import Qt.labs.platform 1.1 as Labs
import org.kde.kalendar.components 1.0

Labs.Menu {
    title: i18nc("@action:menu", "Help")

    NativeMenuItemFromAction {
        kalendarAction: 'open_about_page'
        enabled: pageStack.layers.currentItem.objectName != "aboutPage"
    }

    Labs.MenuItem {
        text: i18nc("@action:menu", "Kalendar Handbook") // todo
        visible: false
    }
}
