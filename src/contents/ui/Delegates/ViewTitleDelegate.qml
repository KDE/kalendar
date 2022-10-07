// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15

RowLayout {
    property alias titleDateButton: titleDataButton

    spacing: 0

    MainDrawerToggleButton {}

    TitleDateButton {
        id: titleDataButton
    }
}
