// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami

MouseArea {
    id: dayMouseArea

    signal addNewEvent(date addDate)

    property date addDate
    property double clickX
    property double clickY

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onDoubleClicked: {
        if (pressedButtons & Qt.LeftButton) {
            addNewEvent(addDate);
        }
    }
    onPressed: {
        clickX = mouseX;
        clickY = mouseY;
        if (pressedButtons & Qt.RightButton) {
            dayActions.createObject(dayMouseArea, {}).open();
        }
    }

    Component {
        id: dayActions
        QQC2.Menu {
            id: actionsPopup
            y: dayMouseArea.clickY
            x: dayMouseArea.clickX

            // TODO: Add to-dos and journals
            QQC2.MenuItem {
                icon.name: "tag-events"
                text: i18n("New event")
                onClicked: addNewEvent(dayMouseArea.addDate)
            }
        }
    }
}
