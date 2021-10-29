// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick 2.7
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0

Kirigami.Action {
    property var __action: KalendarApplication.action(kalendarAction)
    property string kalendarAction: ""

    checkable: __action.checkable
    checked: __action.checked
    icon.name: KalendarApplication.iconName(__action.icon)
    shortcut: __action.shortcut
    text: __action.text
    visible: __action.text !== ""

    onTriggered: __action.trigger()
}
