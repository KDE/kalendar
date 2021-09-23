// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0 as Kalendar

MouseArea {
    id: dayMouseArea

    signal addNewIncidence(int type, date addDate)

    property string defaultType: Kalendar.IncidenceWrapper.TypeEvent
    property date addDate
    property double clickX
    property double clickY

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onDoubleClicked: {
        if (pressedButtons & Qt.LeftButton) {
            clickX = mouseX;
            clickY = mouseY;
            addNewIncidence(defaultType, addDate);
        }
    }
    onPressed: {
        if (pressedButtons & Qt.RightButton) {
            clickX = mouseX;
            clickY = mouseY;
            dayActions.createObject(dayMouseArea, {}).open();
        }
    }

    Component {
        id: dayActions
        QQC2.Menu {
            id: actionsPopup
            y: dayMouseArea.clickY
            x: dayMouseArea.clickX

            // TODO: Add journals
            QQC2.MenuItem {
                text: i18n("New Event…")
                icon.name: "resource-calendar-insert"
                onClicked: addNewIncidence(Kalendar.IncidenceWrapper.TypeEvent, dayMouseArea.addDate)
            }
            QQC2.MenuItem {
                text: i18n("New Task…")
                icon.name: "view-task-add"
                onClicked: addNewIncidence(Kalendar.IncidenceWrapper.TypeTodo, dayMouseArea.addDate)
            }
        }
    }
}
