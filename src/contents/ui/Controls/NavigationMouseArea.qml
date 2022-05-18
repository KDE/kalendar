// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami

import org.kde.kalendar 1.0 as Kalendar
import "dateutils.js" as DateUtils

MouseArea {
    anchors.fill: parent
    property int wheelDelta: 0
    acceptedButtons: Qt.BackButton | Qt.ForwardButton
    onClicked: {
        if (mouse.button == Qt.BackButton) {
            if (pageStack.currentItem.objectName === "monthView") {
                pathView.decrementCurrentIndex();
                monthPage.initialMonth = false;
            } else if (pageStack.currentItem.objectName === "scheduleView") {
                setToDate(DateUtils.addMonthsToDate(pathView.currentItem.firstDayOfMonth, -1));
            }
        } else if (mouse.button == Qt.ForwardButton) {
            if (pageStack.currentItem.objectName === "monthView") {
                pathView.incrementCurrentIndex();
                monthPage.initialMonth = false;
            } else if (pageStack.currentItem.objectName === "scheduleView") {
                setToDate(DateUtils.addMonthsToDate(pathView.currentItem.firstDayOfMonth, 1))
            }
        }
    }
}
