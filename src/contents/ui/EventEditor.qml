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
		standardButtons: QQC2.DialogButtonBox.Ok | QQC2.DialogButtonBox.Cancel
        onRejected: eventEditorSheet.close()
    }

    Kirigami.FormLayout {
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
			QQC2.ComboBox {
				id: eventStartDateCombo
				editable: true
				// Make popup a datepicker
				popup: QQC2.Popup {
					DatePicker {}
					width: parent.width*2
					height: parent.height*10
					z: 1000
				}
			}
			QQC2.ComboBox {
				id: eventStartTimeCombo
				editable: true
				enabled: !allDayCheckBox.checked
				visible: !allDayCheckBox.checked
				// Make a popup a timepicker
			}
		}
		RowLayout {
			Kirigami.FormData.label: "End:"
			visible: !allDayCheckBox.checked
			QQC2.ComboBox {
				id: eventEndDateCombo
				editable: true
				enabled: !allDayCheckBox.checked
				popup: QQC2.Popup {
					width: parent.width*2
					height: Kirigami.Units.gridUnit * 12
					z: 1000
					DatePicker {}
				}
			}
			QQC2.ComboBox {
				id: eventEndTimeCombo
				editable: true
				enabled: !allDayCheckBox.checked
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
