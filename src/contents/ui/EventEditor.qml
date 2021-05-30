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

		Kirigami.Separator {}

		QQC2.CheckBox {
			id: allDayCheckBox
			Kirigami.FormData.label: "All day event:"
		}
		RowLayout {
			Kirigami.FormData.label: "Start:"
			QQC2.ComboBox {
				id: eventStartDateCombo
				editable: true
				enabled: !allDayCheckBox.checked
			}
			QQC2.ComboBox {
				id: eventStartTimeCombo
				editable: true
				enabled: !allDayCheckBox.checked
			}
		}
		RowLayout {
			Kirigami.FormData.label: "End:"
			QQC2.ComboBox {
				id: eventEndDateCombo
				editable: true
				enabled: !allDayCheckBox.checked
			}
			QQC2.ComboBox {
				id: eventEndTimeCombo
				editable: true
				enabled: !allDayCheckBox.checked
			}
		}

		Kirigami.Separator {}

		QQC2.TextArea {
			Kirigami.FormData.label: "Notes:"
			Layout.fillWidth: true
			Layout.fillHeight: true
		}
	}
}
