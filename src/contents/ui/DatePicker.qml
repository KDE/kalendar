// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0

QQC2.Control {
	anchors.fill: parent
	padding: 0

	GridLayout {
		id: monthLayout
		anchors.fill: parent
		columns: 7

		Repeater {
			model: CalendarManager.monthModel.weekDays
			QQC2.Control {
				implicitWidth: monthGrid.width / 7
				Layout.maximumHeight: Kirigami.Units.gridUnit * 2
				Layout.fillWidth: true
				Layout.fillHeight: true
				padding: Kirigami.Units.smallSpacing
				contentItem: Kirigami.Heading {
					text: modelData
					level: 2
					horizontalAlignment: Text.AlignHCenter
				}
			}
		}

		Repeater {
			model: CalendarManager.monthModel
			delegate: QQC2.AbstractButton {
				implicitWidth: monthGrid.width / 7
				implicitHeight: (monthGrid.height - Kirigami.Units.gridUnit * 2) / 6
				Layout.fillWidth: true
				Layout.fillHeight: true
				padding: 0
				contentItem: Kirigami.Heading {
					id: number
					width: parent.width
					level: 3
					text: model.dayNumber
					horizontalAlignment: Text.AlignHCenter
					padding: Kirigami.Units.smallSpacing
					opacity: sameMonth ? 1 : 0.7
				}
			}
		}
	}
}

