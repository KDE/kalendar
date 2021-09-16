// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2020 Han Young <hanyoung@protonmail.com>
// SPDX-FileCopyrightText: 2020 Devin Lin <espidev@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import QtGraphicalEffects 1.15
import org.kde.kalendar 1.0

QQC2.ToolBar {
    id: toolbarRoot
    property int iconSize: Math.round(Kirigami.Units.gridUnit * 1.6)
    property double shrinkIconSize: Math.round(Kirigami.Units.gridUnit * 1.1)
    property double fontSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 0.6)
    property double shrinkFontSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 0.5)

    background: Rectangle {
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.inherit: false
        color: Kirigami.Theme.backgroundColor
        anchors.fill: parent
        layer.enabled: true
        layer.effect: DropShadow {
            color: Qt.rgba(0.0, 0.0, 0.0, 0.33)
            radius: 6
            samples: 8
        }
    }
    RowLayout {
        anchors.fill: parent
        spacing: 0
        Repeater {
            property list<QtObject> actionList: [
                KActionFromAction {
                    kalendarAction: "open_month_view"
                    property string name: "monthView"
                },
                KActionFromAction {
                    kalendarAction: "open_schedule_view"
                    property string name: "scheduleView"
                },
                KActionFromAction {
                    kalendarAction: "open_todo_view"
                    property string name: "todoView"
                }
            ]
            model: actionList

            Rectangle {
                Layout.minimumWidth: parent.width / 5
                Layout.maximumWidth: parent.width / 5
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
                Layout.alignment: Qt.AlignCenter

                Kirigami.Theme.colorSet: Kirigami.Theme.Window
                Kirigami.Theme.inherit: false

                color: mouseArea.pressed ? Qt.darker(Kirigami.Theme.backgroundColor, 1.1) :
                        mouseArea.containsMouse ? Qt.darker(Kirigami.Theme.backgroundColor, 1.03) : Kirigami.Theme.backgroundColor

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                        easing.type: Easing.InOutQuad
                    }
                }

                MouseArea {
                    id: mouseArea
                    hoverEnabled: true
                    anchors.fill: parent
                    onClicked: if (modelData.enabled) {
                        modelData.trigger();
                    }
                    onPressed: {
                        widthAnim.to = toolbarRoot.shrinkIconSize;
                        heightAnim.to = toolbarRoot.shrinkIconSize;
                        widthAnim.restart();
                        heightAnim.restart();
                    }
                    onReleased: {
                        if (!widthAnim.running) {
                            widthAnim.to = toolbarRoot.iconSize;
                            widthAnim.restart();
                        }
                        if (!heightAnim.running) {
                            heightAnim.to = toolbarRoot.iconSize;
                            heightAnim.restart();
                        }
                    }
                }

                ColumnLayout {
                    id: itemColumn
                    anchors.fill: parent
                    spacing: 0 //Kirigami.Units.smallSpacing
                    property color color: modelData.name == pageStack.currentItem.objectName ? Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.highlightColor, Kirigami.Theme.textColor, 0.4) : Kirigami.Theme.textColor

                    Kirigami.Icon {
                        color: parent.color
                        source: model.icon.name
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                        Layout.preferredHeight: toolbarRoot.iconSize
                        Layout.preferredWidth: toolbarRoot.iconSize

                        ColorAnimation on color {
                            easing.type: Easing.Linear
                        }
                        NumberAnimation on Layout.preferredWidth {
                            id: widthAnim
                            easing.type: Easing.Linear
                            duration: 130
                            onFinished: {
                                if (widthAnim.to !== toolbarRoot.iconSize && !mouseArea.pressed) {
                                    widthAnim.to = toolbarRoot.iconSize;
                                    widthAnim.start();
                                }
                            }
                        }
                        NumberAnimation on Layout.preferredHeight {
                            id: heightAnim
                            easing.type: Easing.Linear
                            duration: 130
                            onFinished: {
                                if (heightAnim.to !== toolbarRoot.iconSize && !mouseArea.pressed) {
                                    heightAnim.to = toolbarRoot.iconSize;
                                    heightAnim.start();
                                }
                            }
                        }
                    }

                    QQC2.Label {
                        text: model.text
                        color: parent.color
                        Layout.fillWidth: true
                        horizontalAlignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
