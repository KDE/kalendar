// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2

MouseArea {
    acceptedButtons: Qt.BackButton | Qt.ForwardButton
    propagateComposedEvents: true
    onClicked: {
        if (mouse.button === Qt.BackButton) {
            moveViewBackwardsAction.trigger();
        } else if (mouse.button === Qt.ForwardButton) {
            moveViewForwardsAction.trigger();
        }
    }
}
