// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import "dateutils.js" as DateUtils

/* Like the time combo, we need to play around with the date objects we present to the user to show the time in the date's set TZ.
 * The time picker is not aware of these differences and only has the hours and minutes in the date's set TZ.
 */

QQC2.ComboBox {
    id: root

    signal newDateChosen(date newDate)

    property int timeZoneOffset: 0
    property date dateTime
    property date dateFromText: Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
    property bool validDate: !isNaN(dateFromText.getTime())
    property TimePicker timePicker

    validator: RegularExpressionValidator {
        regularExpression: /[0-9]{0,2}[/|.|-][0-9]{0,2}[/|.|-][0-9]*/
    }

    editable: true
    editText: activeFocus ? editText : DateUtils.adjustDateTimeToLocalTimeZone(dateTime, timeZoneOffset).toLocaleDateString(Qt.locale(), Locale.NarrowFormat)

    onEditTextChanged: {
        // Set date from text here because it otherwise updates after this handler
        dateFromText = Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat);

        if (validDate && activeFocus) {
            datePicker.selectedDate = dateFromText;
            datePicker.clickedDate = dateFromText;
            newDateChosen(new Date(dateFromText.setHours(timePicker.hours, timePicker.minutes)));
        }
    }

    popup: QQC2.Popup {
        id: datePopup

        width: Kirigami.Units.gridUnit * 18
        height: Kirigami.Units.gridUnit * 18
        y: parent.y + parent.height
        z: 1000

        DatePicker {
            id: datePicker
            anchors.fill: parent
            onDatePicked: {
                datePopup.close();
                let hours = root.dateTime.getHours();
                let minutes = root.dateTime.getMinutes();
                newDateChosen(DateUtils.adjustDateTimeToLocalTimeZone(new Date(pickedDate.setHours(hours, minutes)), root.timeZoneOffset));
            }
        }
    }
}
