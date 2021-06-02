// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami

Item {
	id: datepicker

	signal datePicked(date pickedDate)

	property date selectedDate: new Date() // Decides calendar span
	property double clickedDate: new Date()
	property int year: selectedDate.getFullYear()
	property int month: selectedDate.getMonth()
	property int firstDay: new Date(year, month, 1).getDay() // 0 Sunday to 6 Saturday

	Component.onCompleted: clickedDate = selectedDate.setHours(0,0,0,0)

	function prevMonth() {
		selectedDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth() - 1, selectedDate.getDate())
	}

	function nextMonth() {
		selectedDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth() + 1, selectedDate.getDate())
	}

	function prevYear() {
		selectedDate = new Date(selectedDate.getFullYear() - 1, selectedDate.getMonth(), selectedDate.getDate())
	}

	function nextYear() {
		selectedDate = new Date(selectedDate.getFullYear() + 1, selectedDate.getMonth(), selectedDate.getDate())
	}
	function prevDecade() {
		selectedDate = new Date(selectedDate.getFullYear() - 10, selectedDate.getMonth(), selectedDate.getDate())
	}

	function nextDecade() {
		selectedDate = new Date(selectedDate.getFullYear() + 10, selectedDate.getMonth(), selectedDate.getDate())
	}

	anchors.fill: parent

	ColumnLayout {
		anchors.fill: parent

		RowLayout {
			id: headingRow
			width: parent

			Kirigami.Heading {
				id: monthLabel
				Layout.fillWidth: true
				text: selectedDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
				level: 1
			}
			QQC2.ToolButton {
				icon.name: 'go-previous-view'
				onClicked: {
					if (monthsViewCheck.checked) {
						prevYear()
					} else if (yearsViewCheck.checked) {
						prevDecade()
					} else {
						prevMonth()
					}
				}
			}
			QQC2.ToolButton {
				icon.name: 'go-jump-today'
				onClicked: selectedDate = new Date()
			}
			QQC2.ToolButton {
				icon.name: 'go-next-view'
				onClicked: {
					if (monthsViewCheck.checked) {
						nextYear()
					} else if (yearsViewCheck.checked) {
						nextDecade()
					} else {
						nextMonth()
					}
				}
			}
		}

		QQC2.ButtonGroup {
			buttons: rangeBar.children
		}
		RowLayout {
			id: rangeBar
			Layout.fillWidth: true

			QQC2.ToolButton {
				id: daysViewCheck
				Layout.fillWidth: true
				checkable: true
				checked: true
				text: "Days"
			}
			QQC2.ToolButton {
				id: monthsViewCheck
				Layout.fillWidth: true
				checkable: true
				text: "Months"
			}
			QQC2.ToolButton {
				id: yearsViewCheck
				Layout.fillWidth: true
				checkable: true
				text: "Years"
			}
		}

		QQC2.ButtonGroup {
			buttons: dayGrid.children
		}
		GridLayout {
			id: dayGrid
			visible: daysViewCheck.checked
			columns: 7
			rows: 6
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.topMargin: Kirigami.Units.smallSpacing

			Repeater {
				model: 7
				delegate: QQC2.Label {
					Layout.fillWidth: true
					height: dayGrid / dayGrid.rows
					horizontalAlignment: Text.AlignHCenter
					opacity: 0.7
					text: Qt.locale().dayName(index + Qt.locale().firstDayOfWeek, Locale.ShortFormat) // dayName() loops back over beyond index 6
				}
			}

			Repeater {
				model: dayGrid.columns * dayGrid.rows // 42 cells per month

				delegate: QQC2.Button {
					// Stop days overflowing from the grid by creating an adjusted offset
					property int firstDayOfWeekOffset: Qt.locale().firstDayOfWeek >= 4 ? Qt.locale().firstDayOfWeek - 7 : Qt.locale().firstDayOfWeek
					// .getDay() returns from 0 to 30, add +1 for correct day number, and add locale offset for correct firstDayOfWeek
					property int dateToUse: index - firstDay + 1 - firstDayOfWeekOffset
					property date date: new Date(year, month, dateToUse)
					property bool sameMonth: date.getMonth() == month
					Layout.fillWidth: true
					Layout.fillHeight: true
					flat: true
					checkable: true
					checked: date.valueOf() === clickedDate.valueOf()
					opacity: sameMonth ? 1 : 0.7
					text: date.getDate()
					onClicked: datePicked(date), clickedDate = date.setHours(0,0,0,0)
				}
			}
		}

		GridLayout {
			id: monthGrid
			visible: monthsViewCheck.checked
			columns: 3
			rows: 4
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.topMargin: Kirigami.Units.smallSpacing

			Repeater {
				model: monthGrid.columns * monthGrid.rows
				delegate: QQC2.Button {
					property int monthToUse: index
					property date date: new Date(year, monthToUse)
					Layout.fillWidth: true
					Layout.fillHeight: true
					flat: true
					text: Qt.locale().monthName(date.getMonth())
					onClicked: selectedDate = new Date(date), daysViewCheck.checked = true
				}
			}
		}

		GridLayout {
			id: yearGrid
			visible: yearsViewCheck.checked
			columns: 3
			rows: 4
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.topMargin: Kirigami.Units.smallSpacing

			Repeater {
				model: yearGrid.columns * yearGrid.rows
				delegate: QQC2.Button {
					property int yearToUse: index - 1 + (Math.floor(year/10)*10) // Display a decade, e.g. 2019 - 2030
					property date date: new Date(yearToUse, 0)
					property bool sameDecade: Math.floor(yearToUse / 10) == Math.floor(year / 10)
					Layout.fillWidth: true
					Layout.fillHeight: true
					flat: true
					opacity: sameDecade ? 1 : 0.7
					text: date.getFullYear()
					onClicked: selectedDate = new Date(date), monthsViewCheck.checked = true
				}
			}
		}
	}
}



