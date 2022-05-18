// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import "dateutils.js" as DateUtils

QQC2.Popup {
    id: root

    signal dateSelected(date date)

    property date date: new Date()
    onDateChanged: {
        datePicker.selectedDate = date;
        datePicker.clickedDate = date;
    }
    property bool showDays: true

    implicitWidth: Kirigami.Units.gridUnit * 20
    padding: 0

    contentItem: DatePicker {
        id: datePicker
        showDays: root.showDays
        selectedDate: root.date
        clickedDate: root.date
        onDatePicked: root.dateSelected(pickedDate)
    }
}
