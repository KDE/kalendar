// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later
import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0 as Kalendar

MouseArea {
    id: dayMouseArea
    property date addDate
    property double clickX
    property double clickY
    property string defaultType: Kalendar.IncidenceWrapper.TypeEvent

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true

    signal addNewIncidence(int type, date addDate)
    signal deselect

    onClicked: deselect()
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
            x: dayMouseArea.clickX
            y: dayMouseArea.clickY

            // TODO: Add journals
            QQC2.MenuItem {
                icon.name: "resource-calendar-insert"
                text: i18n("New Event…")

                onClicked: addNewIncidence(Kalendar.IncidenceWrapper.TypeEvent, dayMouseArea.addDate)
            }
            QQC2.MenuItem {
                icon.name: "view-task-add"
                text: i18n("New Task…")

                onClicked: addNewIncidence(Kalendar.IncidenceWrapper.TypeTodo, dayMouseArea.addDate)
            }
        }
    }
}
