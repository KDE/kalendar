// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0

Kirigami.OverlaySheet {
    id: eventEditorSheet

    Item {
        EventWrapper {
            id: event
        }
    }

    signal added(int collectionId, EventWrapper event)
    signal edited(int collectionId, EventWrapper event)

    property bool editMode: false
    property bool validDates: eventStartDateCombo.validDate && (eventEndDateCombo.validDate || allDayCheckBox.checked)

    header: Kirigami.Heading {
        text: editMode ? i18n("Edit event") : i18n("Add event")
    }

    footer: QQC2.DialogButtonBox {
        standardButtons: QQC2.DialogButtonBox.Cancel

        QQC2.Button {
            text: editMode ? i18n("Done") : i18n("Add")
            enabled: titleField.text && eventEditorSheet.validDates && calendarCombo.currentValue
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
        }

        onRejected: eventEditorSheet.close()
        onAccepted: {
            if (editMode) {
                return
            } else {
                // setHours method of JS Date objects returns milliseconds since epoch for some ungodly reason.
                // We need to use this to create a new JS date object.
                const startDate = new Date(eventStartDateCombo.dateFromText.setHours(eventStartTimePicker.hours, eventStartTimePicker.minutes));
                const endDate = new Date(eventEndDateCombo.dateFromText.setHours(eventEndTimePicker.hours, eventEndTimePicker.minutes));

                event.summary = titleField.text;
                event.description = descriptionTextArea.text;
                event.location = locationField.text;
                event.eventStart = startDate;

                if (allDayCheckBox.checked) {
                    event.setAllDay(true);
                } else {
                    event.eventEnd = endDate;
                }

                added(calendarCombo.currentValue, event);
            }
            eventEditorSheet.close();
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Kirigami.InlineMessage {
            id: invalidDateMessage
            Layout.fillWidth: true
            visible: !eventEditorSheet.validDates
            type: Kirigami.MessageType.Error
            text: i18n("Invalid dates provided.")
        }

        Kirigami.FormLayout {
            id: eventForm
            property date todayDate: new Date()

            QQC2.ComboBox {
                id: calendarCombo
                Kirigami.FormData.label: i18n("Calendar:")
                Layout.fillWidth: true

                property int selectedCollectionId: null

                textRole: "display"
                valueRole: "collectionId"

                // Should default to default collection
                // Should also only show *calendars*
                model: CalendarManager.collections
                delegate: Kirigami.BasicListItem {
                    leftPadding: Kirigami.Units.largeSpacing * kDescendantLevel
                    label: display
                    icon: decoration
                }
                popup.z: 1000
            }
            QQC2.TextField {
                id: titleField
                Kirigami.FormData.label: i18n("<b>Title</b>:")
                placeholderText: i18n("Required")
            }
            QQC2.TextField {
                id: locationField
                Kirigami.FormData.label: i18n("Location:")
                placeholderText: i18n("Optional")
            }

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
            }

            QQC2.CheckBox {
                id: allDayCheckBox
                Kirigami.FormData.label: i18n("All day event:")
            }
            RowLayout {
                Kirigami.FormData.label: i18n("Start:")
                Layout.fillWidth: true

                QQC2.ComboBox {
                    id: eventStartDateCombo
                    Layout.fillWidth: true
                    editable: true
                    editText: eventStartDatePicker.clickedDate.toLocaleDateString(Qt.locale(), Locale.NarrowFormat);

                    inputMethodHints: Qt.ImhDate

                    property date dateFromText: Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
                    property bool validDate: !isNaN(dateFromText.getTime())

                    onDateFromTextChanged: {
                        var datePicker = eventStartDatePicker
                        if (validDate && activeFocus) {
                            datePicker.selectedDate = dateFromText
                            datePicker.clickedDate = dateFromText
                        }
                    }

                    popup: QQC2.Popup {
                        id: eventStartDatePopup
                        width: parent.width*2
                        height: Kirigami.Units.gridUnit * 18
                        z: 1000

                        DatePicker {
                            id: eventStartDatePicker
                            anchors.fill: parent
                            onDatePicked: eventStartDatePopup.close()
                        }
                    }
                }
                QQC2.ComboBox {
                    id: eventStartTimeCombo
                    Layout.fillWidth: true
                    property string displayHour: eventStartTimePicker.hours < 10 ?
                        String(eventStartTimePicker.hours).padStart(2, "0") : eventStartTimePicker.hours
                    property string displayMinutes: eventStartTimePicker.minutes < 10 ?
                        String(eventStartTimePicker.minutes).padStart(2, "0") : eventStartTimePicker.minutes

                    editable: true
                    editText: displayHour + ":" + displayMinutes
                    enabled: !allDayCheckBox.checked
                    visible: !allDayCheckBox.checked

                    inputMethodHints: Qt.ImhTime
                    validator: RegularExpressionValidator {
                        regularExpression: /^([0-1]?[0-9]|2[0-3]):([0-5][0-9])(:[0-5][0-9])?$/
                    }

                    onEditTextChanged: {
                        var timePicker = eventStartTimePicker
                        if (acceptableInput && activeFocus) { // Need to check for activeFocus or on load the text gets reset to 00:00
                            timePicker.setToTimeFromString(editText);
                        }
                    }
                    popup: QQC2.Popup {
                        id: eventStartTimePopup
                        width: parent.width
                        height: parent.width * 2
                        z: 1000

                        TimePicker {
                            id: eventStartTimePicker
                            onDone: eventStartTimePopup.close()
                        }
                    }
                }
            }
            RowLayout {
                Kirigami.FormData.label: i18n("End:")
                Layout.fillWidth: true
                visible: !allDayCheckBox.checked

                QQC2.ComboBox {
                    id: eventEndDateCombo
                    Layout.fillWidth: true
                    editable: true
                    editText: eventEndDatePicker.clickedDate.toLocaleDateString(Qt.locale(), Locale.NarrowFormat);
                    enabled: !allDayCheckBox.checked

                    property date dateFromText: Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
                    property bool validDate: !isNaN(dateFromText.getTime())

                    onDateFromTextChanged: {
                        var datePicker = eventEndDatePicker
                        if (validDate && activeFocus) {
                            datePicker.selectedDate = dateFromText
                            datePicker.clickedDate = dateFromText
                        }
                    }

                    popup: QQC2.Popup {
                        id: eventEndDatePopup
                        width: parent.width*2
                        height: Kirigami.Units.gridUnit * 18
                        z: 1000

                        DatePicker {
                            id: eventEndDatePicker
                            anchors.fill: parent
                            onDatePicked: eventEndDatePopup.close()
                        }
                    }
                }
                QQC2.ComboBox {
                    id: eventEndTimeCombo
                    Layout.fillWidth: true
                    property string displayHour: eventEndTimePicker.hours < 10 ?
                        String(eventEndTimePicker.hours).padStart(2, "0") : eventEndTimePicker.hours
                    property string displayMinutes: eventEndTimePicker.minutes < 10 ?
                        String(eventEndTimePicker.minutes).padStart(2, "0") : eventEndTimePicker.minutes

                    editable: true
                    editText: displayHour + ":" + displayMinutes
                    enabled: !allDayCheckBox.checked

                    inputMethodHints: Qt.ImhTime
                    validator: RegularExpressionValidator {
                        regularExpression: /^([0-1]?[0-9]|2[0-3]):([0-5][0-9])(:[0-5][0-9])?$/
                    }

                    onEditTextChanged: {
                        var timePicker = eventEndTimePicker
                        if (acceptableInput && activeFocus) {
                            timePicker.setToTimeFromString(editText);
                        }
                    }

                    popup: QQC2.Popup {
                        id: eventEndTimePopup
                        width: parent.width
                        height: parent.width * 2
                        z: 1000

                        TimePicker {
                            id: eventEndTimePicker
                            onDone: eventEndTimePopup.close()
                        }
                    }
                }
            }

            QQC2.ComboBox {
                id: repeatComboBox
                Kirigami.FormData.label: i18n("Repeat:")
                Layout.fillWidth: true
                model: [i18n("Never"),
                        i18n("Daily"),
                        i18n("Weekly"),
                        i18n("Monthly"),
                        i18n("Yearly"),
                        i18n("Custom")]
                delegate: Kirigami.BasicListItem {
                    label: modelData
                }
                popup.z: 1000
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing
                columns: 5
                visible: repeatComboBox.currentIndex == 5 // "Custom" index

                QQC2.Label {
                    Layout.columnSpan: 1
                    text: i18n("Every:")
                }
                QQC2.SpinBox {
                    id: recurFreqRuleSpinbox
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    value: 1
                }
                QQC2.ComboBox {
                    id: recurScaleRuleCombobox
                    Layout.fillWidth: true
                    Layout.columnSpan: 2

                    property int savedIndex: 0;
                    property var modelSingular: [i18n("day"), i18n("week"), i18n("month"), i18n("year")]
                    property var modelPlural: [i18n("days"), i18n("weeks"), i18n("months"), i18n("years")]

                    onModelChanged: currentIndex = savedIndex

                    model: recurFreqRuleSpinbox.value > 1 ? modelPlural : modelSingular
                    delegate: Kirigami.BasicListItem {
                        text: modelData
                        onClicked: recurScaleRuleCombobox.savedIndex = index;
                    }
                    popup.z: 1000
                }

                GridLayout {
                    id: recurWeekdayRuleLayout
                    Layout.columnSpan: 5
                    columns: 7
                    visible: recurScaleRuleCombobox.currentIndex == 1 // "week"/"weeks" index

                    Repeater {
                        model: 7
                        delegate: QQC2.Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.locale().dayName(Qt.locale().firstDayOfWeek + index, Locale.ShortFormat)
                        }
                    }

                    QQC2.ButtonGroup {
                        buttons: weekdayCheckboxRepeater.children
                    }
                    Repeater {
                        id: weekdayCheckboxRepeater
                        model: 7
                        delegate: QQC2.CheckBox {
                            Layout.alignment: Qt.AlignHCenter
                            // We make sure we get dayNumber per the day of the week number used by QML/JS
                            property int dayNumber: Qt.locale().firstDayOfWeek + index > 6 ?
                                                    Qt.locale().firstDayOfWeek + index - 7 :
                                                    Qt.locale().firstDayOfWeek + index
                        }
                    }
                }

            }

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
            }

            QQC2.TextArea {
                id: descriptionTextArea
                Kirigami.FormData.label: i18n("Description:")
                placeholderText: i18n("Optional")
                Layout.fillWidth: true
            }

            ColumnLayout {
                Kirigami.FormData.label: i18n("Reminder:")
                Layout.fillWidth: true
                id: remindersColumn

                function secondsToReminderLabel(seconds) { // Gives prettified time

                    function numAndUnit(secs) {
                        if(secs >= 2 * 24 * 60 * 60)
                            return Math.round(secs / (24*60*60)) + i18n(" days"); // 2 days +
                        else if (secs >= 1 * 24 * 60 * 60)
                            return "1 day";
                        else if (secs >= 2 * 60 * 60)
                            return Math.round(secs / (60*60)) + i18n(" hours"); // 2 hours +
                        else if (secs >= 1 * 60 * 60)
                            return "1 hour";
                        else
                            return Math.round(secs / 60) + i18n(" minutes");
                    }

                    if (seconds < 0) {
                        return numAndUnit(seconds * -1) + i18n(" before");
                    } else if (seconds < 0) {
                        return numAndUnit(seconds) + i18n(" after");
                    } else {
                        return i18n("On event start");
                    }
                }

                property var reminderCombos: []

                QQC2.Button {
                    id: remindersButton
                    text: i18n("Add reminder")
                    Layout.fillWidth: true

                    onClicked: event.remindersModel.addAlarm();
                }

                Repeater {
                    id: remindersRepeater
                    Layout.fillWidth: true

                    model: event.remindersModel
                    // All of the alarms are handled within the delegates.

                    delegate: RowLayout {
                        Layout.fillWidth: true

                        Component.onCompleted: console.log(Object.keys(model))

                        QQC2.ComboBox {
                            // There is also a chance here to add a feature for the user to pick reminder type.
                            Layout.fillWidth: true

                            property var beforeEventSeconds: 0

                            displayText: remindersColumn.secondsToReminderLabel(startOffset)
                            //textRole: "DisplayNameRole"
                            onCurrentValueChanged: event.remindersModel.setData(event.remindersModel.index(index, 0),
                                                                                currentValue,
                                                                                event.remindersModel.dataroles["startOffset"])

                            model: [0, // We times by -1 to make times be before event
                                    -1 * 5 * 60, // 5 minutes
                                    -1 * 10 * 60,
                                    -1 * 15 * 60,
                                    -1 * 30 * 60,
                                    -1 * 45 * 60,
                                    -1 * 1 * 60 * 60, // 1 hour
                                    -1 * 2 * 60 * 60,
                                    -1 * 1 * 24 * 60 * 60, // 1 day
                                    -1 * 2 * 24 * 60 * 60,
                                    -1 * 5 * 24 * 60 * 60]
                                    // All these times are in seconds.
                            delegate: Kirigami.BasicListItem {
                                text: remindersColumn.secondsToReminderLabel(modelData)
                            }

                            popup.z: 1000
                        }

                        QQC2.Button {
                            icon.name: "edit-delete-remove"
                            onClicked: event.remindersModel.deleteAlarm(model.index);
                        }
                    }
                }
            }

            ColumnLayout {
                Kirigami.FormData.label: i18n("Attendees:")
                Layout.fillWidth: true
                id: attendeesColumn

                QQC2.Button {
                    id: attendeesButton
                    text: i18n("Add attendee")
                    Layout.fillWidth: true

                    onClicked: event.attendeesModel.addAttendee();
                }

                Repeater {
                    model: event.attendeesModel
                    // All of the alarms are handled within the delegates.

                    delegate: ColumnLayout {
                        Layout.leftMargin: Kirigami.Units.largeSpacing

                        RowLayout {
                            QQC2.Label {
                                Layout.fillWidth: true
                                text: i18n("Attendee " + String(index + 1))
                            }
                            QQC2.Button {
                                icon.name: "edit-delete-remove"
                                onClicked: event.attendeesModel.deleteAttendee(index);
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 5

                            QQC2.Label{
                                text: i18n("Name:")
                            }
                            QQC2.TextField {
                                Layout.fillWidth: true
                                Layout.columnSpan: 4
                                onTextChanged: event.attendeesModel.setData(event.attendeesModel.index(index, 0),
                                                                            text,
                                                                            event.attendeesModel.dataroles["name"])
                                Component.onCompleted: text = model.name
                            }

                            QQC2.Label {
                                text: i18n("Email:")
                            }
                            QQC2.TextField {
                                Layout.fillWidth: true
                                Layout.columnSpan: 4
                                //editText: Email
                                onTextChanged: event.attendeesModel.setData(event.attendeesModel.index(index, 0),
                                                                            text,
                                                                            event.attendeesModel.dataroles["email"])
                                Component.onCompleted: text = model.email
                            }
                            QQC2.Label {
                                text: i18n("Status:")
                            }
                            QQC2.ComboBox {
                                Layout.columnSpan: 2
                                model: event.attendeesModel.attendeeStatusModel
                                textRole: "display"
                                valueRole: "value"
                                currentIndex: status // role of parent
                                onCurrentValueChanged: event.attendeesModel.setData(event.attendeesModel.index(index, 0),
                                                                                    currentValue,
                                                                                    event.attendeesModel.dataroles["status"])

                                popup.z: 1000
                            }
                            QQC2.CheckBox {
                                Layout.columnSpan: 2
                                text: i18n("Request RSVP")
                                checked: model.rsvp
                                onCheckedChanged: event.attendeesModel.setData(event.attendeesModel.index(index, 0),
                                                                               checked,
                                                                               event.attendeesModel.dataroles["rsvp"])
                            }
                        }
                    }
                }
            }
        }
    }
}
