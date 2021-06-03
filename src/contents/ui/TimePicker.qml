// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami

Item {
	id: timePicker

	signal done()

	anchors.fill: parent

	property int hours: 0
	property int minutes: 0
	property int seconds: 0

	property int minuteMultiples: 5
	property bool secondsPicker: false

	ColumnLayout {
		anchors.fill: parent

		RowLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true

			// For some weird reason, the first swipeview used refuses to change the current index when swiping it.
			// This is a janky workaround.
			QQC2.SwipeView {
				visible: false
				Repeater {
					model: 1
				}
			}

			ColumnLayout {
				Layout.fillWidth: true
				Layout.fillHeight: true

				QQC2.ToolButton {
					Layout.fillWidth: true
					icon.name: "go-up"
					enabled: hourView.currentIndex != 0
					onClicked: hourView.currentIndex -= 1
				}
				QQC2.SwipeView {
					id: hourView
					orientation: Qt.Vertical
					clip: true
					Layout.fillWidth: true
					Layout.fillHeight: true

					Repeater {
						model: 24
						delegate: Kirigami.Heading {
							property int thisIndex: index

							horizontalAlignment: Text.AlignHCenter
							verticalAlignment: Text.AlignVCenter
							opacity: hourView.currentIndex == thisIndex ? 1 : 0.7
							text: modelData < 10 ? String(modelData).padStart(2, "0") : modelData
						}
					}
				}
				QQC2.ToolButton {
					Layout.fillWidth: true
					icon.name: "go-down"
					enabled: hourView.currentIndex < hourView.count - 1
					onClicked: hourView.currentIndex += 1
				}
			}

			Kirigami.Heading {
				Layout.fillWidth: true
				Layout.fillHeight: true
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				text: ":"
			}
			ColumnLayout {
				Layout.fillWidth: true
				Layout.fillHeight: true

				QQC2.ToolButton {
					Layout.fillWidth: true
					icon.name: "go-up"
					enabled: minuteView.currentIndex != 0
					onClicked: minuteView.currentIndex -= 1
				}
				QQC2.SwipeView {
					id: minuteView
					orientation: Qt.Vertical
					clip: true
					Layout.fillWidth: true
					Layout.fillHeight: true

					Repeater {
						model: (60 / timePicker.minuteMultiples) // So we can adjust the minute intervals selectable by the user (model goes up to 59)
						delegate: Kirigami.Heading {
							property int thisIndex: index
							property int minuteToDisplay: modelData * timePicker.minuteMultiples

							horizontalAlignment: Text.AlignHCenter
							verticalAlignment: Text.AlignVCenter
							opacity: minuteView.currentIndex == thisIndex ? 1 : 0.7
							text: minuteToDisplay < 10 ? String(minuteToDisplay).padStart(2, "0") : minuteToDisplay
						}
					}
				}
				QQC2.ToolButton {
					Layout.fillWidth: true
					icon.name: "go-down"
					enabled: minuteView.currentIndex < minuteView.count - 1
					onClicked: minuteView.currentIndex += 1
				}
			}

			Kirigami.Heading {
				Layout.fillWidth: true
				Layout.fillHeight: true
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				visible: timePicker.secondsPicker
				text: ":"
			}

			ColumnLayout {
				Layout.fillWidth: true
				Layout.fillHeight: true
				visible: timePicker.secondsPicker

				QQC2.ToolButton {
					Layout.fillWidth: true
					icon.name: "go-up"
					enabled: secondsView.currentIndex != 0
					onClicked: secondsView.currentIndex -= 1
				}
				QQC2.SwipeView {
					id: secondsView
					orientation: Qt.Vertical
					clip: true
					Layout.fillWidth: true
					Layout.fillHeight: true

					Repeater {
						model: 60
						delegate: Kirigami.Heading {
							property int thisIndex: index

							horizontalAlignment: Text.AlignHCenter
							verticalAlignment: Text.AlignVCenter
							opacity: secondsView.currentIndex == thisIndex ? 1 : 0.7
							text: modelData < 10 ? String(modelData).padStart(2, "0") : modelData
						}
					}
				}
				QQC2.ToolButton {
					Layout.fillWidth: true
					icon.name: "go-down"
					enabled: secondsView.currentIndex < secondsView.count - 1
					onClicked: secondsView.currentIndex += 1
				}
			}
		}

		QQC2.Button {
			Layout.fillWidth: true
			text: "Done"
			onClicked: done()
		}
	}
}

