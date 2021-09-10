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

    signal added(IncidenceWrapper incidenceWrapper)
    signal edited(IncidenceWrapper incidenceWrapper)
    signal cancel

    Component {
        id: contactsPage
        ContactsPage {
            attendeeAkonadiIds: root.incidenceWrapper.attendeesModel.attendeesAkonadiIds

            onAddAttendee: {
                root.incidenceWrapper.attendeesModel.addAttendee(itemId, email);
                root.flickable.contentY = editorLoader.item.attendeesColumnY;
            }
            onRemoveAttendee: {
                root.incidenceWrapper.attendeesModel.deleteAttendeeFromAkonadiId(itemId)
                root.flickable.contentY = editorLoader.item.attendeesColumnY;
            }
        }
    }

    // Setting the incidenceWrapper here and now causes some *really* weird behaviour.
    // Set it after this component has already been instantiated.
    property var incidenceWrapper

    property bool editMode: false
    property bool validDates: {
        if(incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo) {
            editorLoader.active && editorLoader.item.validEndDate
        } else {
            editorLoader.active && editorLoader.item.validFormDates &&
            (root.incidenceWrapper.allDay || incidenceWrapper.incidenceStart <= incidenceWrapper.incidenceEnd)
        }
    }

    title: if (incidenceWrapper) {
        editMode ? i18nc("%1 is incidence type", "Edit %1", incidenceWrapper.incidenceTypeStr) :
            i18nc("%1 is incidence type", "Add %1", incidenceWrapper.incidenceTypeStr);
    } else {
        "";
    }

    footer: QQC2.DialogButtonBox {
        standardButtons: QQC2.DialogButtonBox.Cancel

        QQC2.Button {
            icon.name: editMode ? "document-save" : "list-add"
            text: editMode ? i18n("Save") : i18n("Add")
            enabled: root.validDates && incidenceWrapper.summary && incidenceWrapper.collectionId
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
        }

        onRejected: cancel()
        onAccepted: {
            if (editMode) {
                edited(incidenceWrapper);
            } else {
                added(incidenceWrapper);
            }
            cancel();
        }
    }

    Loader {
        id: editorLoader
        Layout.fillWidth: true
        Layout.fillHeight: true

        active: incidenceWrapper !== undefined
        sourceComponent: ColumnLayout {

            Layout.fillWidth: true
            Layout.fillHeight: true

            property bool validStartDate: incidenceForm.isTodo ?
                incidenceStartDateCombo.validDate || !incidenceStartCheckBox.checked :
                incidenceStartDateCombo.validDate
            property bool validEndDate: incidenceForm.isTodo ?
                incidenceEndDateCombo.validDate || !incidenceEndCheckBox.checked :
                incidenceEndDateCombo.validDate
            property bool validFormDates: validStartDate && (validEndDate || incidenceWrapper.allDay)

            property alias attendeesColumnY: attendeesColumn.y

            Kirigami.InlineMessage {
                id: invalidDateMessage

                Layout.fillWidth: true
                visible: !root.validDates
                type: Kirigami.MessageType.Error
                // Specify what the problem is to aid user
                text: root.incidenceWrapper.incidenceStart < root.incidenceWrapper.incidenceEnd ?
                      i18n("Invalid dates provided.") : i18n("End date cannot be before start date.")
            }

            Kirigami.FormLayout {
                id: incidenceForm

                property date todayDate: new Date()
                property bool isTodo: root.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo
                property bool isJournal: root.incidenceWrapper.incidenceType === IncidenceWrapper.TypeJournal

                QQC2.ComboBox {
                    id: calendarCombo

                    Kirigami.FormData.label: i18n("Calendar:")
                    Layout.fillWidth: true

                    // Not using a property from the incidenceWrapper object makes currentIndex send old incidenceWrapper to function
                    property int collectionId: root.incidenceWrapper.collectionId

                    textRole: "display"
                    valueRole: "collectionId"
                    currentIndex: model && collectionId !== -1 ? CalendarManager.getCalendarSelectableIndex(root.incidenceWrapper) : -1

                    // Should default to default collection
                    model: {
                        if(root.incidenceWrapper.incidenceType === IncidenceWrapper.TypeEvent) {
                            return CalendarManager.selectableEventCalendars;
                        } else if (root.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo) {
                            return CalendarManager.selectableTodoCalendars;
                        }
                    }
                    delegate: Kirigami.BasicListItem {
                        label: display
                        icon: decoration
                        onClicked: root.incidenceWrapper.collectionId = collectionId
                    }
                    popup.z: 1000
                }
                QQC2.TextField {
                    id: summaryField

                    Kirigami.FormData.label: i18n("<b>Summary:</b>")
                    placeholderText: i18n("Required")
                    text: root.incidenceWrapper.summary
                    onTextChanged: root.incidenceWrapper.summary = text
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
                        onTextChanged: root.incidenceWrapper.location = text
                        Keys.onPressed: locationsMenu.open()

                        QQC2.BusyIndicator {
                            height: parent.height
                            anchors.right: parent.right
                            running: locationsModel.status === GeocodeModel.Loading
                            visible: locationsModel.status === GeocodeModel.Loading
                        }

                        QQC2.Menu {
                            id: locationsMenu
                            width: parent.width
                            y: parent.height // Y is relative to parent
                            focus: false

                            Repeater {
                                model: GeocodeModel {
                                    id: locationsModel
                                    plugin: locationPlugin
                                    query: root.incidenceWrapper.location
                                    autoUpdate: true
                                }
                                delegate: QQC2.MenuItem {
                                    text: locationData.address.text
                                    onClicked: root.incidenceWrapper.location = locationData.address.text
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
                        height: Kirigami.Units.gridUnit * 16
                        asynchronous: true
                        active: visible

                        sourceComponent: LocationMap {
                            id: map
                            selectMode: true
                            query: root.incidenceWrapper.location
                            onSelectedLocationAddress: root.incidenceWrapper.location = address
                        }
                    }
                }

                // Restrain the descriptionTextArea from getting too chonky
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: incidenceForm.wideMode ? Kirigami.Units.gridUnit * 25 : -1
                    Kirigami.FormData.label: i18n("Description:")

                    QQC2.TextArea {
                        id: descriptionTextArea

                        Layout.fillWidth: true
                        placeholderText: i18n("Optional")
                        text: root.incidenceWrapper.description
                        onTextChanged: root.incidenceWrapper.description = text
                    }
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
                        orientation: Qt.Horizontal
                        from: 0
                        to: 100.0
                        stepSize: 10.0
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
                    onCurrentValueChanged: root.incidenceWrapper.priority = currentValue
                    textRole: "display"
                    valueRole: "value"
                    model: [
                        {display: i18n("Unassigned"), value: 0},
                        {display: i18n("1 (Highest Priority)"), value: 1},
                        {display: i18n("2"), value: 2},
                        {display: i18n("3"), value: 3},
                        {display: i18n("4"), value: 4},
                        {display: i18n("5 (Medium Priority)"), value: 5},
                        {display: i18n("6"), value: 6},
                        {display: i18n("7"), value: 7},
                        {display: i18n("8"), value: 8},
                        {display: i18n("9 (Lowest Priority)"), value: 9}
                    ]
                    visible: incidenceForm.isTodo
                }

                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                    visible: incidenceForm.isTodo
                }

                QQC2.CheckBox {
                    id: allDayCheckBox

                    text: i18n("All day")
                    checked: root.incidenceWrapper.allDay
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
                        onClicked: {
                            if(!checked) {
                                oldDate = new Date(root.incidenceWrapper.incidenceStart)
                                root.incidenceWrapper.incidenceStart = new Date(undefined)
                            } else {
                                root.incidenceWrapper.incidenceStart = oldDate
                            }
                        }
                        visible: incidenceForm.isTodo
                    }


                    DateCombo {
                        id: incidenceStartDateCombo
                        Layout.fillWidth: true
                        timePicker: incidenceStartTimeCombo.timePicker
                        dateTime: root.incidenceWrapper.incidenceStart
                        onNewDateChosen: root.incidenceWrapper.incidenceStart = newDate
                    }
                    TimeCombo {
                        id: incidenceStartTimeCombo
                        dateTime: root.incidenceWrapper.incidenceStart
                        onNewTimeChosen: root.incidenceWrapper.incidenceStart = newTime
                        enabled: !allDayCheckBox.checked && (!incidenceForm.isTodo || incidenceStartCheckBox.checked)
                        visible: !allDayCheckBox.checked
                    }
                }
                RowLayout {
                    id: incidenceEndLayout

                    Kirigami.FormData.label: incidenceForm.isTodo ? i18n("Due:") : i18n("End:")
                    Layout.fillWidth: true
                    visible: (!allDayCheckBox.checked && !incidenceForm.isJournal) || incidenceForm.isTodo

                    QQC2.CheckBox {
                        id: incidenceEndCheckBox

                        property date oldDate: new Date()

                        checked: !isNaN(root.incidenceWrapper.incidenceEnd.getTime())
                        onClicked: {
                            if(!checked) {
                                oldDate = new Date(root.incidenceWrapper.incidenceEnd)
                                root.incidenceWrapper.incidenceEnd = new Date(undefined)
                            } else {
                                root.incidenceWrapper.incidenceEnd = oldDate
                            }
                        }
                        visible: incidenceForm.isTodo
                    }

                    DateCombo {
                        id: incidenceEndDateCombo
                        Layout.fillWidth: true

                        timePicker: incidenceEndTimeCombo.timePicker
                        dateTime: root.incidenceWrapper.incidenceEnd
                        onNewDateChosen: root.incidenceWrapper.incidenceEnd = newDate
                        enabled: (!incidenceForm.isTodo && !allDayCheckBox.checked) || (incidenceForm.isTodo && incidenceEndCheckBox.checked)
                    }
                    TimeCombo {
                        id: incidenceEndTimeCombo

                        Layout.fillWidth: true
                        dateTime: root.incidenceWrapper.incidenceEnd
                        onNewTimeChosen: root.incidenceWrapper.incidenceEnd = newTime
                        enabled: (!incidenceForm.isTodo && !allDayCheckBox.checked) || (incidenceForm.isTodo && incidenceEndCheckBox.checked)
                        visible: !allDayCheckBox.checked
                    }
                }

                QQC2.ComboBox {
                    id: repeatComboBox
                    Kirigami.FormData.label: i18n("Repeat:")
                    Layout.fillWidth: true

                    textRole: "display"
                    valueRole: "interval"
                    onCurrentIndexChanged: if(currentIndex == 0) { root.incidenceWrapper.clearRecurrences() }
                    currentIndex: {
                        switch(root.incidenceWrapper.recurrenceData.type) {
                            case 0:
                                return root.incidenceWrapper.recurrenceData.type;
                            case 3: // Daily
                                return root.incidenceWrapper.recurrenceData.frequency === 1 ?
                                    root.incidenceWrapper.recurrenceData.type - 2 : 5
                            case 4: // Weekly
                                return root.incidenceWrapper.recurrenceData.frequency === 1 ?
                                    (root.incidenceWrapper.recurrenceData.weekdays.filter(x => x === true).length === 0 ?
                                    root.incidenceWrapper.recurrenceData.type - 2 : 5) : 5
                            case 5: // Monthly on position (e.g. third Monday)
                            case 8: // Yearly on day
                            case 9: // Yearly on position
                            case 10: // Other
                                return 5;
                            case 6: // Monthly on day (1st of month)
                                return 3;
                            case 7: // Yearly on month
                                return 4;
                        }
                    }
                    model: [
                        {key: "never", display: i18n("Never"), interval: -1},
                        {key: "daily", display: i18n("Daily"), interval: IncidenceWrapper.Daily},
                        {key: "weekly", display: i18n("Weekly"), interval: IncidenceWrapper.Weekly},
                        {key: "monthly", display: i18n("Monthly"), interval: IncidenceWrapper.Monthly},
                        {key: "yearly", display: i18n("Yearly"), interval: IncidenceWrapper.Yearly},
                        {key: "custom", display: i18n("Custom"), interval: -1}
                    ]
                    delegate: Kirigami.BasicListItem {
                        text: modelData.display
                        onClicked: if (modelData.interval > 0) {
                            root.incidenceWrapper.setRegularRecurrence(modelData.interval)
                        } else {
                            root.incidenceWrapper.clearRecurrences();
                        }
                    }
                    popup.z: 1000
                }

                Kirigami.FormLayout {
                    id: customRecurrenceLayout

                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    visible: repeatComboBox.currentIndex > 0 // Not "Never" index

                    function setOcurrence() {
                        root.incidenceWrapper.setRegularRecurrence(recurScaleRuleCombobox.currentValue, recurFreqRuleSpinbox.value);

                        if(recurScaleRuleCombobox.currentValue === IncidenceWrapper.Weekly) {
                            weekdayCheckboxRepeater.setWeekdaysRepeat();
                        }
                    }

                    // Custom controls
                    RowLayout {
                        Layout.fillWidth: true
                        Kirigami.FormData.label: i18n("Every:")
                        visible: repeatComboBox.currentIndex === 5

                        QQC2.SpinBox {
                            id: recurFreqRuleSpinbox

                            Layout.fillWidth: true
                            from: 1
                            value: root.incidenceWrapper.recurrenceData.frequency
                            onValueChanged: if(visible) { root.incidenceWrapper.setRecurrenceDataItem("frequency", value) }
                        }
                        QQC2.ComboBox {
                            id: recurScaleRuleCombobox

                            Layout.fillWidth: true
                            visible: repeatComboBox.currentIndex === 5
                            // Make sure it defaults to something
                            onVisibleChanged: if(visible && currentIndex < 0) { currentIndex = 0; customRecurrenceLayout.setOcurrence(); }

                            textRole: "display"
                            valueRole: "interval"
                            onCurrentValueChanged: if(visible) {
                                customRecurrenceLayout.setOcurrence();
                                repeatComboBox.currentIndex = 5; // Otherwise resets to default daily/weekly/etc.
                            }
                            currentIndex: {
                                if(root.incidenceWrapper.recurrenceData.type === undefined) {
                                    return -1;
                                }

                                switch(root.incidenceWrapper.recurrenceData.type) {
                                    case 3: // Daily
                                    case 4: // Weekly
                                        return root.incidenceWrapper.recurrenceData.type - 3
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
                                {key: "day", display: i18np("day", "days", recurFreqRuleSpinbox.value), interval: IncidenceWrapper.Daily},
                                {key: "week", display: i18np("week", "weeks", recurFreqRuleSpinbox.value), interval: IncidenceWrapper.Weekly},
                                {key: "month", display: i18np("month", "months", recurFreqRuleSpinbox.value), interval: IncidenceWrapper.Monthly},
                                {key: "year", display: i18np("year", "years", recurFreqRuleSpinbox.value), interval: IncidenceWrapper.Yearly},
                            ]
                            delegate: Kirigami.BasicListItem {
                                text: modelData.display
                                onClicked: {
                                    customRecurrenceLayout.setOcurrence();
                                    repeatComboBox.currentIndex = 5; // Otherwise resets to default daily/weekly/etc.
                                }
                            }

                            popup.z: 1000
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
                            function setWeekdaysRepeat() {
                                let selectedDays = new Array(7)
                                for(let checkbox of checkboxes) {
                                    // C++ func takes 7 bit array
                                    selectedDays[checkbox.dayNumber] = checkbox.checked
                                }
                                root.incidenceWrapper.setRecurrenceDataItem("weekdays", selectedDays);
                            }

                            model: 7
                            delegate: QQC2.CheckBox {
                                Layout.alignment: Qt.AlignHCenter
                                // We make sure we get dayNumber per the day of the week number used by C++ Qt
                                property int dayNumber: Qt.locale().firstDayOfWeek + index > 7 ?
                                                        Qt.locale().firstDayOfWeek + index - 1 - 7 :
                                                        Qt.locale().firstDayOfWeek + index - 1

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

                            text: i18nc("%1 is the day number of month", "The %1 of each month", LabelUtils.numberToString(dateOfMonth))

                            checked: root.incidenceWrapper.recurrenceData.type === 6 // Monthly on day (1st of month)
                            onClicked: customRecurrenceLayout.setOcurrence()
                        }
                        QQC2.RadioButton {
                            property int dayOfWeek: incidenceStartDateCombo.dateFromText.getDay() > 0 ?
                                                    incidenceStartDateCombo.dateFromText.getDay() - 1 :
                                                    7 // C++ Qt day of week index goes Mon-Sun, 0-7
                            property int weekOfMonth: Math.ceil((incidenceStartDateCombo.dateFromText.getDate() + 6 - incidenceStartDateCombo.dateFromText.getDay())/7);
                            property string dayOfWeekString: Qt.locale().dayName(incidenceStartDateCombo.dateFromText.getDay())

                            text: i18nc("the weekOfMonth dayOfWeekString of each month", "The %1 %2 of each month", LabelUtils.numberToString(weekOfMonth), dayOfWeekString)
                            checked: root.incidenceWrapper.recurrenceData.type === 5 // Monthly on position
                            onTextChanged: if(checked) { root.incidenceWrapper.setMonthlyPosRecurrence(weekOfMonth, dayOfWeek); }
                            onClicked: root.incidenceWrapper.setMonthlyPosRecurrence(weekOfMonth, dayOfWeek)
                        }
                    }


                    // Repeat end controls (visible on all recurrences)
                    RowLayout {
                        Layout.fillWidth: true
                        Kirigami.FormData.label: i18n("Ends:")

                        QQC2.ComboBox {
                            id: endRecurType

                            Layout.fillWidth: true
                            // Recurrence duration returns -1 for never ending and 0 when the recurrence
                            // end date is set. Any number larger is the set number of recurrences
                            currentIndex: root.incidenceWrapper.recurrenceData.duration <= 0 ?
                                root.incidenceWrapper.recurrenceData.duration + 1 : 2

                            textRole: "display"
                            valueRole: "duration"
                            model: [
                                {display: i18n("Never"), duration: -1},
                                {display: i18n("On"), duration: 0},
                                {display: i18n("After"), duration: 1}
                            ]
                            delegate: Kirigami.BasicListItem {
                                text: modelData.display
                                onClicked: root.incidenceWrapper.setRecurrenceDataItem("duration", modelData.duration)
                            }
                            popup.z: 1000
                        }
                        QQC2.ComboBox {
                            id: recurEndDateCombo

                            Layout.fillWidth: true
                            visible: endRecurType.currentIndex == 1
                            onVisibleChanged: if (visible && isNaN(root.incidenceWrapper.recurrenceData.endDateTime.getTime())) { root.incidenceWrapper.setRecurrenceDataItem("endDateTime", new Date()); }
                            editable: true
                            editText: root.incidenceWrapper.recurrenceData.endDateTime.toLocaleDateString(Qt.locale(), Locale.NarrowFormat);

                            inputMethodHints: Qt.ImhDate

                            property date dateFromText: Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
                            property bool validDate: !isNaN(dateFromText.getTime())

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
                                        root.incidenceWrapper.setRecurrenceDataItem("endDateTime", pickedDate);
                                        recurEndDatePopup.close();
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: endRecurType.currentIndex === 2
                            onVisibleChanged: if (visible) { root.incidenceWrapper.setRecurrenceOcurrences(recurOcurrenceEndSpinbox.value) }

                            QQC2.SpinBox {
                                id: recurOcurrenceEndSpinbox

                                Layout.fillWidth: true
                                from: 1
                                value: root.incidenceWrapper.recurrenceData.duration
                                onValueChanged: if (visible) { root.incidenceWrapper.setRecurrenceOcurrences(value) }
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

                                width: Kirigami.Units.gridUnit * 18
                                height: Kirigami.Units.gridUnit * 18
                                y: parent.y + parent.height
                                z: 1000

                                DatePicker {
                                    id: recurExceptionPicker
                                    anchors.fill: parent
                                    selectedDate: incidenceStartDateCombo.dateFromText
                                    onDatePicked: {
                                        root.incidenceWrapper.recurrenceExceptionsModel.addExceptionDateTime(pickedDate)
                                        recurExceptionPopup.close()
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
                                // There is also a chance here to add a feature for the user to pick reminder type.
                                Layout.fillWidth: true

                                property var selectedIndex: 0

                                displayText: LabelUtils.secondsToReminderLabel(startOffset)
                                //textRole: "DisplayNameRole"
                                onCurrentValueChanged: root.incidenceWrapper.remindersModel.setData(root.incidenceWrapper.remindersModel.index(index, 0),
                                                                                                            currentValue,
                                                                                                            root.incidenceWrapper.remindersModel.dataroles.startOffset)
                                onCountChanged: selectedIndex = currentIndex // Gets called *just* before modelChanged
                                onModelChanged: currentIndex = selectedIndex

                                model: [0, // We times by -1 to make times be before incidence
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
                                onClicked: root.incidenceWrapper.remindersModel.deleteAlarm(model.index);
                            }
                        }
                    }

                    QQC2.Button {
                        id: remindersButton

                        text: i18n("Add Reminder")
                        Layout.fillWidth: true

                        onClicked: root.incidenceWrapper.remindersModel.addAlarm();
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
                        model: root.incidenceWrapper.attendeesModel
                        // All of the alarms are handled within the delegates.
                        Layout.fillWidth: true

                        delegate: Kirigami.AbstractCard {

                            topPadding: Kirigami.Units.smallSpacing
                            bottomPadding: Kirigami.Units.smallSpacing

                            contentItem: Item {
                                implicitWidth: attendeeCardContent.implicitWidth
                                implicitHeight: attendeeCardContent.implicitHeight

                                GridLayout {
                                    id: attendeeCardContent

                                    anchors {
                                        left: parent.left
                                        top: parent.top
                                        right: parent.right
                                        //IMPORTANT: never put the bottom margin
                                    }

                                    columns: 6
                                    rows: 4

                                    QQC2.Label{
                                        Layout.row: 0
                                        Layout.column: 0
                                        text: i18n("Name:")
                                    }
                                    QQC2.TextField {
                                        Layout.fillWidth: true
                                        Layout.row: 0
                                        Layout.column: 1
                                        Layout.columnSpan: 4
                                        placeholderText: i18n("Optional")
                                        text: model.name
                                        onTextChanged: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(index, 0),
                                                                                                    text,
                                                                                                    AttendeesModel.NameRole)
                                    }

                                    QQC2.Button {
                                        Layout.alignment: Qt.AlignTop
                                        Layout.column: 5
                                        Layout.row: 0
                                        icon.name: "edit-delete-remove"
                                        onClicked: root.incidenceWrapper.attendeesModel.deleteAttendee(index);
                                    }

                                    QQC2.Label {
                                        Layout.row: 1
                                        Layout.column: 0
                                        text: i18n("Email:")
                                    }
                                    QQC2.TextField {
                                        Layout.fillWidth: true
                                        Layout.row: 1
                                        Layout.column: 1
                                        Layout.columnSpan: 4
                                        placeholderText: i18n("Required")
                                        text: model.email
                                        onTextChanged: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(index, 0),
                                                                                                    text,
                                                                                                    AttendeesModel.EmailRole)
                                    }
                                    QQC2.Label {
                                        Layout.row: 2
                                        Layout.column: 0
                                        text: i18n("Status:")
                                        visible: root.editMode
                                    }
                                    QQC2.ComboBox {
                                        Layout.fillWidth: true
                                        Layout.row: 2
                                        Layout.column: 1
                                        Layout.columnSpan: 2
                                        model: root.incidenceWrapper.attendeesModel.attendeeStatusModel
                                        textRole: "display"
                                        valueRole: "value"
                                        currentIndex: status // role of parent
                                        onCurrentValueChanged: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(index, 0),
                                                                                                            currentValue,
                                                                                                            AttendeesModel.StatusRole)

                                        popup.z: 1000
                                        visible: root.editMode
                                    }
                                    QQC2.CheckBox {
                                        Layout.fillWidth: true
                                        Layout.row: 2
                                        Layout.column: 3
                                        Layout.columnSpan: 2
                                        text: i18n("Request RSVP")
                                        checked: model.rsvp
                                        onCheckedChanged: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(index, 0),
                                                                                                       checked,
                                                                                                       AttendeesModel.RSVPRole)
                                        visible: root.editMode
                                    }
                                }
                            }
                        }
                    }

                    QQC2.Button {
                        id: attendeesButton
                        text: i18n("Add Attendee")
                        Layout.fillWidth: true

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
                                onClicked: root.incidenceWrapper.attendeesModel.addAttendee();
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
                                onClicked: root.eventWrapper.attachmentsModel.deleteAttachment(uri)
                            }
                        }
                    }

                    QQC2.Button {
                        id: attachmentsButton
                        text: i18n("Add Attachment")
                        Layout.fillWidth: true
                        onClicked: attachmentFileDialog.open();

                        FileDialog {
                            id: attachmentFileDialog

                            title: "Add an attachment"
                            folder: shortcuts.home
                            onAccepted: root.incidenceWrapper.attachmentsModel.addAttachment(fileUrls)
                        }
                    }
                }
            }
        }
    }
}
