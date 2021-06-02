// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami

Item {
	id: datepicker

	property date selectedDate: new Date() // Decides calendar span
	property date pickedDate: selectedDate

	function prevMonth() {
		selectedDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth() - 1, selectedDate.getDate())
	}

	function nextMonth() {
		selectedDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth() + 1, selectedDate.getDate())
	}

	property int year: selectedDate.getFullYear()
	property int month: selectedDate.getMonth()
	property int firstDay: new Date(year, month, 1).getDay() // 0 Sunday to 6 Saturday

	anchors.fill: parent

	ColumnLayout {
		anchors.fill: parent

		RowLayout {
			id: headingRow
			width: parent

			QQC2.ToolButton {
				icon.name: 'go-previous-view'
				onClicked: prevMonth()
			}
			Kirigami.Heading {
				id: monthLabel
				Layout.fillWidth: true
				text: selectedDate.toLocaleDateString(Qt.locale(), "<b>MMMM</b> yyyy")
				level: 1
				horizontalAlignment: Text.AlignHCenter
			}
			QQC2.ToolButton {
				icon.name: 'go-next-view'
				onClicked: nextMonth()
			}
		}

		/*QQC2.ButtonGroup {
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
				onClicked: console.log(Qt.locale().firstDayOfWeek)
			}
		}*/

		GridLayout {
			id: dayGrid
			columns: 7
			rows: 7
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.topMargin: Kirigami.Units.smallSpacing

			Repeater {
				model: 7
				delegate: QQC2.Label {
					// We have the week days twice so we can account for the locale offset and still use a simple loop
					property var weekdays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
					Layout.fillWidth: true
					Layout.fillHeight: true
					horizontalAlignment: Text.AlignHCenter
					opacity: 0.7

					text: weekdays[index + Qt.locale().firstDayOfWeek] // Su-Sa
				}
			}

			Repeater {
				model: (dayGrid.columns * dayGrid.rows) // 42 cells per month

				delegate: QQC2.Button {
					// Stop days overflowing from the grid by creating an adjusted offset
					property int firstDayOfWeekOffset: Qt.locale().firstDayOfWeek >= 4 ? Qt.locale().firstDayOfWeek - 7 : Qt.locale().firstDayOfWeek
					// .getDay() returns from 0 to 30, add +1 for correct day number, and add locale offset for correct firstDayOfWeek
					property int dateToUse: index - firstDay + 1 - firstDayOfWeekOffset
					property date date: new Date(year, month, dateToUse)
					property bool sameMonth: date.getMonth() == month
					Layout.fillWidth: true
					height: dayGrid / 7
					flat: true
					checkable: true
					checked: date === pickedDate
					opacity: sameMonth ? 1 : 0.7
					text: date.getDate()
					onClicked: {
						pickedDate = date;
						console.log(pickedDate + ", " + date);
					}

				}
			}
		}
	}
}



