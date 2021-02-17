// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.15 as Kirigami

QQC2.Control {
    padding: 0
    topPadding: 0
    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0
    GridLayout {
        anchors.fill: parent
        columns: 7
        columnSpacing: monthPage.isLarge ? 1 : 0
        rowSpacing: monthPage.isLarge ? 1 : 0
        Kirigami.Theme.inherit: false
        
        Repeater {
            model: CalendarManager.monthModel.weekDays
            Controls.Control {
                implicitWidth: monthGrid.width / 7
                Layout.maximumHeight: Kirigami.Units.gridUnit * 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                padding: Kirigami.Units.smallSpacing
                contentItem: Kirigami.Heading {
                    text: modelData
                    level: 2
                    horizontalAlignment: monthPage.isLarge ? Text.AlignRight : Text.AlignHCenter
                }
                background: Rectangle {
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                    color: Kirigami.Theme.backgroundColor
                }
            }
        }

        Repeater {
            model: CalendarManager.monthModel
            delegate: Controls.AbstractButton {
                id: button
                implicitWidth: monthGrid.width / 7
                implicitHeight: (monthGrid.height - Kirigami.Units.gridUnit * 2) / 6
                Layout.fillWidth: true
                Layout.fillHeight: true
                padding: 0
                contentItem: Column {
                    Kirigami.Heading {
                        id: number
                        width: parent.width
                        level: 3
                        text: model.dayNumber
                        horizontalAlignment: Text.AlignHCenter
                        padding: Kirigami.Units.smallSpacing
                        opacity: sameMonth ? 1 : 0.7
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Kirigami.Units.smallSpacing
                        Repeater {
                            model: DelegateModel {
                                model: CalendarManager.monthModel
                                rootIndex: modelIndex(index)
                                delegate: Rectangle {
                                    width: Kirigami.Units.smallSpacing
                                    height: width
                                    radius: width / 2
                                    color: eventColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
