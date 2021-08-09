// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15 
import org.kde.kalendar 1.0

Kirigami.Page {
    title: i18n("Settings")
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    onBackRequested: {
        if (pageSettingStack.depth > 1 && !pageSettingStack.wideMode && pageSettingStack.currentIndex !== 0) {
            event.accepted = true;
            pageSettingStack.pop();
        }
    }
    Kirigami.PageRow {
        id: pageSettingStack
        anchors.fill: parent
        initialPage: Kirigami.ScrollablePage {
            bottomPadding: 0
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            ListView {
                property list<Kirigami.Action> actions: [
                    Kirigami.Action {
                        text: i18n("General")
                        icon.name: "korganizer"
                        onTriggered: pageSettingStack.push(generalSettingPage)
                    },
                    Kirigami.Action {
                        text: i18n("Accounts")
                        icon.name: "preferences-system-users"
                        onTriggered: pageSettingStack.push(accountsSettingsComponent)
                    },
                    Kirigami.Action {
                        text: i18n("Calendar")
                        icon.name: "korganizer"
                        onTriggered: pageSettingStack.push(calendarsSettingsComponent)
                    },
                    Kirigami.Action {
                        text: i18n("About Kalendar")
                        icon.name: "help-about"
                        onTriggered: pageSettingStack.push(aboutPage)
                    }
                ]
                model: actions
                Component.onCompleted: actions[0].trigger();
                delegate: Kirigami.BasicListItem {
                    action: modelData
                }
            }
        }
    }

    Component {
        id: accountsSettingsComponent
        Kirigami.Page {
            id: calendarsSettingsPage
            title: i18n("Calendars")

            ColumnLayout {
                anchors.fill: parent
                Controls.ScrollView {
                    Component.onCompleted: background.visible = true
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ListView {
                        clip: true
                        model: AgentConfiguration.runningAgents // CalendarManager.collections
                        delegate: Kirigami.SwipeListItem {
                            leftPadding: Kirigami.Units.largeSpacing * 2
                            topPadding: Kirigami.Units.largeSpacing
                            bottomPadding: Kirigami.Units.largeSpacing

                            actions: [
                                Kirigami.Action {
                                    iconName: "view-refresh"
                                    text: i18n("Restart")
                                    onTriggered: AgentConfiguration.restart(index);
                                },
                                Kirigami.Action {
                                    iconName: "entry-edit"
                                    text: i18n("Edit")
                                    onTriggered: AgentConfiguration.edit(index);
                                },
                                Kirigami.Action {
                                    iconName: "delete"
                                    text: i18n("Remove")
                                    onTriggered: {
                                        // TODO add confirmation dialog
                                        AgentConfiguration.remove(index);
                                    }
                                }
                            ]

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
                                    columns: 2
                                    rows: 2

                                    Kirigami.Icon {
                                        source: model.decoration
                                        Layout.rowSpan: 2
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                                        Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                                    }

                                    Controls.Label {
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
                                }
                            }
                        }
                    }
                }
                Component {
                    id: addCalendarOverlay
                    Kirigami.OverlaySheet {
                        id: overlay
                        parent: calendarsSettingsPage.Controls.Overlay.overlay
                        header: Kirigami.Heading {
                            level: 2
                            text: i18n("Add new calendar")
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
                        text: i18n("Add new Calendar")
                        icon.name: "list-add"
                        onClicked: {
                            const item = addCalendarOverlay.createObject(addCalendarOverlay, calendarsSettingsPage.Controls.Overlay.overlay)
                            item.open();
                        }
                    }
                }
            }
        }
    }

    Component {
        id: generalSettingPage
        Kirigami.Page {
            title: i18n("General")

            Kirigami.FormLayout {
                RowLayout {
                    Kirigami.FormData.label: i18n("Enable maps:")

                    Controls.CheckBox {
                        checked: Config.enableMaps
                        onClicked: {
                            Config.enableMaps = !Config.enableMaps;
                            Config.save();
                        }
                    }
                    Controls.Label {
                        font: Kirigami.Theme.smallFont
                        text: i18n("May cause crashing on some systems.")
                    }
                }
            }
        }
    }

    Component {
        id: calendarsSettingsComponent
        Kirigami.Page {
            title: i18n("Calendar")
            ColumnLayout {
                anchors.fill: parent
                Controls.ScrollView {
                    Component.onCompleted: background.visible = true
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ListView {
                        model: CalendarManager.collections
                        delegate: Kirigami.BasicListItem {
                            leftPadding: Kirigami.Units.largeSpacing * kDescendantLevel
                            leading: Controls.CheckBox {
                                visible: model.checkState != null
                                checked: model.checkState == 2
                                onClicked: model.checkState = (checked ? 2 : 0)
                            }
                            label: display
                            icon: decoration
                        }
                    }
                }
            }
        }
    }

    Component {
        id: aboutPage
        Kirigami.AboutPage {
            aboutData: AboutType.aboutData
        }
    }
}
