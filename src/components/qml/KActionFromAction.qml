// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.7
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0

Kirigami.Action {
    property string kalendarAction: ""
    property var __action: KalendarApplication.action(kalendarAction)

    text: __action.text
    shortcut: __action.shortcut
    icon.name: KalendarApplication.iconName(__action.icon)
    onTriggered: __action.trigger()
    visible: __action.text !== ""
    checkable: __action.checkable
    checked: __action.checked
}
