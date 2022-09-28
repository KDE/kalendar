// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.16 as Kirigami
import org.kde.kalendar 1.0
import org.kde.kalendar.contact 1.0
import org.kde.kalendar.mail 1.0
import org.kde.akonadi 1.0
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0

QQC2.ScrollView {
    id: root

    signal collectionCheckChanged
    signal closeParentDrawer
    signal deleteCollection(int collectionId, var collectionDetails)

    readonly property AgentConfiguration agentConfiguration: AgentConfiguration {}
    readonly property var activeTags: Filter.tags

    property var mode: KalendarApplication.Event
    property bool parentDrawerModal: false
    property bool parentDrawerCollapsed: false

    implicitWidth: Kirigami.Units.gridUnit * 16
    contentWidth: availableWidth

    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Kirigami.BasicListItem {
            id: tagsHeadingItem

            property bool expanded: Config.tagsSectionExpanded

            Layout.topMargin: Kirigami.Units.largeSpacing
            separatorVisible: false
            hoverEnabled: false
            visible: TagManager.tagModel.rowCount() > 0 && mode !== KalendarApplication.Contact
            Accessible.name: tagsHeadingItem.expanded ? i18nc('Accessible description of dropdown menu', 'Tags, Expanded') : i18nc('Accessible description of dropdown menu', 'Tags, Collapsed')

            Kirigami.Heading {
                id: headingSizeCalculator
                level: 4
            }

            highlighted: visualFocus
            leading: Kirigami.Icon {
                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                implicitHeight: Kirigami.Units.iconSizes.smallMedium
                isMask: true
                color: tagsHeadingItem.labelItem.color
                source: "action-rss_tag"
            }
            text: i18n("Tags")
            labelItem.color: visualFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            labelItem.font.pointSize: headingSizeCalculator.font.pointSize
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            trailing: Kirigami.Icon {
                implicitWidth: Kirigami.Units.iconSizes.small
                implicitHeight: Kirigami.Units.iconSizes.small
                source: tagsHeadingItem.expanded ? 'arrow-up' : 'arrow-down'
                isMask: true
                color: tagsHeadingItem.labelItem.color
            }
            onClicked: {
                Config.tagsSectionExpanded = !Config.tagsSectionExpanded;
                Config.save();
            }
        }

        Flow {
            id: tagFlow
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Settings.isMobile ?
                Kirigami.Units.largeSpacing * 2 :
                Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing
            visible: TagManager.tagModel.rowCount() > 0 && tagsHeadingItem.expanded && mode !== KalendarApplication.Contact

            Repeater {
                id: tagList

                model: parent.visible ? TagManager.tagModel : []

                delegate: Tag {
                    implicitWidth: itemLayout.implicitWidth > tagFlow.width ? tagFlow.width : itemLayout.implicitWidth
                    text: model.display
                    showAction: false
                    activeFocusOnTab: true
                    backgroundColor: root.activeTags.includes(model.display) ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                    enabled: !root.parentDrawerCollapsed
                    onClicked: Filter.toggleFilterTag(model.display)
                }
            }
        }

        Kirigami.BasicListItem {
            id: collectionHeadingItem

            readonly property bool expanded: Config.collectionsSectionExpanded

            separatorVisible: false
            hoverEnabled: false
            Layout.topMargin: Kirigami.Units.largeSpacing

            leading: Kirigami.Icon {
                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                implicitHeight: Kirigami.Units.iconSizes.smallMedium
                source: if (mode === KalendarApplication.Contact) {
                    return "view-pim-contacts";
                } else {
                    return "view-calendar";
                }
                isMask: true
                color: collectionHeadingItem.labelItem.color
            }
            text: if (mode === KalendarApplication.Contact) {
                return i18n("Contacts");
            } else {
                return i18n("Calendars");
            }
            highlighted: visualFocus
            labelItem.color: visualFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            labelItem.font.pointSize: headingSizeCalculator.font.pointSize
            trailing: Kirigami.Icon {
                implicitWidth: Kirigami.Units.iconSizes.small
                implicitHeight: Kirigami.Units.iconSizes.small
                source: collectionHeadingItem.expanded ? 'arrow-up' : 'arrow-down'
                isMask: true
                color: collectionHeadingItem.labelItem.color
            }
            onClicked: {
                Config.collectionsSectionExpanded = !Config.collectionsSectionExpanded;
                Config.save();
            }
        }

        Repeater {
            id: collectionList

            property var collectionModel: KDescendantsProxyModel {
                model: switch(root.mode) {
                case KalendarApplication.Todo:
                    return CalendarManager.todoCollections;
                case KalendarApplication.Contact:
                    return ContactManager.contactCollections;
                default:
                    return CalendarManager.viewCollections;
                }
            }

            model: collectionHeadingItem.expanded ? collectionModel : []

            delegate: DelegateChooser {
                role: 'kDescendantExpandable'
                DelegateChoice {
                    roleValue: true

                    Kirigami.BasicListItem {
                        id: collectionSourceItem
                        label: display
                        highlighted: visualFocus || incidenceDropArea.containsDrag
                        labelItem.color: visualFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                        labelItem.font.weight: Font.DemiBold
                        Layout.topMargin: 2 * Kirigami.Units.largeSpacing
                        leftPadding: Kirigami.Settings.isMobile ?
                            (Kirigami.Units.largeSpacing * 2 * model.kDescendantLevel) + (Kirigami.Units.iconSizes.smallMedium * (model.kDescendantLevel - 1)) :
                            (Kirigami.Units.largeSpacing * model.kDescendantLevel) + (Kirigami.Units.iconSizes.smallMedium * (model.kDescendantLevel - 1))
                        hoverEnabled: false
                        enabled: !root.parentDrawerCollapsed

                        separatorVisible: false

                        leading: Kirigami.Icon {
                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                            implicitHeight: Kirigami.Units.iconSizes.smallMedium
                            color: collectionSourceItem.labelItem.color
                            isMask: true
                            source: model.decoration
                        }
                        leadingPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                        Connections {
                            target: root.agentConfiguration
                            property var collectionDetails: CalendarManager.getCollectionDetails(collectionId)

                            function onAgentProgressChanged(agentData) {
                                if(agentData.instanceId === collectionDetails.resource &&
                                    agentData.status === AgentConfiguration.Running) {

                                    loadingIndicator.visible = true;
                                } else if (agentData.instanceId === collectionDetails.resource) {
                                    loadingIndicator.visible = false;
                                }
                            }
                        }

                        trailing: RowLayout {
                            QQC2.BusyIndicator {
                                id: loadingIndicator
                                Layout.fillHeight: true
                                padding: 0
                                visible: false
                                running: visible
                            }

                            Kirigami.Icon {
                                implicitWidth: Kirigami.Units.iconSizes.small
                                implicitHeight: Kirigami.Units.iconSizes.small
                                source: model.kDescendantExpanded ? 'arrow-up' : 'arrow-down'
                                color: collectionSourceItem.labelItem.color
                                isMask: true
                            }
                            ColoredCheckbox {
                                id: collectionCheckbox

                                Layout.fillHeight: true
                                visible: model.checkState != null
                                color: model.collectionColor ?? Kirigami.Theme.highlightedTextColor
                                checked: model.checkState === 2
                                onCheckedChanged: root.collectionCheckChanged()
                                onClicked: {
                                    model.checkState = model.checkState === 0 ? 2 : 0
                                    root.collectionCheckChanged()
                                }
                            }
                        }

                        onClicked: collectionList.model.toggleChildren(index)

                        CalendarItemTapHandler {
                            collectionId: model.collectionId
                            collectionDetails: CalendarManager.getCollectionDetails(collectionId)
                            agentConfiguration: root.agentConfiguration
                            enabled: root.mode !== KalendarApplication.Contact
                        }

                        DropArea {
                            id: incidenceDropArea
                            property var collectionDetails: CalendarManager.getCollectionDetails(model.collectionId)
                            parent: collectionSourceItem.contentItem // Otherwise label elide breaks
                            anchors.fill: parent
                            z: 9999
                            enabled: collectionDetails.canCreate
                            onDropped: if(drop.source.objectName === "taskDelegate") {
                                CalendarManager.changeIncidenceCollection(drop.source.incidencePtr, model.collectionId);

                                const pos = mapToItem(applicationWindow().contentItem, x, y);
                                drop.source.caughtX = pos.x;
                                drop.source.caughtY = pos.y;
                                drop.source.caught = true;
                            }
                        }
                    }
                }

                DelegateChoice {
                    roleValue: false
                    Kirigami.BasicListItem {
                        id: collectionItem
                        label: display
                        labelItem.color: Kirigami.Theme.textColor
                        leftPadding: Kirigami.Settings.isMobile ?
                            (Kirigami.Units.largeSpacing * 2 * model.kDescendantLevel) + (Kirigami.Units.iconSizes.smallMedium * (model.kDescendantLevel - 1)) :
                            (Kirigami.Units.largeSpacing * model.kDescendantLevel) + (Kirigami.Units.iconSizes.smallMedium * (model.kDescendantLevel - 1))
                        separatorVisible: false
                        enabled: !root.parentDrawerCollapsed
                        highlighted: visualFocus || incidenceDropArea.containsDrag

                        leading: Kirigami.Icon {
                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                            implicitHeight: Kirigami.Units.iconSizes.smallMedium
                            source: model.decoration
                        }
                        leadingPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                        trailing: ColoredCheckbox {
                            id: collectionCheckbox

                            visible: model.checkState != null
                            color: model.collectionColor
                            checked: model.checkState === 2
                            onCheckedChanged: root.collectionCheckChanged()
                            onClicked: {
                                model.checkState = model.checkState === 0 ? 2 : 0
                                root.collectionCheckChanged()
                            }
                        }

                        onClicked: {
                            Filter.collectionId = collectionId;
                            if (root.parentDrawerModal) {
                                root.closeParentDrawer();
                            }
                        }

                        CalendarItemTapHandler {
                            collectionId: model.collectionId
                            collectionDetails: CalendarManager.getCollectionDetails(collectionId)
                            agentConfiguration: root.agentConfiguration
                            enabled: mode !== KalendarApplication.Contact
                            onDeleteCalendar: root.deleteCollection(collectionId, collectionDetails)
                        }

                        DropArea {
                            id: incidenceDropArea
                            property var collectionDetails: CalendarManager.getCollectionDetails(model.collectionId)
                            parent: collectionItem.contentItem // Otherwise label elide breaks
                            anchors.fill: parent
                            z: 9999
                            enabled: collectionDetails.canCreate
                            onDropped: if(drop.source.objectName === "taskDelegate") {
                                CalendarManager.changeIncidenceCollection(drop.source.incidencePtr, model.collectionId);

                                const pos = mapToItem(applicationWindow().contentItem, x, y);
                                drop.source.caughtX = pos.x;
                                drop.source.caughtY = pos.y;
                                drop.source.caught = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
