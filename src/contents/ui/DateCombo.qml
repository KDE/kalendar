// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami

QQC2.ComboBox {
    id: root

    signal newDateChosen(int day, int month, int year)

    property int timeZoneOffset: 0
    property string display: dateTime.toLocaleString(Qt.locale(), Locale.NarrowFormat) // Can override for better C++ time strings
    property date dateTime: new Date()
    property date dateFromText: Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
    property bool validDate: !isNaN(dateFromText.getTime())

    onDateTimeChanged: {
        datePicker.selectedDate = dateTime;
        datePicker.clickedDate = dateTime;
    }

    editable: true
    editText: activeFocus ? editText : display

    onEditTextChanged: {
        // Set date from text here because it otherwise updates after this handler
        dateFromText = Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat);

        if (validDate && activeFocus) {
            datePicker.selectedDate = dateFromText;
            datePicker.clickedDate = dateFromText;
            newDateChosen(dateFromText.getDate(), dateFromText.getMonth() + 1, dateFromText.getFullYear());
        }
    }

    popup: QQC2.Popup {
        id: datePopup

        width: Kirigami.Units.gridUnit * 18
        height: Kirigami.Units.gridUnit * 18
        y: parent.y + parent.height
        z: 1000
        padding: 0

        contentItem: DatePicker {
            id: datePicker

            clickedDate: root.dateTime
            selectedDate: root.dateTime
            onDatePicked: {
                datePopup.close();
                newDateChosen(pickedDate.getDate(), pickedDate.getMonth() + 1, pickedDate.getFullYear());
            }
        }
    }
}
