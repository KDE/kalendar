// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import "dateutils.js" as DateUtils

QQC2.ComboBox {
    id: root

    signal newTimeChosen(int hours, int minutes)

    property int timeZoneOffset: 0
    property string display
    property date dateTime
    property alias timePicker: popupTimePicker

    editable: true
    editText: activeFocus && !popupTimePicker.visible ? editText : display

    inputMethodHints: Qt.ImhTime

    onEditTextChanged: {
        if (activeFocus && !popupTimePicker.visible) { // Need to check for activeFocus or on load the text gets reset to 00:00
            const dateFromTime = Date.fromLocaleTimeString(Qt.locale(), editText, Locale.NarrowFormat);
            if(!isNaN(dateFromTime.getTime())) {
                newTimeChosen(dateFromTime.getHours(), dateFromTime.getMinutes());
            }
        }
    }

    popup: QQC2.Popup {
        id: timePopup
        width: Kirigami.Units.gridUnit * 10
        height: Kirigami.Units.gridUnit * 14
        x: parent.width - width
        y: parent.y + parent.height
        z: 1000
        padding: 0

        TimePicker {
            id: popupTimePicker

            Component.onCompleted: minuteMultiples = 5
            Connections {
                target: root

                function timeChangeHandler() {
                    if(!popupTimePicker.visible) {
                        // JS for some insane reason always tries to give you a datetime in the local timezone, even though
                        // we want the hours in the datetime's timezone, not our local timezone
                        const adjusted = DateUtils.adjustDateTimeToLocalTimeZone(root.dateTime, root.timeZoneOffset)

                        popupTimePicker.hours = adjusted.getHours();
                        popupTimePicker.minutes = adjusted.getMinutes();
                    }
                }

                function onDateTimeChanged() {
                    timeChangeHandler();
                }

                function onTimeZoneOffsetChanged() {
                    timeChangeHandler();
                }
            }

            function valuesChangedHandler() {
                if(visible) {
                    root.newTimeChosen(hours, minutes);
                }
            }

            onHoursChanged: valuesChangedHandler()
            onMinutesChanged: valuesChangedHandler()
        }
    }
}
