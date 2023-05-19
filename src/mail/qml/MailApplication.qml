// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQml 2.15
import org.kde.kalendar.components 1.0
import org.kde.kirigami 2.20 as Kirigami

KalendarApp {
    appName: 'mail'
    menuBar: Qt.resolvedUrl('./private/MenuBar.qml')
    globalMenuBar: Qt.resolvedUrl('./private/GlobalMenuBar.qml')
    hamburgerActions: []
}
