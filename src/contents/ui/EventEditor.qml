// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.0
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0
import "labelutils.js" as LabelUtils

Kirigami.ScrollablePage {
    id: eventEditorSheet

    signal added(int collectionId, EventWrapper event)
    signal edited(int collectionId, EventWrapper event)
    signal cancel

    // Setting the eventWrapper here and now causes some *really* weird behaviour.
    // Set it after this component has already been instantiated.
    property var eventWrapper
    property bool editMode: false

    property bool validDates: eventWrapper !== undefined &&
                              editorLoader.item.validFormDates &&
                              eventWrapper.eventStart < eventWrapper.eventEnd

    onEventWrapperChanged: if(!editMode) { eventWrapper.collectionId = CalendarManager.defaultCalendarId }


    title: editMode ? i18n("Edit event") : i18n("Add event")

    footer: QQC2.DialogButtonBox {
        standardButtons: QQC2.DialogButtonBox.Cancel

        QQC2.Button {
            icon.name: editMode ? "document-save" : "list-add"
            text: editMode ? i18n("Save") : i18n("Add")
            enabled: eventEditorSheet.validDates && eventWrapper.summary && eventWrapper.collectionId
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
        }

        onRejected: cancel()
        onAccepted: {
            if (editMode) {
                edited(eventWrapper.collectionId, eventWrapper);
            } else {
                added(eventWrapper.collectionId, eventWrapper);
            }
            cancel();
        }
    }

    Loader {
        id: editorLoader
        Layout.fillWidth: true
        Layout.fillHeight: true

        active: eventWrapper !== undefined
        sourceComponent: ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            property bool validFormDates: eventStartDateCombo.validDate &&
                                          (eventEndDateCombo.validDate || eventWrapper.allDay)

            Kirigami.InlineMessage {
                id: invalidDateMessage

                Layout.fillWidth: true
                visible: !eventEditorSheet.validDates
                type: Kirigami.MessageType.Error
                // Specify what the problem is to aid user
                text: eventEditorSheet.eventWrapper.eventStart < eventEditorSheet.eventWrapper.eventEnd ?
                      i18n("Invalid dates provided.") : i18n("End date cannot be before start date.")
            }

            Kirigami.FormLayout {
                id: eventForm

                property date todayDate: new Date()

                QQC2.ComboBox {
                    id: calendarCombo

                    Kirigami.FormData.label: i18n("Calendar:")
                    Layout.fillWidth: true

                    textRole: "display"
                    valueRole: "collectionId"
                    currentIndex: CalendarManager.getCalendarSelectableIndex(eventEditorSheet.eventWrapper.collectionId)
                    onCurrentValueChanged: eventEditorSheet.eventWrapper.collectionId = currentValue

                    // Should default to default collection
                    // Should also only show *calendars*
                    model: CalendarManager.selectableCalendars
                    delegate: Kirigami.BasicListItem {
                        label: display
                        icon: decoration
                    }
                    popup.z: 1000
                }
                QQC2.TextField {
                    id: titleField

                    Kirigami.FormData.label: i18n("<b>Title</b>:")
                    placeholderText: i18n("Required")
                    text: eventEditorSheet.eventWrapper.summary
                    onTextChanged: eventEditorSheet.eventWrapper.summary = text
                }
                QQC2.TextField {
                    id: locationField

                    Kirigami.FormData.label: i18n("Location:")
                    placeholderText: i18n("Optional")
                    text: eventEditorSheet.eventWrapper.location
                    onTextChanged: eventEditorSheet.eventWrapper.location = text
                }

                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                }

                QQC2.CheckBox {
                    id: allDayCheckBox

                    text: i18n("All day event")
                    onCheckedChanged: eventEditorSheet.eventWrapper.allDay = checked
                }
                RowLayout {
                    id: eventStartLayout

                    Kirigami.FormData.label: i18n("Start:")
                    Layout.fillWidth: true

                    QQC2.ComboBox {
                        id: eventStartDateCombo
                        Layout.fillWidth: true

                        editable: true
                        editText: eventEditorSheet.eventWrapper.eventStart.toLocaleDateString(Qt.locale(), Locale.NarrowFormat)

                        inputMethodHints: Qt.ImhDate

                        property date dateFromText: Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
                        property bool validDate: !isNaN(dateFromText.getTime())

                        onEditTextChanged: {
                            // Set date from text here because it otherwise updates after this handler
                            dateFromText = Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
                            let datePicker = eventStartDatePicker

                            if (validDate && activeFocus) {
                                var timePicker = eventStartTimePicker
                                datePicker.selectedDate = dateFromText;
                                datePicker.clickedDate = dateFromText;
                                eventEditorSheet.eventWrapper.eventStart = new Date(dateFromText.setHours(timePicker.hours, timePicker.minutes));
                            }
                        }

                        popup: QQC2.Popup {
                            id: eventStartDatePopup

                            width: Kirigami.Units.gridUnit * 18
                            height: Kirigami.Units.gridUnit * 18
                            y: parent.y + parent.height
                            z: 1000

                            DatePicker {
                                id: eventStartDatePicker

                                anchors.fill: parent
                                onDatePicked: {
                                    eventStartDatePopup.close();
                                    let hours = eventEditorSheet.eventWrapper.eventStart.getHours();
                                    let minutes = eventEditorSheet.eventWrapper.eventStart.getMinutes();
                                    eventEditorSheet.eventWrapper.eventStart = new Date(pickedDate.setHours(hours, minutes));
                                }
                            }
                        }
                    }
                    QQC2.ComboBox {
                        id: eventStartTimeCombo

                        Layout.fillWidth: true

                        editable: true
                        editText: eventEditorSheet.eventWrapper.eventStart.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                        enabled: !allDayCheckBox.checked
                        visible: !allDayCheckBox.checked

                        inputMethodHints: Qt.ImhTime
                        validator: RegularExpressionValidator {
                            regularExpression: /^([0-1]?[0-9]|2[0-3]):([0-5][0-9])(:[0-5][0-9])?$/
                        }

                        onEditTextChanged: {
                            let timePicker = eventStartTimePicker

                            if (acceptableInput && activeFocus) { // Need to check for activeFocus or on load the text gets reset to 00:00
                                timePicker.setToTimeFromString(editText);
                                eventEditorSheet.eventWrapper.eventStart = new Date(eventEditorSheet.eventWrapper.eventStart.setHours(timePicker.hours, timePicker.minutes));
                            }
                        }

                        popup: QQC2.Popup {
                            id: eventStartTimePopup
                            width: parent.width
                            height: parent.width * 2
                            y: parent.y + parent.height
                            z: 1000

                            TimePicker {
                                id: eventStartTimePicker

                                Connections {
                                    target: eventEditorSheet.eventWrapper
                                    function onEventStartChanged() {
                                        eventStartTimePicker.dateTime = eventEditorSheet.eventWrapper.eventStart
                                    }
                                }

                                dateTime: eventEditorSheet.eventWrapper.eventStart

                                onDone: {
                                    eventStartTimePopup.close();
                                    eventEditorSheet.eventWrapper.eventStart = new Date(eventEditorSheet.eventWrapper.eventStart.setHours(hours, minutes));

                                }
                            }
                        }
                    }
                }
                RowLayout {
                    id: eventEndLayout

                    Kirigami.FormData.label: i18n("End:")
                    Layout.fillWidth: true
                    visible: !allDayCheckBox.checked

                    QQC2.ComboBox {
                        id: eventEndDateCombo

                        Layout.fillWidth: true

                        property date dateFromText: Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
                        property bool validDate: !isNaN(dateFromText.getTime())

                        editable: true
                        editText: eventEditorSheet.eventWrapper.eventEnd.toLocaleDateString(Qt.locale(), Locale.NarrowFormat)
                        enabled: !allDayCheckBox.checked

                        onEditTextChanged: {
                            // Set date from text here because it otherwise updates after this handler
                            dateFromText = Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat);
                            let datePicker = eventEndDatePicker;

                            if (validDate && activeFocus) {
                                var timePicker = eventEndTimePicker
                                datePicker.selectedDate = dateFromText;
                                datePicker.clickedDate = dateFromText;
                                eventEditorSheet.eventWrapper.eventEnd = new Date(dateFromText.setHours(timePicker.hours, timePicker.minutes));
                            }
                        }

                        popup: QQC2.Popup {
                            id: eventEndDatePopup

                            width: Kirigami.Units.gridUnit * 18
                            height: Kirigami.Units.gridUnit * 18
                            y: parent.y + parent.height
                            z: 1000

                            DatePicker {
                                id: eventEndDatePicker
                                anchors.fill: parent
                                onDatePicked: {
                                    eventEndDatePopup.close();
                                    let hours = eventEditorSheet.eventWrapper.eventEnd.getHours();
                                    let minutes = eventEditorSheet.eventWrapper.eventEnd.getMinutes();
                                    eventEditorSheet.eventWrapper.eventEnd = new Date(pickedDate.setHours(hours, minutes));
                                }
                            }
                        }
                    }
                    QQC2.ComboBox {
                        id: eventEndTimeCombo

                        Layout.fillWidth: true

                        editable: true
                        editText: eventEditorSheet.eventWrapper.eventEnd.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                        enabled: !allDayCheckBox.checked

                        inputMethodHints: Qt.ImhTime
                        validator: RegularExpressionValidator {
                            regularExpression: /^([0-1]?[0-9]|2[0-3]):([0-5][0-9])(:[0-5][0-9])?$/
                        }

                        onEditTextChanged: {
                            let timePicker = eventEndTimePicker

                            if (acceptableInput && activeFocus) {
                                timePicker.setToTimeFromString(editText);
                                eventEditorSheet.eventWrapper.eventEnd = new Date(eventEditorSheet.eventWrapper.eventEnd.setHours(timePicker.hours, timePicker.minutes));
                            }
                        }

                        popup: QQC2.Popup {
                            id: eventEndTimePopup

                            width: parent.width
                            height: parent.width * 2
                            y: parent.y + parent.height
                            z: 1000

                            TimePicker {
                                id: eventEndTimePicker

                                Connections {
                                    target: eventEditorSheet.eventWrapper
                                    function onEventEndChanged() {
                                        eventEndTimePicker.dateTime = eventEditorSheet.eventWrapper.eventEnd
                                    }
                                }

                                dateTime: eventEditorSheet.eventWrapper.eventEnd

                                onDone: {
                                    eventEndTimePopup.close();
                                    eventEditorSheet.eventWrapper.eventEnd = new Date(eventEditorSheet.eventWrapper.eventEnd.setHours(hours, minutes));
                                }
                            }
                        }
                    }
                }

                QQC2.ComboBox {
                    id: repeatComboBox
                    Kirigami.FormData.label: i18n("Repeat:")
                    Layout.fillWidth: true
                    textRole: "display"
                    valueRole: "interval"
                    onCurrentIndexChanged: if(currentIndex == 0) { eventEditorSheet.eventWrapper.clearRecurrences(); } // "Never"
                    onCurrentValueChanged: if(currentValue >= 0) { eventEditorSheet.eventWrapper.setRegularRecurrence(currentValue); }
                    currentIndex: {
                        switch(eventEditorSheet.eventWrapper.recurrenceData.type) {
                            case 0:
                                return eventEditorSheet.eventWrapper.recurrenceData.type;
                            case 3: // Daily
                                return eventEditorSheet.eventWrapper.recurrenceData.frequency === 1 ?
                                    eventEditorSheet.eventWrapper.recurrenceData.type - 2 : 5
                            case 4: // Weekly
                                return eventEditorSheet.eventWrapper.recurrenceData.frequency === 1 ?
                                    (eventEditorSheet.eventWrapper.recurrenceData.weekdays.filter(x => x === true).length === 0 ?
                                    eventEditorSheet.eventWrapper.recurrenceData.type - 2 : 5) : 5
                            case 5: // Monthly on position (e.g. third Monday)
                            case 7: // Yearly on month
                            case 9: // Yearly on position
                            case 10: // Other
                                return 5;
                            case 6: // Monthly on day (1st of month)
                                return 3;
                            case 8: // Yearly on day
                                return 4;
                        }
                    }
                    model: [
                        {key: "never", display: i18n("Never"), interval: -1},
                        {key: "daily", display: i18n("Daily"), interval: eventEditorSheet.eventWrapper.recurrenceIntervals.Daily},
                        {key: "weekly", display: i18n("Weekly"), interval: eventEditorSheet.eventWrapper.recurrenceIntervals.Weekly},
                        {key: "monthly", display: i18n("Monthly"), interval: eventEditorSheet.eventWrapper.recurrenceIntervals.Monthly},
                        {key: "yearly", display: i18n("Yearly"), interval: eventEditorSheet.eventWrapper.recurrenceIntervals.Yearly},
                        {key: "custom", display: i18n("Custom"), interval: -1}
                    ]
                    popup.z: 1000
                }

                GridLayout {
                    id: customRecurrenceLayout

                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    columns: 5
                    visible: repeatComboBox.currentIndex > 0 // Not "Never" index

                    function setOcurrence() {
                        eventEditorSheet.eventWrapper.setRegularRecurrence(recurScaleRuleCombobox.currentValue, recurFreqRuleSpinbox.value);

                        if(recurScaleRuleCombobox.currentValue === eventEditorSheet.eventWrapper.recurrenceIntervals.Weekly) {
                            weekdayCheckboxRepeater.setWeekdaysRepeat();
                        }
                    }

                    // Custom controls
                    QQC2.Label {
                        visible: repeatComboBox.currentIndex === 5 // "Custom"
                        Layout.columnSpan: 1
                        text: i18n("Every:")
                    }
                    QQC2.SpinBox {
                        id: recurFreqRuleSpinbox

                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        visible: repeatComboBox.currentIndex === 5
                        from: 1
                        value: eventEditorSheet.eventWrapper.recurrenceData.frequency
                        onValueChanged: if(visible) { eventEditorSheet.eventWrapper.recurrenceData.frequency = value }
                    }
                    QQC2.ComboBox {
                        id: recurScaleRuleCombobox

                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        visible: repeatComboBox.currentIndex === 5
                        textRole: recurFreqRuleSpinbox.value > 1 ? "displayPlural" : "displaySingular"
                        valueRole: "interval"
                        onCurrentValueChanged: if(visible) { customRecurrenceLayout.setOcurrence(); }
                        currentIndex: {
                            if(eventEditorSheet.eventWrapper.recurrenceData.type === undefined) {
                                return -1;
                            }

                            switch(eventEditorSheet.eventWrapper.recurrenceData.type) {
                                case 3: // Daily
                                case 4: // Weekly
                                    return eventEditorSheet.eventWrapper.recurrenceData.type - 3
                                case 5: // Monthly on position (e.g. third Monday)
                                case 6: // Monthly on day (1st of month)
                                    return 2;
                                case 7: // Yearly on month
                                case 8: // Yearly on day
                                case 9: // Yearly on position
                                    return 3;
                                default:
                                    return -1;
                            }
                        }

                        model: [
                            {key: "day", displaySingular: i18n("day"), displayPlural: i18n("days"), interval: eventEditorSheet.eventWrapper.recurrenceIntervals.Daily},
                            {key: "week", displaySingular: i18n("week"), displayPlural: i18n("weeks"), interval: eventEditorSheet.eventWrapper.recurrenceIntervals.Weekly},
                            {key: "month", displaySingular: i18n("month"), displayPlural: i18n("months"), interval: eventEditorSheet.eventWrapper.recurrenceIntervals.Monthly},
                            {key: "year", displaySingular: i18n("year"), displayPlural: i18n("years"), interval: eventEditorSheet.eventWrapper.recurrenceIntervals.Yearly},
                        ]
                        delegate: Kirigami.BasicListItem {
                            text: recurFreqRuleSpinbox.value > 1 ? modelData.displayPlural : modelData.displaySingular
                            onClicked: eventEditorSheet.eventWrapper.setRegularRecurrence(modelData.interval, recurFreqRuleSpinbox.value);
                        }
                        popup.z: 1000
                    }

                    // Custom controls specific to weekly
                    GridLayout {
                        id: recurWeekdayRuleLayout

                        Layout.row: 1
                        Layout.column: 1
                        Layout.columnSpan: 4
                        columns: 7
                        visible: recurScaleRuleCombobox.currentIndex === 1 && repeatComboBox.currentIndex === 5 // "week"/"weeks" index

                        Repeater {
                            model: 7
                            delegate: QQC2.Label {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: Qt.locale().dayName(Qt.locale().firstDayOfWeek + index, Locale.ShortFormat)
                            }
                        }

                        Repeater {
                            id: weekdayCheckboxRepeater

                            property var checkboxes: []
                            function setWeekdaysRepeat() {
                                let selectedDays = new Array(7)
                                for(let checkbox of checkboxes) {
                                    // C++ func takes 7 bit array
                                    selectedDays[checkbox.dayNumber] = checkbox.checked
                                }
                                eventEditorSheet.eventWrapper.recurrenceData.weekdays = selectedDays;
                            }

                            model: 7
                            delegate: QQC2.CheckBox {
                                Layout.alignment: Qt.AlignHCenter
                                // We make sure we get dayNumber per the day of the week number used by C++ Qt
                                property int dayNumber: Qt.locale().firstDayOfWeek + index > 7 ?
                                                        Qt.locale().firstDayOfWeek + index - 1 - 7 :
                                                        Qt.locale().firstDayOfWeek + index - 1

                                checked: eventEditorSheet.eventWrapper.recurrenceData.weekdays[dayNumber]
                                onClicked: eventEditorSheet.eventWrapper.recurrenceData.weekdays[dayNumber] = !eventEditorSheet.eventWrapper.recurrenceData.weekdays[dayNumber]
                            }
                        }
                    }

                    // Controls specific to monthly recurrence
                    QQC2.Label {
                        Layout.columnSpan: 1
                        visible: recurScaleRuleCombobox.currentIndex === 2 && repeatComboBox.currentIndex === 5 // "month/months" index
                        text: i18n("On:")
                    }

                    QQC2.ButtonGroup {
                        buttons: monthlyRecurRadioColumn.children
                    }

                    ColumnLayout {
                        id: monthlyRecurRadioColumn

                        Layout.fillWidth: true
                        Layout.columnSpan: 4
                        visible: recurScaleRuleCombobox.currentIndex === 2 && repeatComboBox.currentIndex === 5 // "month/months" index

                        QQC2.RadioButton {
                            property int dateOfMonth: eventStartDateCombo.dateFromText.getDate()

                            text: i18nc("%1 is the day number of month", "the %1 of each month", LabelUtils.numberToString(dateOfMonth))
                            checked: eventEditorSheet.eventWrapper.recurrenceData.type == 6 // Monthly on day (1st of month)
                            onClicked: customRecurrenceLayout.setOcurrence()
                        }
                        QQC2.RadioButton {
                            property int dayOfWeek: eventStartDateCombo.dateFromText.getDay() > 0 ?
                                                    eventStartDateCombo.dateFromText.getDay() - 1 :
                                                    7 // C++ Qt day of week index goes Mon-Sun, 0-7
                            property int weekOfMonth: Math.ceil((eventStartDateCombo.dateFromText.getDate() + 6 - eventStartDateCombo.dateFromText.getDay())/7);
                            property string dayOfWeekString: Qt.locale().dayName(eventStartDateCombo.dateFromText.getDay())

                            text: i18nc("the weekOfMonth dayOfWeekString of each month", "the %1 %2 of each month", LabelUtils.numberToString(weekOfMonth), dayOfWeekString)
                            checked: eventEditorSheet.eventWrapper.recurrenceData.type == 5 // Monthly on position
                            onTextChanged: if(checked) { eventEditorSheet.eventWrapper.setMonthlyPosRecurrence(weekOfMonth, dayOfWeek); }
                            onClicked: eventEditorSheet.eventWrapper.setMonthlyPosRecurrence(weekOfMonth, dayOfWeek)
                        }
                    }


                    // Repeat end controls (visible on all recurrences)
                    QQC2.Label {
                        Layout.columnSpan: 1
                        text: i18n("Ends:")
                    }
                    QQC2.ComboBox {
                        id: endRecurType

                        Layout.fillWidth: true
                        Layout.columnSpan: currentIndex == 0 ? 4 : 2
                        currentIndex: eventEditorSheet.eventWrapper.recurrenceData.duration <= 0 ? // Recurrence duration returns -1 for never ending and 0 when the recurrence
                                    eventEditorSheet.eventWrapper.recurrenceData.duration + 1 :  // end date is set. Any number larger is the set number of recurrences
                                    2
                        textRole: "display"
                        valueRole: "duration"
                        model: [
                            {display: i18n("Never"), duration: -1},
                            {display: i18n("On"), duration: 0},
                            {display: i18n("After"), duration: 1}
                        ]
                        delegate: Kirigami.BasicListItem {
                            text: modelData.display
                            onClicked: eventEditorSheet.eventWrapper.recurrenceData.duration = modelData.duration
                        }
                        popup.z: 1000
                    }
                    QQC2.ComboBox {
                        id: recurEndDateCombo

                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        visible: endRecurType.currentIndex == 1
                        editable: true
                        editText: eventEditorSheet.eventWrapper.recurrenceData.endDateTime.toLocaleDateString(Qt.locale(), Locale.NarrowFormat);

                        inputMethodHints: Qt.ImhDate

                        property date dateFromText: Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
                        property bool validDate: !isNaN(dateFromText.getTime())

                        onDateFromTextChanged: {
                            const datePicker = recurEndDatePicker
                            if (validDate && activeFocus) {
                                datePicker.selectedDate = dateFromText;
                                datePicker.clickedDate = dateFromText;

                                if (visible) {
                                    eventEditorSheet.eventWrapper.recurrenceData.endDateTime = dateFromText
                                }
                            }
                        }

                        popup: QQC2.Popup {
                            id: recurEndDatePopup

                            width: Kirigami.Units.gridUnit * 18
                            height: Kirigami.Units.gridUnit * 18
                            y: parent.y + parent.height
                            z: 1000

                            DatePicker {
                                id: recurEndDatePicker
                                anchors.fill: parent
                                onDatePicked: {
                                    eventEditorSheet.eventWrapper.recurrenceData.endDateTime = pickedDate
                                    recurEndDatePopup.close()
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        visible: endRecurType.currentIndex === 2
                        onVisibleChanged: if (visible) { eventEditorSheet.eventWrapper.setRecurrenceOcurrences(recurOcurrenceEndSpinbox.value) }

                        QQC2.SpinBox {
                            id: recurOcurrenceEndSpinbox
                            Layout.fillWidth: true
                            from: 1
                            value: eventEditorSheet.eventWrapper.recurrenceData.duration
                            onValueChanged: eventEditorSheet.eventWrapper.setRecurrenceOcurrences(value)
                        }
                        QQC2.Label {
                            text: i18np("occurrence", "occurrences", recurOcurrenceEndSpinbox.value)
                        }
                    }

                    QQC2.Label {
                        Layout.columnSpan: 1
                        text: i18n("Exceptions:")
                    }
                    ColumnLayout {
                        Layout.columnSpan: 4
                        QQC2.ComboBox {
                            id: exceptionAddButton
                            Layout.fillWidth: true
                            displayText: i18n("Add recurrence exception")

                            popup: QQC2.Popup {
                                id: recurExceptionPopup

                                width: Kirigami.Units.gridUnit * 18
                                height: Kirigami.Units.gridUnit * 18
                                y: parent.y + parent.height
                                z: 1000

                                DatePicker {
                                    id: recurExceptionPicker
                                    anchors.fill: parent
                                    selectedDate: eventStartDateCombo.dateFromText
                                    onDatePicked: {
                                        eventEditorSheet.eventWrapper.recurrenceExceptionsModel.addExceptionDateTime(pickedDate)
                                        recurExceptionPopup.close()
                                    }
                                }
                            }
                        }

                        Repeater {
                            id: exceptionsRepeater
                            model: eventEditorSheet.eventWrapper.recurrenceExceptionsModel
                            delegate: RowLayout {
                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: date.toLocaleDateString(Qt.locale())
                                }
                                QQC2.Button {
                                    icon.name: "edit-delete-remove"
                                    onClicked: eventEditorSheet.eventWrapper.recurrenceExceptionsModel.deleteExceptionDateTime(date)
                                }
                            }
                        }
                    }
                }

                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                }
                // Restrain the descriptionTextArea from getting too chonky
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: eventForm.wideMode ? Kirigami.Units.gridUnit * 25 : -1
                    Kirigami.FormData.label: i18n("Description:")

                    QQC2.TextArea {
                        id: descriptionTextArea

                        Layout.fillWidth: true
                        placeholderText: i18n("Optional")
                        text: eventEditorSheet.eventWrapper.description
                        onTextChanged: eventEditorSheet.eventWrapper.description = text
                    }
                }

                ColumnLayout {
                    id: remindersColumn

                    Kirigami.FormData.label: i18n("Reminder:")
                    Layout.fillWidth: true

                    property var reminderCombos: []

                    QQC2.Button {
                        id: remindersButton

                        text: i18n("Add reminder")
                        Layout.fillWidth: true

                        onClicked: eventEditorSheet.eventWrapper.remindersModel.addAlarm();
                    }

                    Repeater {
                        id: remindersRepeater

                        Layout.fillWidth: true

                        model: eventEditorSheet.eventWrapper.remindersModel
                        // All of the alarms are handled within the delegates.

                        delegate: RowLayout {
                            Layout.fillWidth: true

                            QQC2.ComboBox {
                                // There is also a chance here to add a feature for the user to pick reminder type.
                                Layout.fillWidth: true

                                property var selectedIndex: 0

                                displayText: LabelUtils.secondsToReminderLabel(startOffset)
                                //textRole: "DisplayNameRole"
                                onCurrentValueChanged: eventEditorSheet.eventWrapper.remindersModel.setData(eventEditorSheet.eventWrapper.remindersModel.index(index, 0),
                                                                                                            currentValue,
                                                                                                            eventEditorSheet.eventWrapper.remindersModel.dataroles.startOffset)
                                onCountChanged: selectedIndex = currentIndex // Gets called *just* before modelChanged
                                onModelChanged: currentIndex = selectedIndex

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
                                    text: LabelUtils.secondsToReminderLabel(modelData)
                                }

                                popup.z: 1000
                            }

                            QQC2.Button {
                                icon.name: "edit-delete-remove"
                                onClicked: eventEditorSheet.eventWrapper.remindersModel.deleteAlarm(model.index);
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: attendeesColumn

                    Kirigami.FormData.label: i18n("Attendees:")
                    Layout.fillWidth: true

                    QQC2.Button {
                        id: attendeesButton
                        text: i18n("Add attendee")
                        Layout.fillWidth: true

                        onClicked: eventEditorSheet.eventWrapper.attendeesModel.addAttendee();
                    }

                    Repeater {
                        model: eventEditorSheet.eventWrapper.attendeesModel
                        // All of the alarms are handled within the delegates.
                        Layout.fillWidth: true

                        delegate: ColumnLayout {
                            Layout.leftMargin: Kirigami.Units.largeSpacing

                            RowLayout {
                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: i18n("Attendee " + String(index + 1))
                                }
                                QQC2.Button {
                                    icon.name: "edit-delete-remove"
                                    onClicked: eventEditorSheet.eventWrapper.attendeesModel.deleteAttendee(index);
                                }
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 5
                                rows: 3
                                Layout.rightMargin: 0

                                QQC2.Label{
                                    text: i18n("Name:")
                                }
                                QQC2.TextField {
                                    Layout.fillWidth: true
                                    Layout.columnSpan: 4
                                    text: model.name
                                    onTextChanged: eventEditorSheet.eventWrapper.attendeesModel.setData(eventEditorSheet.eventWrapper.attendeesModel.index(index, 0),
                                                                                        text,
                                                                                        eventEditorSheet.eventWrapper.attendeesModel.dataroles.name)
                                }

                                QQC2.Label {
                                    text: i18n("Email:")
                                }
                                QQC2.TextField {
                                    Layout.fillWidth: true
                                    Layout.columnSpan: 4
                                    text: model.email
                                    onTextChanged: eventEditorSheet.eventWrapper.attendeesModel.setData(eventEditorSheet.eventWrapper.attendeesModel.index(index, 0),
                                                                                        text,
                                                                                        eventEditorSheet.eventWrapper.attendeesModel.dataroles.email)
                                }
                                QQC2.Label {
                                    text: i18n("Status:")
                                }
                                QQC2.ComboBox {
                                    Layout.fillWidth: true
                                    Layout.columnSpan: 2
                                    model: eventEditorSheet.eventWrapper.attendeesModel.attendeeStatusModel
                                    textRole: "display"
                                    valueRole: "value"
                                    currentIndex: status // role of parent
                                    onCurrentValueChanged: eventEditorSheet.eventWrapper.attendeesModel.setData(eventEditorSheet.eventWrapper.attendeesModel.index(index, 0),
                                                                                        currentValue,
                                                                                        eventEditorSheet.eventWrapper.attendeesModel.dataroles.status)

                                    popup.z: 1000
                                }
                                QQC2.CheckBox {
                                    Layout.fillWidth: true
                                    Layout.columnSpan: 2
                                    text: i18n("Request RSVP")
                                    checked: model.rsvp
                                    onCheckedChanged: eventEditorSheet.eventWrapper.attendeesModel.setData(eventEditorSheet.eventWrapper.attendeesModel.index(index, 0),
                                                                                        checked,
                                                                                        eventEditorSheet.eventWrapper.attendeesModel.dataroles.rsvp)
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: attachmentsColumn

                    Kirigami.FormData.label: i18n("Attachments:")
                    Layout.fillWidth: true

                    QQC2.Button {
                        id: attachmentsButton
                        text: i18n("Add attachment")
                        Layout.fillWidth: true
                        onClicked: attachmentFileDialog.open();

                        FileDialog {
                            id: attachmentFileDialog

                            title: "Add an attachment"
                            folder: shortcuts.home
                            onAccepted: eventEditorSheet.eventWrapper.attachmentsModel.addAttachment(fileUrls)
                        }
                    }

                    Repeater {
                        id: attachmentsRepeater
                        model: eventEditorSheet.eventWrapper.attachmentsModel
                        delegate: RowLayout {
                            QQC2.Label {
                                Layout.fillWidth: true
                                text: attachmentLabel
                            }
                            QQC2.Button {
                                icon.name: "edit-delete-remove"
                                onClicked: eventEditorSheet.eventWrapper.attachmentsModel.deleteAttachment(uri)
                            }
                        }
                    }
                }
            }
        }
    }
}
