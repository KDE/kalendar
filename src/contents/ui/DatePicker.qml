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

			QQC2.Button {
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
			QQC2.Button {
				icon.name: 'go-next-view'
				onClicked: nextMonth()
			}
		}
		GridLayout {
			id: dayGrid
			columns: 7
			rows: 7
			Layout.fillWidth: true
			Layout.fillHeight: true

			Repeater {
				model: 7
				delegate: QQC2.Label {
					Layout.fillWidth: true
					Layout.fillHeight: true
					horizontalAlignment: Text.AlignHCenter

					text: ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index] // Su-Sa
				}
			}

			Repeater {
				model: (dayGrid.columns * dayGrid.rows) - dayGrid.columns // 49 cells per month, minus header row

				delegate: QQC2.Button {
					property int dateToUse: index - firstDay + 1 // .getDay() returns from 0 to 30, add +1 for correct day number
					property date date: new Date(year, month, dateToUse)
					property bool sameMonth: date.getMonth() == month
					Layout.fillWidth: true
					height: dayGrid / 7
					//flat: true
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



