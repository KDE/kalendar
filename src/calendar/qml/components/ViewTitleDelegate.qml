// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kalendar.components 1.0 as Components

RowLayout {
    property alias titleDateButton: titleDataButton

    spacing: 0

    Components.MainDrawerToggleButton {}

    TitleDateButton {
        id: titleDataButton
    }
}
