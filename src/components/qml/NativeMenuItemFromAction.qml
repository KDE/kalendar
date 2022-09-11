// SPDX-FileCopyrightText: 2020 (c) Carson Black <uhhadd@gmail.com>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.7
import Qt.labs.platform 1.1
import org.kde.kalendar 1.0

MenuItem {
    id: menuItem
    property string kalendarAction: ""
    property var __action: KalendarApplication.action(kalendarAction)

    text: __action.text
    shortcut: __action.shortcut
    iconName: KalendarApplication.iconName(__action.icon)
    onTriggered: __action.trigger()
    visible: __action.text !== ""
    checkable: __action.checkable
    checked: __action.checked
    enabled: __action.enabled && parent.enabled
}
