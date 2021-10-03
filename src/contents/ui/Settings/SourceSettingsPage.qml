// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kalendar 1.0

Kirigami.Page {
    id: sourcesSettingsPage
    title: i18n("Calendar Sources")

    ColumnLayout {
        anchors.fill: parent

        Controls.ScrollView {
            Component.onCompleted: background.visible = true
            Layout.fillWidth: true
            Layout.fillHeight: true
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: AgentConfiguration.runningAgents // CalendarManager.collections
                delegate: Kirigami.BasicListItem { // Originally swipelistitem, caused issues in mobile mode
                    leftPadding: Kirigami.Units.largeSpacing * 2
                    topPadding: Kirigami.Units.largeSpacing
                    bottomPadding: Kirigami.Units.largeSpacing

                    contentItem: Item {
                        implicitWidth: delegateLayout.implicitWidth
                        implicitHeight: delegateLayout.implicitHeight

                        GridLayout {
                            id: delegateLayout
                            anchors {
                                left: parent.left
                                top: parent.top
                                right: parent.right
                            }

                            rowSpacing: Kirigami.Units.smallSpacing
                            columnSpacing: Kirigami.Units.smallSpacing
                            columns: 4
                            rows: 3

                            Kirigami.Icon {
                                source: model.decoration
                                Layout.row: 0
                                Layout.column: 0
                                Layout.rowSpan: 2
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                            }

                            Controls.Label {
                                Layout.row: 0
                                Layout.column: 1
                                font.weight: Font.Light
                                font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.75)
                                text: model.display
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WordWrap
                            }

                            Controls.Label {
                                id: alarmName
                                Layout.row: 1
                                Layout.column: 1
                                visible: text !== ""
                                font.weight: Font.Bold
                                color: {
                                    // TODO this is weird
                                    if (model.status === /* running */0) {
                                        return Kirigami.Theme.positiveTextColor;
                                    } else if (model.status === /* idle */1) {
                                        return Kirigami.Theme.disabledTextColor;
                                    } else if (model.status === /* broken */2) {
                                        return Kirigami.Theme.negativeTextColor;
                                    } else {
                                        return Kirigami.Theme.textColor;
                                    }
                                }
                                text: model.statusMessage
                            }

                            RowLayout {
                                readonly property bool smallScreen: sourcesSettingsPage.width < Kirigami.Units.gridUnit * 30
                                Layout.row: smallScreen ? 3 : 0
                                Layout.column: smallScreen ? 4 : 2
                                Layout.columnSpan : 2
                                Layout.alignment: Qt.AlignRight
                                Controls.ToolButton {
                                    icon.name: "view-refresh"
                                    text: i18n("Restart")
                                    onClicked: AgentConfiguration.restart(index);
                                }
                                Controls.ToolButton {
                                    icon.name: "entry-edit"
                                    text: i18n("Edit")
                                    onClicked: AgentConfiguration.edit(index);
                                }
                                Controls.ToolButton {
                                    icon.name: "delete"
                                    text: i18n("Remove")
                                    onClicked: {
                                        // TODO add confirmation dialog
                                        AgentConfiguration.remove(index);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        Component {
            id: addCalendarOverlay
            Kirigami.OverlaySheet {
                id: overlay
                parent: sourcesSettingsPage.Controls.Overlay.overlay
                header: Kirigami.Heading {
                    level: 2
                    text: i18n("Add New Calendar Source")
                }
                ListView {
                    implicitWidth: Kirigami.Units.gridUnit * 20
                    model: AgentConfiguration.availableAgents
                    delegate: Kirigami.BasicListItem {
                        label: model.display
                        icon: model.decoration
                        subtitle: model.description
                        enabled: AgentConfiguration.availableAgents.flags(AgentConfiguration.availableAgents.index(index, 0)) & Qt.ItemIsEnabled
                        onClicked: {
                            AgentConfiguration.createNew(index);
                            overlay.close();
                            overlay.destroy();
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Controls.Button {
                Layout.alignment: Qt.AlignRight
                text: i18n("Add New Calendar Source…")
                icon.name: "list-add"
                onClicked: {
                    const item = addCalendarOverlay.createObject(addCalendarOverlay, sourcesSettingsPage.Controls.Overlay.overlay)
                    item.open();
                }
            }
        }
    }
}
