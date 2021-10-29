/*
   SPDX-FileCopyrightText: 2020 (c) Carson Black <uhhadd@gmail.com>

   SPDX-License-Identifier: LGPL-3.0-or-later
 */
import QtQuick 2.7
import Qt.labs.platform 1.1
import org.kde.kalendar 1.0

MenuItem {
    id: menuItem
    property var __action: KalendarApplication.action(kalendarAction)
    property string kalendarAction: ""

    checkable: __action.checkable
    checked: __action.checked
    enabled: __action.enabled && parent.enabled
    iconName: KalendarApplication.iconName(__action.icon)
    shortcut: __action.shortcut
    text: __action.text
    visible: __action.text !== ""

    onTriggered: __action.trigger()
}
