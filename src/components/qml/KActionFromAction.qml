// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.7
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kalendar.components 1.0

Kirigami.Action {
    required property var action

    text: action.text
    shortcut: action.shortcut
    icon.name: Helper.iconName(action.icon)
    onTriggered: action.trigger()
    visible: action.text.length > 0
    checkable: action.checkable
    checked: action.checked
}
