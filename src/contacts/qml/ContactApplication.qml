// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQml 2.15
import org.kde.kalendar.components 1.0

KalendarApp {
    menuBar: Qt.resolvedUrl('./private/MenuBar.qml')
    globalMenuBar: Qt.resolvedUrl('./private/GlobalMenuBar.qml')
}
