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
            Layout.fillHeight: true
            Layout.fillWidth: true

            Component.onCompleted: background.visible = true

            ListView {
                Layout.fillHeight: true
                Layout.fillWidth: true
                clip: true
                model: AgentConfiguration.runningAgents // CalendarManager.collections

                delegate: Kirigami.BasicListItem {
                    bottomPadding: Kirigami.Units.largeSpacing // Originally swipelistitem, caused issues in mobile mode
                    leftPadding: Kirigami.Units.largeSpacing * 2
                    topPadding: Kirigami.Units.largeSpacing

                    contentItem: Item {
                        implicitHeight: delegateLayout.implicitHeight
                        implicitWidth: delegateLayout.implicitWidth

                        GridLayout {
                            id: delegateLayout
                            columnSpacing: Kirigami.Units.smallSpacing
                            columns: 4
                            rowSpacing: Kirigami.Units.smallSpacing
                            rows: 3

                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }
                            Kirigami.Icon {
                                Layout.column: 0
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                                Layout.row: 0
                                Layout.rowSpan: 2
                                source: model.decoration
                            }
                            Controls.Label {
                                Layout.column: 1
                                Layout.fillWidth: true
                                Layout.row: 0
                                elide: Text.ElideRight
                                font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.75)
                                font.weight: Font.Light
                                maximumLineCount: 2
                                text: model.display
                                wrapMode: Text.WordWrap
                            }
                            Controls.Label {
                                id: alarmName
                                Layout.column: 1
                                Layout.row: 1
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
                                font.weight: Font.Bold
                                text: model.statusMessage
                                visible: text !== ""
                            }
                            RowLayout {
                                readonly property bool smallScreen: sourcesSettingsPage.width < Kirigami.Units.gridUnit * 30

                                Layout.alignment: Qt.AlignRight
                                Layout.column: smallScreen ? 4 : 2
                                Layout.columnSpan: 2
                                Layout.row: smallScreen ? 3 : 0

                                Controls.ToolButton {
                                    icon.name: "view-refresh"
                                    text: i18n("Restart")

                                    onClicked: AgentConfiguration.restart(index)
                                }
                                Controls.ToolButton {
                                    icon.name: "entry-edit"
                                    text: i18n("Edit")

                                    onClicked: AgentConfiguration.edit(index)
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

                ListView {
                    implicitWidth: Kirigami.Units.gridUnit * 20
                    model: AgentConfiguration.availableAgents

                    delegate: Kirigami.BasicListItem {
                        enabled: AgentConfiguration.availableAgents.flags(AgentConfiguration.availableAgents.index(index, 0)) & Qt.ItemIsEnabled
                        icon: model.decoration
                        label: model.display
                        subtitle: model.description

                        onClicked: {
                            AgentConfiguration.createNew(index);
                            overlay.close();
                            overlay.destroy();
                        }
                    }
                }

                header: Kirigami.Heading {
                    level: 2
                    text: i18n("Add New Calendar Source")
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true

            Controls.Button {
                Layout.alignment: Qt.AlignRight
                icon.name: "list-add"
                text: i18n("Add New Calendar Source…")

                onClicked: {
                    const item = addCalendarOverlay.createObject(addCalendarOverlay, sourcesSettingsPage.Controls.Overlay.overlay);
                    item.open();
                }
            }
        }
    }
}
