// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15 
import QtQuick.Dialogs 1.0
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
                        text: i18n("Views")
                        icon.name: "view-choose"
                        onTriggered: pageSettingStack.push(viewsSettingPage)
                    },
                    Kirigami.Action {
                        text: i18n("Calendar sources")
                        icon.name: "preferences-system-users"
                        onTriggered: pageSettingStack.push(sourcesSettingsComponent)
                    },
                    Kirigami.Action {
                        text: i18n("Calendars")
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
                Component.onCompleted: if(!Kirigami.Settings.isMobile) { actions[0].trigger(); }
                delegate: Kirigami.BasicListItem {
                    action: modelData
                }
            }
        }
    }

    Component {
        id: sourcesSettingsComponent
        Kirigami.Page {
            id: sourcesSettingsPage
            title: i18n("Calendar sources")

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
                                    columns: 2
                                    rows: 3

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

                                    RowLayout {
                                        Layout.row: 2
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
                            text: i18n("Add new calendar source")
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
                        text: i18n("Add new calendar source")
                        icon.name: "list-add"
                        onClicked: {
                            const item = addCalendarOverlay.createObject(addCalendarOverlay, sourcesSettingsPage.Controls.Overlay.overlay)
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
                anchors.fill: parent
                Item {
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: i18n("Maps")
                }
                RowLayout {
                    Kirigami.FormData.label: i18n("Enable maps:")

                    Controls.CheckBox {
                        checked: Config.enableMaps
                        enabled: !Config.isEnableMapsImmutable
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
                Controls.ButtonGroup {
                    buttons: locationMarkerButtonColumn.children
                    exclusive: true
                    onClicked: {
                        Config.locationMarker = button.value;
                        Config.save();
                    }
                }
                Column {
                    id: locationMarkerButtonColumn
                    Kirigami.FormData.label: i18n("Location marker:")
                    Kirigami.FormData.labelAlignment: Qt.AlignTop

                    Controls.RadioButton {
                        property int value: 0 // HACK: Ideally should use config enum
                        text: i18n("Circle (shows area of location)")
                        enabled: Config.enableMaps && !Config.isLocationMarkerImmutable
                        checked: Config.locationMarker === value
                    }
                    Controls.RadioButton {
                        property int value: 1 // HACK: Ideally should use config enum
                        text: i18n("Pin (shows exact location)")
                        enabled: Config.enableMaps && !Config.isLocationMarkerImmutable
                        checked: Config.locationMarker === value
                    }
                }
            }
        }
    }

    Component {
        id: viewsSettingPage

        Kirigami.ScrollablePage {
            title: i18n("Views")
            Kirigami.FormLayout {
                Kirigami.Heading {
                    level: 3
                    Kirigami.FormData.isSection: true
                    text: i18n("Month view settings")
                }
                Controls.ButtonGroup {
                    buttons: weekdayLabelAlignmentButtonColumn.children
                    exclusive: true
                    onClicked: {
                        Config.weekdayLabelAlignment = button.value;
                        Config.save();
                    }
                }
                Column {
                    id: weekdayLabelAlignmentButtonColumn
                    Kirigami.FormData.label: i18n("Weekday label alignment:")
                    Kirigami.FormData.labelAlignment: Qt.AlignTop

                    Controls.RadioButton {
                        property int value: 0 // HACK: Ideally should use config enum
                        text: i18n("Left")
                        enabled: !Config.isWeekdayLabelAlignmentImmutable
                        checked: Config.weekdayLabelAlignment === value
                    }
                    Controls.RadioButton {
                        property int value: 1
                        text: i18n("Center")
                        enabled: !Config.isWeekdayLabelAlignmentImmutable
                        checked: Config.weekdayLabelAlignment === value
                    }
                    Controls.RadioButton {
                        property int value: 2
                        text: i18n("Right")
                        enabled: !Config.isWeekdayLabelAlignmentImmutable
                        checked: Config.weekdayLabelAlignment === value
                    }
                }
                Controls.ButtonGroup {
                    buttons: weekdayLabelLengthButtonColumn.children
                    exclusive: true
                    onClicked: {
                        Config.weekdayLabelLength = button.value;
                        Config.save();
                    }
                }
                Column {
                    id: weekdayLabelLengthButtonColumn
                    Kirigami.FormData.label: i18n("Weekday label length:")
                    Kirigami.FormData.labelAlignment: Qt.AlignTop

                    Controls.RadioButton {
                        property int value: 0 // HACK: Ideally should use config enum
                        text: i18n("Full name (Monday)")
                        enabled: !Config.isWeekdayLabelLengthImmutable
                        checked: Config.weekdayLabelLength === value
                    }
                    Controls.RadioButton {
                        property int value: 1
                        text: i18n("Abbreviated (Mon)")
                        enabled: !Config.isWeekdayLabelLengthImmutable
                        checked: Config.weekdayLabelLength === value
                    }
                    Controls.RadioButton {
                        property int value: 2
                        text: i18n("Letter only (M)")
                        enabled: !Config.isWeekdayLabelLengthImmutable
                        checked: Config.weekdayLabelLength === value
                    }
                }
                Controls.CheckBox {
                    text: i18n("Show week numbers")
                    checked: Config.showWeekNumbers
                    enabled: !Config.isShowWeekNumbersImmutable
                    onClicked: {
                        Config.showWeekNumbers = !Config.showWeekNumbers;
                        Config.save();
                    }
                }

                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: i18n("Schedule view settings")
                }
                Column {
                    Kirigami.FormData.label: i18n("Headers:")
                    Kirigami.FormData.labelAlignment: Qt.AlignTop

                    Controls.CheckBox {
                        text: i18n("Show month header")
                        checked: Config.showMonthHeader
                        enabled: !Config.isShowMonthHeaderImmutable
                        onClicked: {
                            Config.showMonthHeader = !Config.showMonthHeader;
                            Config.save();
                        }
                    }
                    Controls.CheckBox {
                        text: i18n("Show week headers")
                        checked: Config.showWeekHeaders
                        enabled: !Config.isShowWeekHeadersImmutable
                        onClicked: {
                            Config.showWeekHeaders = !Config.showWeekHeaders;
                            Config.save();
                        }
                    }
                }
            }
        }
    }

    Component {
        id: calendarsSettingsComponent
        Kirigami.Page {
            title: i18n("Calendars")
            ColumnLayout {
                anchors.fill: parent
                Controls.ScrollView {
                    Component.onCompleted: background.visible = true
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ListView {
                        id: collectionsList

                        model: CalendarManager.collections
                        delegate: Kirigami.BasicListItem {
                            property int itemCollectionId: collectionId
                            leftPadding: ((Kirigami.Units.gridUnit * 2) * (kDescendantLevel - 1)) + Kirigami.Units.largeSpacing
                            leading: Controls.CheckBox {
                                visible: model.checkState != null
                                checked: model.checkState == 2
                                onClicked: model.checkState = (checked ? 2 : 0)
                            }
                            trailing: Rectangle {
                                Layout.fillHeight: true
                                width: height
                                radius: 5
                                color: collectionColor
                                visible: collectionColor !== undefined
                            }
                            label: display
                            icon: decoration
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Controls.Button {
                        Layout.alignment: Qt.AlignRight
                        text: i18n("Change calendar color")
                        icon.name: "edit-entry"
                        enabled: collectionsList.currentItem && collectionsList.currentItem.trailing.visible
                        onClicked: {
                            colorDialog.color = collectionsList.currentItem.trailing.color;
                            colorDialog.open();
                        }

                        ColorDialog {
                            id: colorDialog
                            title: i18n("Choose calendar color")
                            onAccepted: {
                                CalendarManager.setCollectionColor(collectionsList.currentItem.itemCollectionId, color)
                            }
                            onRejected: {
                                close();
                            }
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
