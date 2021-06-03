// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0

Kirigami.OverlaySheet {
	id: eventEditorSheet

	header: Kirigami.Heading {
        text: "Event"
    }

    footer: QQC2.DialogButtonBox {
		standardButtons: QQC2.DialogButtonBox.Cancel

		QQC2.Button {
			text: "Add"
			enabled: titleField.text // Also needs to check for selected calendar and date
			QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
		}

        onRejected: eventEditorSheet.close()
    }

    Kirigami.FormLayout {
		id: eventForm
		property date todayDate: new Date()

		QQC2.ComboBox {
			id: calendarCombo
			Kirigami.FormData.label: "Calendar:"
			Layout.fillWidth: true
			model: CalendarManager.collections
			delegate: Kirigami.BasicListItem {
				leftPadding: Kirigami.Units.largeSpacing * kDescendantLevel
				label: display
				icon: decoration
				onClicked: calendarCombo.displayText = display
			}
			popup.z: 1000
		}
		QQC2.TextField {
			id: titleField
			Kirigami.FormData.label: "<b>Title</b>:"
			placeholderText: "Required"
		}
		QQC2.TextField {
			id: locationField
			Kirigami.FormData.label: "Location:"
		}

		Kirigami.Separator {
			Kirigami.FormData.isSection: true
		}

		QQC2.CheckBox {
			id: allDayCheckBox
			Kirigami.FormData.label: "All day event:"
		}
		RowLayout {
			Kirigami.FormData.label: "Start:"
			Layout.fillWidth: true

			QQC2.ComboBox {
				id: eventStartDateCombo
				Layout.fillWidth: true
				editable: true
				editText: eventForm.todayDate.toLocaleDateString(Qt.locale(), Locale.NarrowFormat);
				// Make popup a datepicker
				popup: QQC2.Popup {
					id: eventStartDatePopup
					width: parent.width*2
					height: Kirigami.Units.gridUnit * 18
					z: 1000

					DatePicker {
						id: eventStartDatePicker
						anchors.fill: parent
						onDatePicked: {
							eventStartDateCombo.editText = pickedDate.toLocaleDateString(Qt.locale(), Locale.NarrowFormat)
							eventStartDatePopup.close()
						}
					}
				}
			}
			QQC2.ComboBox {
				id: eventStartTimeCombo
				Layout.fillWidth: true
				editable: true
				enabled: !allDayCheckBox.checked
				visible: !allDayCheckBox.checked
				popup: QQC2.Popup {
					id: eventStartTimePopup
					width: parent.width
					height: parent.width
					z: 1000

					TimePicker {
						onDone: eventStartTimePopup.close()
					}
				}
			}
		}
		RowLayout {
			Kirigami.FormData.label: "End:"
			Layout.fillWidth: true
			visible: !allDayCheckBox.checked

			QQC2.ComboBox {
				id: eventEndDateCombo
				Layout.fillWidth: true
				editable: true
				editText: eventForm.todayDate.toLocaleDateString(Qt.locale(), Locale.NarrowFormat);
				enabled: !allDayCheckBox.checked
				popup: QQC2.Popup {
					id: eventEndDatePopup
					width: parent.width*2
					height: Kirigami.Units.gridUnit * 18
					z: 1000

					DatePicker {
						id: eventEndDatePicker
						anchors.fill: parent
						onDatePicked: {
							eventEndDateCombo.editText = pickedDate.toLocaleDateString(Qt.locale(), Locale.NarrowFormat);
							eventEndDatePopup.close()
						}
					}
				}
			}
			QQC2.ComboBox {
				id: eventEndTimeCombo
				Layout.fillWidth: true
				editable: true
				enabled: !allDayCheckBox.checked
				popup: QQC2.Popup {
					id: eventEndTimePopup
					width: parent.width
					height: parent.width
					z: 1000

					TimePicker {
						onDone: eventEndTimePopup.close()
					}
				}
			}
		}
		QQC2.ComboBox {
			id: repeatComboBox
			Kirigami.FormData.label: "Repeat:"
			Layout.fillWidth: true
			model: ["Never", "Daily", "Weekly", "Monthly", "Yearly"]
			delegate: Kirigami.BasicListItem {
				label: modelData
			}
			popup.z: 1000
		}

		Kirigami.Separator {
			Kirigami.FormData.isSection: true
		}

		QQC2.TextArea {
			id: descriptionTextArea
			Kirigami.FormData.label: "Description:"
			placeholderText: "Add a description..."
			Layout.fillWidth: true
		}
		QQC2.ComboBox {
			id: remindersComboBox
			Kirigami.FormData.label: "Reminder:"
			Layout.fillWidth: true
		}
		QQC2.Button {
			id: attendeesButton
			Kirigami.FormData.label: "Attendees:"
			text: "Add attendees"
			Layout.fillWidth: true
		}
	}
}
