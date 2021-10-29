// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later
import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.0
import QtLocation 5.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0
import "labelutils.js" as LabelUtils

Kirigami.ScrollablePage {
    id: root
    property bool editMode: false

    // Setting the incidenceWrapper here and now causes some *really* weird behaviour.
    // Set it after this component has already been instantiated.
    property var incidenceWrapper
    property bool validDates: {
        if (incidenceWrapper && incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo) {
            return editorLoader.active && editorLoader.item.validEndDate;
        } else if (incidenceWrapper) {
            return editorLoader.active && editorLoader.item.validFormDates && (incidenceWrapper.allDay || incidenceWrapper.incidenceStart <= incidenceWrapper.incidenceEnd);
        } else {
            return false;
        }
    }

    title: if (incidenceWrapper) {
        editMode ? i18nc("%1 is incidence type", "Edit %1", incidenceWrapper.incidenceTypeStr) : i18nc("%1 is incidence type", "Add %1", incidenceWrapper.incidenceTypeStr);
    } else {
        "";
    }

    signal added(IncidenceWrapper incidenceWrapper)
    signal cancel
    signal edited(IncidenceWrapper incidenceWrapper)
    function setNewStart(newStart) {
        if (!isNaN(newStart.getTime()) && incidenceWrapper) {
            const currentStartEndDiff = incidenceWrapper.incidenceEnd.getTime() - incidenceWrapper.incidenceStart.getTime();
            const newEnd = new Date(newStart.getTime() + currentStartEndDiff);
            incidenceWrapper.incidenceStart = newStart;
            incidenceWrapper.incidenceEnd = newEnd;
        }
    }

    Component {
        id: contactsPage
        ContactsPage {
            attendeeAkonadiIds: root.incidenceWrapper.attendeesModel.attendeesAkonadiIds

            onAddAttendee: {
                root.incidenceWrapper.attendeesModel.addAttendee(itemId, email);
                root.flickable.contentY = editorLoader.item.attendeesColumnY;
            }
            onRemoveAttendee: {
                root.incidenceWrapper.attendeesModel.deleteAttendeeFromAkonadiId(itemId);
                root.flickable.contentY = editorLoader.item.attendeesColumnY;
            }
        }
    }
    Loader {
        id: editorLoader
        Layout.fillHeight: true
        Layout.fillWidth: true
        active: incidenceWrapper !== undefined

        sourceComponent: ColumnLayout {
            property alias attendeesColumnY: attendeesColumn.y
            property bool validEndDate: incidenceForm.isTodo ? incidenceEndDateCombo.validDate || !incidenceEndCheckBox.checked : incidenceEndDateCombo.validDate
            property bool validFormDates: validStartDate && (validEndDate || incidenceWrapper.allDay)
            property bool validStartDate: incidenceForm.isTodo ? incidenceStartDateCombo.validDate || !incidenceStartCheckBox.checked : incidenceStartDateCombo.validDate

            Layout.fillHeight: true
            Layout.fillWidth: true

            Kirigami.InlineMessage {
                id: invalidDateMessage
                Layout.fillWidth: true
                // Specify what the problem is to aid user
                text: root.incidenceWrapper.incidenceStart < root.incidenceWrapper.incidenceEnd ? i18n("Invalid dates provided.") : i18n("End date cannot be before start date.")
                type: Kirigami.MessageType.Error
                visible: !root.validDates
            }
            Kirigami.FormLayout {
                id: incidenceForm
                property bool isJournal: root.incidenceWrapper.incidenceType === IncidenceWrapper.TypeJournal
                property bool isTodo: root.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo
                property date todayDate: new Date()

                QQC2.ComboBox {
                    id: calendarCombo

                    // Not using a property from the incidenceWrapper object makes currentIndex send old incidenceWrapper to function
                    property int collectionId: root.incidenceWrapper.collectionId

                    Kirigami.FormData.label: i18n("Calendar:")
                    Layout.fillWidth: true
                    currentIndex: model && collectionId !== -1 ? CalendarManager.getCalendarSelectableIndex(root.incidenceWrapper) : -1
                    model: {
                        if (root.incidenceWrapper.incidenceType === IncidenceWrapper.TypeEvent) {
                            return CalendarManager.selectableEventCalendars;
                        } else if (root.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo) {
                            return CalendarManager.selectableTodoCalendars;
                        }
                    }
                    popup.z: 1000
                    textRole: "display"
                    valueRole: "collectionId"

                    delegate: Kirigami.BasicListItem {
                        icon: decoration
                        label: display

                        onClicked: root.incidenceWrapper.collectionId = collectionId
                    }
                }
                QQC2.TextField {
                    id: summaryField
                    Kirigami.FormData.label: i18n("Summary:")
                    placeholderText: i18n(`Add a title for your ${incidenceWrapper.incidenceTypeStr.toLowerCase()}`)
                    text: root.incidenceWrapper.summary

                    onTextChanged: root.incidenceWrapper.summary = text
                }
                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                }
                RowLayout {
                    Kirigami.FormData.label: i18n("Completion:")
                    Layout.fillWidth: true
                    visible: incidenceForm.isTodo && root.editMode

                    QQC2.Slider {
                        Layout.fillWidth: true
                        from: 0
                        orientation: Qt.Horizontal
                        stepSize: 10.0
                        to: 100.0
                        value: root.incidenceWrapper.todoPercentComplete

                        onValueChanged: root.incidenceWrapper.todoPercentComplete = value
                    }
                    QQC2.Label {
                        text: String(root.incidenceWrapper.todoPercentComplete) + "\%"
                    }
                }
                QQC2.ComboBox {
                    Kirigami.FormData.label: i18n("Priority:")
                    Layout.fillWidth: true
                    currentIndex: root.incidenceWrapper.priority
                    model: [{
                            "display": i18n("Unassigned"),
                            "value": 0
                        }, {
                            "display": i18n("1 (Highest Priority)"),
                            "value": 1
                        }, {
                            "display": i18n("2"),
                            "value": 2
                        }, {
                            "display": i18n("3"),
                            "value": 3
                        }, {
                            "display": i18n("4"),
                            "value": 4
                        }, {
                            "display": i18n("5 (Medium Priority)"),
                            "value": 5
                        }, {
                            "display": i18n("6"),
                            "value": 6
                        }, {
                            "display": i18n("7"),
                            "value": 7
                        }, {
                            "display": i18n("8"),
                            "value": 8
                        }, {
                            "display": i18n("9 (Lowest Priority)"),
                            "value": 9
                        }]
                    textRole: "display"
                    valueRole: "value"
                    visible: incidenceForm.isTodo

                    onCurrentValueChanged: root.incidenceWrapper.priority = currentValue
                }
                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                    visible: incidenceForm.isTodo
                }
                QQC2.CheckBox {
                    id: allDayCheckBox
                    checked: root.incidenceWrapper.allDay
                    text: i18n("All day")

                    onCheckedChanged: root.incidenceWrapper.allDay = checked
                }
                RowLayout {
                    id: incidenceStartLayout
                    Kirigami.FormData.label: i18n("Start:")
                    Layout.fillWidth: true
                    visible: !incidenceForm.isTodo || (incidenceForm.isTodo && !isNaN(root.incidenceWrapper.incidenceStart.getTime()))

                    QQC2.CheckBox {
                        id: incidenceStartCheckBox
                        property date oldDate: new Date()

                        checked: !isNaN(root.incidenceWrapper.incidenceStart.getTime())
                        visible: incidenceForm.isTodo

                        onClicked: {
                            if (!checked) {
                                oldDate = new Date(root.incidenceWrapper.incidenceStart);
                                root.incidenceWrapper.incidenceStart = new Date(undefined);
                            } else {
                                root.incidenceWrapper.incidenceStart = oldDate;
                            }
                        }
                    }
                    DateCombo {
                        id: incidenceStartDateCombo
                        Layout.fillWidth: true
                        dateTime: root.incidenceWrapper.incidenceStart
                        timePicker: incidenceStartTimeCombo.timePicker
                        timeZoneOffset: root.incidenceWrapper.timeZoneUTCOffsetMins

                        onNewDateChosen: root.setNewStart(newDate)
                    }
                    TimeCombo {
                        id: incidenceStartTimeCombo
                        dateTime: root.incidenceWrapper.incidenceStart
                        enabled: !allDayCheckBox.checked && (!incidenceForm.isTodo || incidenceStartCheckBox.checked)
                        timeZoneOffset: root.incidenceWrapper.timeZoneUTCOffsetMins
                        visible: !allDayCheckBox.checked

                        onNewTimeChosen: root.setNewStart(newTime)
                    }
                }
                RowLayout {
                    id: incidenceEndLayout
                    Kirigami.FormData.label: incidenceForm.isTodo ? i18n("Due:") : i18n("End:")
                    Layout.fillWidth: true
                    visible: !incidenceForm.isJournal || incidenceForm.isTodo

                    QQC2.CheckBox {
                        id: incidenceEndCheckBox
                        property date oldDate: new Date()

                        checked: !isNaN(root.incidenceWrapper.incidenceEnd.getTime())
                        visible: incidenceForm.isTodo

                        onClicked: {
                            if (!checked) {
                                oldDate = new Date(root.incidenceWrapper.incidenceEnd);
                                root.incidenceWrapper.incidenceEnd = new Date(undefined);
                            } else {
                                root.incidenceWrapper.incidenceEnd = oldDate;
                            }
                        }
                    }
                    DateCombo {
                        id: incidenceEndDateCombo
                        Layout.fillWidth: true
                        dateTime: root.incidenceWrapper.incidenceEnd
                        enabled: !incidenceForm.isTodo || (incidenceForm.isTodo && incidenceEndCheckBox.checked)
                        timePicker: incidenceEndTimeCombo.timePicker
                        timeZoneOffset: root.incidenceWrapper.timeZoneUTCOffsetMins

                        onNewDateChosen: root.incidenceWrapper.incidenceEnd = newDate
                    }
                    TimeCombo {
                        id: incidenceEndTimeCombo
                        Layout.fillWidth: true
                        dateTime: root.incidenceWrapper.incidenceEnd
                        enabled: (!incidenceForm.isTodo && !allDayCheckBox.checked) || (incidenceForm.isTodo && incidenceEndCheckBox.checked)
                        timeZoneOffset: root.incidenceWrapper.timeZoneUTCOffsetMins
                        visible: !allDayCheckBox.checked

                        onNewTimeChosen: root.incidenceWrapper.incidenceEnd = newTime
                    }
                }
                QQC2.ComboBox {
                    id: timeZoneComboBox
                    Kirigami.FormData.label: i18n("Timezone:")
                    Layout.fillWidth: true
                    currentIndex: model ? timeZonesModel.getTimeZoneRow(root.incidenceWrapper.timeZone) : -1
                    enabled: !incidenceForm.isTodo || (incidenceForm.isTodo && incidenceEndCheckBox.checked)
                    textRole: "display"
                    valueRole: "id"

                    delegate: Kirigami.BasicListItem {
                        label: model.display

                        onClicked: root.incidenceWrapper.timeZone = model.id
                    }
                    model: TimeZoneListModel {
                        id: timeZonesModel
                    }
                }
                QQC2.ComboBox {
                    id: repeatComboBox
                    Kirigami.FormData.label: i18n("Repeat:")
                    Layout.fillWidth: true
                    currentIndex: {
                        switch (root.incidenceWrapper.recurrenceData.type) {
                        case 0:
                            return root.incidenceWrapper.recurrenceData.type;
                        case 3:
                            // Daily
                            return root.incidenceWrapper.recurrenceData.frequency === 1 ? root.incidenceWrapper.recurrenceData.type - 2 : 5;
                        case 4:
                            // Weekly
                            if (root.incidenceWrapper.recurrenceData.frequency === 1) {
                                const hasDay = root.incidenceWrapper.recurrenceData.weekdays.filter(function (x) {
                                        return x === true;
                                    }).length === 0;
                                if (hasDay) {
                                    return root.incidenceWrapper.recurrenceData.type - 2;
                                }
                            }
                            return 5;
                        case 5: // Monthly on position (e.g. third Monday)
                        case 8: // Yearly on day
                        case 9: // Yearly on position
                        case 10:
                            // Other
                            return 5;
                        case 6:
                            // Monthly on day (1st of month)
                            return 3;
                        case 7:
                            // Yearly on month
                            return 4;
                        }
                    }
                    model: [{
                            "key": "never",
                            "display": i18n("Never"),
                            "interval": -1
                        }, {
                            "key": "daily",
                            "display": i18n("Daily"),
                            "interval": IncidenceWrapper.Daily
                        }, {
                            "key": "weekly",
                            "display": i18n("Weekly"),
                            "interval": IncidenceWrapper.Weekly
                        }, {
                            "key": "monthly",
                            "display": i18n("Monthly"),
                            "interval": IncidenceWrapper.Monthly
                        }, {
                            "key": "yearly",
                            "display": i18n("Yearly"),
                            "interval": IncidenceWrapper.Yearly
                        }, {
                            "key": "custom",
                            "display": i18n("Custom"),
                            "interval": -1
                        }]
                    popup.z: 1000
                    textRole: "display"
                    valueRole: "interval"

                    onCurrentIndexChanged: if (currentIndex === 0) {
                        root.incidenceWrapper.clearRecurrences();
                    }

                    delegate: Kirigami.BasicListItem {
                        text: modelData.display

                        onClicked: if (modelData.interval > 0) {
                            root.incidenceWrapper.setRegularRecurrence(modelData.interval);
                        } else {
                            root.incidenceWrapper.clearRecurrences();
                        }
                    }
                }
                Kirigami.FormLayout {
                    id: customRecurrenceLayout
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    visible: repeatComboBox.currentIndex > 0 // Not "Never" index

                    function setOcurrence() {
                        root.incidenceWrapper.setRegularRecurrence(recurScaleRuleCombobox.currentValue, recurFreqRuleSpinbox.value);
                        if (recurScaleRuleCombobox.currentValue === IncidenceWrapper.Weekly) {
                            weekdayCheckboxRepeater.setWeekdaysRepeat();
                        }
                    }

                    // Custom controls
                    RowLayout {
                        Kirigami.FormData.label: i18n("Every:")
                        Layout.fillWidth: true
                        visible: repeatComboBox.currentIndex === 5

                        QQC2.SpinBox {
                            id: recurFreqRuleSpinbox
                            Layout.fillWidth: true
                            from: 1
                            value: root.incidenceWrapper.recurrenceData.frequency

                            onValueChanged: if (visible) {
                                root.incidenceWrapper.setRecurrenceDataItem("frequency", value);
                            }
                        }
                        QQC2.ComboBox {
                            id: recurScaleRuleCombobox
                            Layout.fillWidth: true
                            currentIndex: {
                                if (root.incidenceWrapper.recurrenceData.type === undefined) {
                                    return -1;
                                }
                                switch (root.incidenceWrapper.recurrenceData.type) {
                                case 3: // Daily
                                case 4:
                                    // Weekly
                                    return root.incidenceWrapper.recurrenceData.type - 3;
                                case 5: // Monthly on position (e.g. third Monday)
                                case 6:
                                    // Monthly on day (1st of month)
                                    return 2;
                                case 7: // Yearly on month
                                case 8: // Yearly on day
                                case 9:
                                    // Yearly on position
                                    return 3;
                                default:
                                    return -1;
                                }
                            }
                            model: [{
                                    "key": "day",
                                    "display": i18np("day", "days", recurFreqRuleSpinbox.value),
                                    "interval": IncidenceWrapper.Daily
                                }, {
                                    "key": "week",
                                    "display": i18np("week", "weeks", recurFreqRuleSpinbox.value),
                                    "interval": IncidenceWrapper.Weekly
                                }, {
                                    "key": "month",
                                    "display": i18np("month", "months", recurFreqRuleSpinbox.value),
                                    "interval": IncidenceWrapper.Monthly
                                }, {
                                    "key": "year",
                                    "display": i18np("year", "years", recurFreqRuleSpinbox.value),
                                    "interval": IncidenceWrapper.Yearly
                                }]
                            popup.z: 1000
                            textRole: "display"
                            valueRole: "interval"
                            visible: repeatComboBox.currentIndex === 5

                            onCurrentValueChanged: if (visible) {
                                customRecurrenceLayout.setOcurrence();
                                repeatComboBox.currentIndex = 5; // Otherwise resets to default daily/weekly/etc.
                            }
                            // Make sure it defaults to something
                            onVisibleChanged: if (visible && currentIndex < 0) {
                                currentIndex = 0;
                                customRecurrenceLayout.setOcurrence();
                            }

                            delegate: Kirigami.BasicListItem {
                                text: modelData.display

                                onClicked: {
                                    customRecurrenceLayout.setOcurrence();
                                    repeatComboBox.currentIndex = 5; // Otherwise resets to default daily/weekly/etc.
                                }
                            }
                        }
                    }

                    // Custom controls specific to weekly
                    GridLayout {
                        id: recurWeekdayRuleLayout
                        Layout.fillWidth: true
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

                            model: 7

                            function setWeekdaysRepeat() {
                                let selectedDays = new Array(7);
                                for (let checkbox of checkboxes) {
                                    // C++ func takes 7 bit array
                                    selectedDays[checkbox.dayNumber] = checkbox.checked;
                                }
                                root.incidenceWrapper.setRecurrenceDataItem("weekdays", selectedDays);
                            }

                            delegate: QQC2.CheckBox {
                                // We make sure we get dayNumber per the day of the week number used by C++ Qt
                                property int dayNumber: Qt.locale().firstDayOfWeek + index > 7 ? Qt.locale().firstDayOfWeek + index - 1 - 7 : Qt.locale().firstDayOfWeek + index - 1

                                Layout.alignment: Qt.AlignHCenter
                                checked: root.incidenceWrapper.recurrenceData.weekdays[dayNumber]

                                onClicked: {
                                    let newWeekdays = [...root.incidenceWrapper.recurrenceData.weekdays];
                                    newWeekdays[dayNumber] = !root.incidenceWrapper.recurrenceData.weekdays[dayNumber];
                                    root.incidenceWrapper.setRecurrenceDataItem("weekdays", newWeekdays);
                                }
                            }
                        }
                    }

                    // Controls specific to monthly recurrence
                    QQC2.ButtonGroup {
                        buttons: monthlyRecurRadioColumn.children
                    }
                    ColumnLayout {
                        id: monthlyRecurRadioColumn
                        Kirigami.FormData.label: i18n("On:")
                        Layout.fillWidth: true
                        visible: recurScaleRuleCombobox.currentIndex === 2 && repeatComboBox.currentIndex === 5 // "month/months" index

                        QQC2.RadioButton {
                            property int dateOfMonth: incidenceStartDateCombo.dateFromText.getDate()

                            checked: root.incidenceWrapper.recurrenceData.type === 6 // Monthly on day (1st of month)
                            text: i18nc("%1 is the day number of month", "The %1 of each month", LabelUtils.numberToString(dateOfMonth))

                            onClicked: customRecurrenceLayout.setOcurrence()
                        }
                        QQC2.RadioButton {
                            property int dayOfWeek: incidenceStartDateCombo.dateFromText.getDay() > 0 ? incidenceStartDateCombo.dateFromText.getDay() - 1 : 7 // C++ Qt day of week index goes Mon-Sun, 0-7
                            property string dayOfWeekString: Qt.locale().dayName(incidenceStartDateCombo.dateFromText.getDay())
                            property int weekOfMonth: Math.ceil((incidenceStartDateCombo.dateFromText.getDate() + 6 - incidenceStartDateCombo.dateFromText.getDay()) / 7)

                            checked: root.incidenceWrapper.recurrenceData.type === 5 // Monthly on position
                            text: i18nc("the weekOfMonth dayOfWeekString of each month", "The %1 %2 of each month", LabelUtils.numberToString(weekOfMonth), dayOfWeekString)

                            onClicked: root.incidenceWrapper.setMonthlyPosRecurrence(weekOfMonth, dayOfWeek)
                            onTextChanged: if (checked) {
                                root.incidenceWrapper.setMonthlyPosRecurrence(weekOfMonth, dayOfWeek);
                            }
                        }
                    }

                    // Repeat end controls (visible on all recurrences)
                    RowLayout {
                        Kirigami.FormData.label: i18n("Ends:")
                        Layout.fillWidth: true

                        QQC2.ComboBox {
                            id: endRecurType
                            Layout.fillWidth: true
                            // Recurrence duration returns -1 for never ending and 0 when the recurrence
                            // end date is set. Any number larger is the set number of recurrences
                            currentIndex: root.incidenceWrapper.recurrenceData.duration <= 0 ? root.incidenceWrapper.recurrenceData.duration + 1 : 2
                            model: [{
                                    "display": i18n("Never"),
                                    "duration": -1
                                }, {
                                    "display": i18n("On"),
                                    "duration": 0
                                }, {
                                    "display": i18n("After"),
                                    "duration": 1
                                }]
                            popup.z: 1000
                            textRole: "display"
                            valueRole: "duration"

                            delegate: Kirigami.BasicListItem {
                                text: modelData.display

                                onClicked: root.incidenceWrapper.setRecurrenceDataItem("duration", modelData.duration)
                            }
                        }
                        QQC2.ComboBox {
                            id: recurEndDateCombo
                            property date dateFromText: Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
                            property bool validDate: !isNaN(dateFromText.getTime())

                            Layout.fillWidth: true
                            editText: root.incidenceWrapper.recurrenceData.endDateTime.toLocaleDateString(Qt.locale(), Locale.NarrowFormat)
                            editable: true
                            inputMethodHints: Qt.ImhDate
                            visible: endRecurType.currentIndex === 1

                            onDateFromTextChanged: {
                                const datePicker = recurEndDatePicker;
                                if (validDate && activeFocus) {
                                    datePicker.selectedDate = dateFromText;
                                    datePicker.clickedDate = dateFromText;
                                    if (visible) {
                                        root.incidenceWrapper.setRecurrenceDataItem("endDateTime", dateFromText);
                                    }
                                }
                            }
                            onVisibleChanged: if (visible && isNaN(root.incidenceWrapper.recurrenceData.endDateTime.getTime())) {
                                root.incidenceWrapper.setRecurrenceDataItem("endDateTime", new Date());
                            }

                            popup: QQC2.Popup {
                                id: recurEndDatePopup
                                height: Kirigami.Units.gridUnit * 18
                                width: Kirigami.Units.gridUnit * 18
                                y: parent.y + parent.height
                                z: 1000

                                DatePicker {
                                    id: recurEndDatePicker
                                    anchors.fill: parent

                                    onDatePicked: {
                                        root.incidenceWrapper.setRecurrenceDataItem("endDateTime", pickedDate);
                                        recurEndDatePopup.close();
                                    }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            visible: endRecurType.currentIndex === 2

                            onVisibleChanged: if (visible) {
                                root.incidenceWrapper.setRecurrenceOcurrences(recurOcurrenceEndSpinbox.value);
                            }

                            QQC2.SpinBox {
                                id: recurOcurrenceEndSpinbox
                                Layout.fillWidth: true
                                from: 1
                                value: root.incidenceWrapper.recurrenceData.duration

                                onValueChanged: if (visible) {
                                    root.incidenceWrapper.setRecurrenceOcurrences(value);
                                }
                            }
                            QQC2.Label {
                                text: i18np("occurrence", "occurrences", recurOcurrenceEndSpinbox.value)
                            }
                        }
                    }
                    ColumnLayout {
                        Kirigami.FormData.label: i18n("Exceptions:")
                        Layout.fillWidth: true

                        QQC2.ComboBox {
                            id: exceptionAddButton
                            Layout.fillWidth: true
                            displayText: i18n("Add Recurrence Exception")

                            popup: QQC2.Popup {
                                id: recurExceptionPopup
                                height: Kirigami.Units.gridUnit * 18
                                width: Kirigami.Units.gridUnit * 18
                                y: parent.y + parent.height
                                z: 1000

                                DatePicker {
                                    id: recurExceptionPicker
                                    anchors.fill: parent
                                    selectedDate: incidenceStartDateCombo.dateFromText

                                    onDatePicked: {
                                        root.incidenceWrapper.recurrenceExceptionsModel.addExceptionDateTime(pickedDate);
                                        recurExceptionPopup.close();
                                    }
                                }
                            }
                        }
                        Repeater {
                            id: exceptionsRepeater
                            model: root.incidenceWrapper.recurrenceExceptionsModel

                            delegate: RowLayout {
                                Kirigami.BasicListItem {
                                    Layout.fillWidth: true
                                    text: date.toLocaleDateString(Qt.locale())
                                }
                                QQC2.Button {
                                    icon.name: "edit-delete-remove"

                                    onClicked: root.incidenceWrapper.recurrenceExceptionsModel.deleteExceptionDateTime(date)
                                }
                            }
                        }
                    }
                }
                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                }
                RowLayout {
                    Kirigami.FormData.label: i18n("Location:")
                    Layout.fillWidth: true

                    QQC2.TextField {
                        id: locationField
                        property bool typed: false

                        Layout.fillWidth: true
                        placeholderText: i18n("Optional")
                        text: root.incidenceWrapper.location

                        Keys.onPressed: locationsMenu.open()
                        onTextChanged: root.incidenceWrapper.location = text

                        QQC2.BusyIndicator {
                            anchors.right: parent.right
                            height: parent.height
                            running: locationsModel.status === GeocodeModel.Loading
                            visible: locationsModel.status === GeocodeModel.Loading
                        }
                        QQC2.Menu {
                            id: locationsMenu
                            focus: false
                            width: parent.width
                            y: parent.height // Y is relative to parent

                            Repeater {
                                delegate: QQC2.MenuItem {
                                    text: locationData.address.text

                                    onClicked: root.incidenceWrapper.location = locationData.address.text
                                }
                                model: GeocodeModel {
                                    id: locationsModel
                                    autoUpdate: true
                                    plugin: locationPlugin
                                    query: root.incidenceWrapper.location
                                }
                            }
                            Plugin {
                                id: locationPlugin
                                name: "osm"
                            }
                        }
                    }
                    QQC2.CheckBox {
                        id: mapVisibleCheckBox
                        text: i18n("Show map")
                        visible: Config.enableMaps
                    }
                }
                ColumnLayout {
                    id: mapLayout
                    Layout.fillWidth: true
                    visible: Config.enableMaps && mapVisibleCheckBox.checked

                    Loader {
                        id: mapLoader
                        Layout.fillWidth: true
                        active: visible
                        asynchronous: true
                        height: Kirigami.Units.gridUnit * 16

                        sourceComponent: LocationMap {
                            id: map
                            query: root.incidenceWrapper.location
                            selectMode: true

                            onSelectedLocationAddress: root.incidenceWrapper.location = address
                        }
                    }
                }

                // Restrain the descriptionTextArea from getting too chonky
                ColumnLayout {
                    Kirigami.FormData.label: i18n("Description:")
                    Layout.fillWidth: true
                    Layout.maximumWidth: incidenceForm.wideMode ? Kirigami.Units.gridUnit * 25 : -1

                    QQC2.TextArea {
                        id: descriptionTextArea
                        Layout.fillWidth: true
                        placeholderText: i18n("Optional")
                        text: root.incidenceWrapper.description
                        wrapMode: Text.Wrap

                        onTextChanged: root.incidenceWrapper.description = text
                    }
                }
                RowLayout {
                    Kirigami.FormData.label: i18n("Tags:")
                    Layout.fillWidth: true

                    QQC2.ComboBox {
                        Layout.fillWidth: true
                        displayText: root.incidenceWrapper.categories.length > 0 ? root.incidenceWrapper.categories.join(i18nc("List separator", ", ")) : Kirigami.Settings.tabletMode ? i18n("Tap to set tags…") : i18n("Click to set tags…")
                        model: TagManager.tagModel

                        delegate: Kirigami.CheckableListItem {
                            checked: root.incidenceWrapper.categories.includes(model.display)
                            label: model.display
                            reserveSpaceForIcon: false

                            action: QQC2.Action {
                                onTriggered: {
                                    checked = !checked;
                                    if (root.incidenceWrapper.categories.includes(model.display)) {
                                        root.incidenceWrapper.categories = root.incidenceWrapper.categories.filter(function (tag) {
                                                return tag !== model.display;
                                            });
                                    } else {
                                        root.incidenceWrapper.categories = [...root.incidenceWrapper.categories, model.display];
                                    }
                                }
                            }
                        }
                    }
                    QQC2.Button {
                        text: i18n("Manage tags…")

                        onClicked: KalendarApplication.action("open_tag_manager").trigger()
                    }
                }
                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                }
                ColumnLayout {
                    id: remindersColumn
                    Kirigami.FormData.label: i18n("Reminders:")
                    Kirigami.FormData.labelAlignment: remindersRepeater.count ? Qt.AlignTop : Qt.AlignVCenter
                    Layout.fillWidth: true

                    Repeater {
                        id: remindersRepeater
                        Layout.fillWidth: true
                        model: root.incidenceWrapper.remindersModel

                        // All of the alarms are handled within the delegates.
                        delegate: RowLayout {
                            Layout.fillWidth: true

                            QQC2.ComboBox {
                                property var selectedIndex: 0

                                // There is also a chance here to add a feature for the user to pick reminder type.
                                Layout.fillWidth: true
                                displayText: LabelUtils.secondsToReminderLabel(startOffset)
                                model: [0 // We times by -1 to make times be before incidence
                                    , -1 * 5 * 60 // 5 minutes
                                    , -1 * 10 * 60, -1 * 15 * 60, -1 * 30 * 60, -1 * 45 * 60, -1 * 1 * 60 * 60 // 1 hour
                                    , -1 * 2 * 60 * 60, -1 * 1 * 24 * 60 * 60 // 1 day
                                    , -1 * 2 * 24 * 60 * 60, -1 * 5 * 24 * 60 * 60]
                                popup.z: 1000

                                onCountChanged: selectedIndex = currentIndex // Gets called *just* before modelChanged
                                //textRole: "DisplayNameRole"
                                onCurrentValueChanged: root.incidenceWrapper.remindersModel.setData(root.incidenceWrapper.remindersModel.index(index, 0), currentValue, root.incidenceWrapper.remindersModel.dataroles.startOffset)
                                onModelChanged: currentIndex = selectedIndex

                                // All these times are in seconds.
                                delegate: Kirigami.BasicListItem {
                                    text: LabelUtils.secondsToReminderLabel(modelData)
                                }
                            }
                            QQC2.Button {
                                icon.name: "edit-delete-remove"

                                onClicked: root.incidenceWrapper.remindersModel.deleteAlarm(model.index)
                            }
                        }
                    }
                    QQC2.Button {
                        id: remindersButton
                        Layout.fillWidth: true
                        text: i18n("Add Reminder")

                        onClicked: root.incidenceWrapper.remindersModel.addAlarm()
                    }
                }
                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                }
                ColumnLayout {
                    id: attendeesColumn
                    Kirigami.FormData.label: i18n("Attendees:")
                    Kirigami.FormData.labelAlignment: attendeesRepeater.count ? Qt.AlignTop : Qt.AlignVCenter
                    Layout.fillWidth: true

                    Repeater {
                        id: attendeesRepeater
                        // All of the alarms are handled within the delegates.
                        Layout.fillWidth: true
                        model: root.incidenceWrapper.attendeesModel

                        delegate: Kirigami.AbstractCard {
                            bottomPadding: Kirigami.Units.smallSpacing
                            topPadding: Kirigami.Units.smallSpacing

                            contentItem: Item {
                                implicitHeight: attendeeCardContent.implicitHeight
                                implicitWidth: attendeeCardContent.implicitWidth

                                GridLayout {
                                    id: attendeeCardContent
                                    columns: 6
                                    rows: 4

                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        //IMPORTANT: never put the bottom margin
                                        top: parent.top
                                    }
                                    QQC2.Label {
                                        Layout.column: 0
                                        Layout.row: 0
                                        text: i18n("Name:")
                                    }
                                    QQC2.TextField {
                                        Layout.column: 1
                                        Layout.columnSpan: 4
                                        Layout.fillWidth: true
                                        Layout.row: 0
                                        placeholderText: i18n("Optional")
                                        text: model.name

                                        onTextChanged: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(index, 0), text, AttendeesModel.NameRole)
                                    }
                                    QQC2.Button {
                                        Layout.alignment: Qt.AlignTop
                                        Layout.column: 5
                                        Layout.row: 0
                                        icon.name: "edit-delete-remove"

                                        onClicked: root.incidenceWrapper.attendeesModel.deleteAttendee(index)
                                    }
                                    QQC2.Label {
                                        Layout.column: 0
                                        Layout.row: 1
                                        text: i18n("Email:")
                                    }
                                    QQC2.TextField {
                                        Layout.column: 1
                                        Layout.columnSpan: 4
                                        Layout.fillWidth: true
                                        Layout.row: 1
                                        placeholderText: i18n("Required")
                                        text: model.email

                                        onTextChanged: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(index, 0), text, AttendeesModel.EmailRole)
                                    }
                                    QQC2.Label {
                                        Layout.column: 0
                                        Layout.row: 2
                                        text: i18n("Status:")
                                        visible: root.editMode
                                    }
                                    QQC2.ComboBox {
                                        Layout.column: 1
                                        Layout.columnSpan: 2
                                        Layout.fillWidth: true
                                        Layout.row: 2
                                        currentIndex: status // role of parent
                                        model: root.incidenceWrapper.attendeesModel.attendeeStatusModel
                                        popup.z: 1000
                                        textRole: "display"
                                        valueRole: "value"
                                        visible: root.editMode

                                        onCurrentValueChanged: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(index, 0), currentValue, AttendeesModel.StatusRole)
                                    }
                                    QQC2.CheckBox {
                                        Layout.column: 3
                                        Layout.columnSpan: 2
                                        Layout.fillWidth: true
                                        Layout.row: 2
                                        checked: model.rsvp
                                        text: i18n("Request RSVP")
                                        visible: root.editMode

                                        onCheckedChanged: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(index, 0), checked, AttendeesModel.RSVPRole)
                                    }
                                }
                            }
                        }
                    }
                    QQC2.Button {
                        id: attendeesButton
                        Layout.fillWidth: true
                        text: i18n("Add Attendee")

                        onClicked: attendeeAddChoices.open()

                        QQC2.Menu {
                            id: attendeeAddChoices
                            width: attendeesButton.width
                            y: parent.height // Y is relative to parent

                            QQC2.MenuItem {
                                text: i18n("Choose from Contacts")

                                onClicked: pageStack.push(contactsPage)
                            }
                            QQC2.MenuItem {
                                text: i18n("Fill in Manually")

                                onClicked: root.incidenceWrapper.attendeesModel.addAttendee()
                            }
                        }
                    }
                }
                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                }
                ColumnLayout {
                    id: attachmentsColumn
                    Kirigami.FormData.label: i18n("Attachments:")
                    Kirigami.FormData.labelAlignment: attachmentsRepeater.count ? Qt.AlignTop : Qt.AlignVCenter
                    Layout.fillWidth: true

                    Repeater {
                        id: attachmentsRepeater
                        model: root.incidenceWrapper.attachmentsModel

                        delegate: RowLayout {
                            Kirigami.BasicListItem {
                                Layout.fillWidth: true
                                icon: iconName // Why isn't this icon.name??
                                label: attachmentLabel

                                onClicked: Qt.openUrlExternally(uri)
                            }
                            QQC2.Button {
                                icon.name: "edit-delete-remove"

                                onClicked: root.incidenceWrapper.attachmentsModel.deleteAttachment(uri)
                            }
                        }
                    }
                    QQC2.Button {
                        id: attachmentsButton
                        Layout.fillWidth: true
                        text: i18n("Add Attachment")

                        onClicked: attachmentFileDialog.open()

                        FileDialog {
                            id: attachmentFileDialog
                            folder: shortcuts.home
                            title: "Add an attachment"

                            onAccepted: root.incidenceWrapper.attachmentsModel.addAttachment(fileUrls)
                        }
                    }
                }
            }
        }
    }

    footer: QQC2.DialogButtonBox {
        standardButtons: QQC2.DialogButtonBox.Cancel

        onAccepted: {
            if (editMode) {
                edited(incidenceWrapper);
            } else {
                added(incidenceWrapper);
                if (root.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo) {
                    Config.lastUsedTodoCollection = root.incidenceWrapper.collectionId;
                } else {
                    Config.lastUsedEventCollection = root.incidenceWrapper.collectionId;
                }
                Config.save();
            }
            cancel();
        }
        onRejected: cancel()

        QQC2.Button {
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            enabled: root.validDates && incidenceWrapper.summary && incidenceWrapper.collectionId
            icon.name: editMode ? "document-save" : "list-add"
            text: editMode ? i18n("Save") : i18n("Add")
        }
    }
}
