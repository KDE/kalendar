// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Window 2.15
import Qt.labs.platform 1.1 as Labs
import org.kde.kalendar.components 1.0

Labs.Menu {
    property Window _window: applicationWindow()

    title: i18nc("@action:menu", "Window")

    Labs.MenuItem {
        text: root.visibility === Window.FullScreen ? i18nc("@action:menu", "Exit Full Screen") : i18nc("@action:menu", "Enter Full Screen")
        icon.name: "view-fullscreen"
        shortcut: StandardKey.FullScreen
        onTriggered: if (_window.visibility === Window.FullScreen) {
            _window.showNormal();
        } else {
            _window.showFullScreen();
        }
    }
}
