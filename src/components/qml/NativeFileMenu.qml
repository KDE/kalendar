// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import Qt.labs.platform 1.1 as Labs
import org.kde.kalendar.components 1.0

Labs.Menu {
    id: fileMenu
    title: i18nc("@action:menu", "File")

    default property list<QtObject> additionalMenuItems

    property list<QtObject> _menuItems: [
        NativeMenuItemFromAction {
            text: i18nc("@action:menu", "Quit Kalendar")
            icon.name: "application-exit"
            shortcut: StandardKey.Quit
            onTriggered: Qt.quit()
        }
    ]

    Component.onCompleted: {
        for (let i in additionalMenuItems) {
            fileMenu.addItem(additionalMenuItems[i])
        }
        for (let i in _menuItems) {
            fileMenu.addItem(_menuItems[i])
        }
    }
}
