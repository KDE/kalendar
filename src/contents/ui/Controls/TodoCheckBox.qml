// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar.utils 1.0

ColoredCheckbox {
    id: todoCheckbox

    property bool todoCompleted
    property int todoCompletion
    property var todoPtr

    color: incidenceColor
    radius: 100
    checked: todoCompleted || todoCompletion === 100
    onClicked: KalendarUiUtils.completeTodo(todoPtr)

    indicator: Item {
        height: parent.height
        width: height
        x: todoCheckbox.leftPadding
        y: parent.height / 2 - height / 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        // The icon provides the main circle for the checkbox when not checked,
        // whereas the rectangle provides the circle when it is checked.
        // The rectangle always provides the tinted background.

        Kirigami.Icon {
            isMask: true
            color: todoCheckbox.color
            anchors.fill: parent
            anchors.margins: parent.height * -0.16
            visible: !todoCheckbox.checked
            source: {
                if (todoCheckbox.todoCompletion >= 75) {
                    return 'task-process-3';
                }
                if (todoCheckbox.todoCompletion >= 50) {
                    return 'task-process-2';
                }
                if (todoCheckbox.todoCompletion >= 25) {
                    return 'task-process-1';
                }
                return 'task-process-0';
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: todoCheckbox.radius
            border.color: todoCheckbox.checked ? todoCheckbox.color : Qt.rgba(0,0,0,0)
            color: Qt.rgba(todoCheckbox.color.r, todoCheckbox.color.g, todoCheckbox.color.b, 0.1)

            Rectangle {
                anchors.margins: parent.height * 0.2
                anchors.fill: parent
                radius: todoCheckbox.radius / 3
                color: todoCheckbox.color
                visible: todoCheckbox.checked
            }
        }
    }
}
