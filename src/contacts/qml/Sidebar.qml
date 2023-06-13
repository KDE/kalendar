// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kalendar.contact 1.0 as Contact
import org.kde.akonadi 1.0 as Akonadi
import org.kde.kalendar.components 1.0
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0

Kirigami.OverlayDrawer {
    id: root

    signal collectionCheckChanged
    signal closeParentDrawer
    signal deleteCollection(int collectionId, var collectionDetails)

    property Akonadi.AgentConfiguration agentConfiguration: Akonadi.AgentConfiguration {}

    edge: Qt.application.layoutDirection === Qt.RightToLeft ? Qt.RightEdge : Qt.LeftEdge
    modal: !enabled || Kirigami.Settings.isMobile || (applicationWindow().width < Kirigami.Units.gridUnit * 50 && !collapsed) // Only modal when not collapsed, otherwise collapsed won't show.
    onModalChanged: drawerOpen = !modal;

    z: modal ? Math.round(position * 10000000) : 100

    drawerOpen: !Kirigami.Settings.isMobile && enabled

    handleClosedIcon.source: modal ? null : "sidebar-expand-left"
    handleOpenIcon.source: modal ? null : "sidebar-collapse-left"
    handleVisible: modal && enabled

    width: Kirigami.Units.gridUnit * 16
    Behavior on width {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
    }

    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    contentItem: ColumnLayout {
        id: container

        spacing: 0
        clip: true

        QQC2.ToolBar {
            id: toolbar

            Layout.fillWidth: true
            Layout.preferredHeight: pageStack.globalToolBar.preferredHeight

            leftPadding: root.collapsed ? 0 : Kirigami.Units.smallSpacing
            rightPadding: root.collapsed ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
            topPadding: 0
            bottomPadding: 0

            contentItem: RowLayout {
                Kirigami.SearchField {
                    Layout.fillWidth: true

                    opacity: root.collapsed ? 0 : 1
                    onTextChanged: Contact.ContactManager.filteredContacts.setFilterFixedString(text)

                    Behavior on opacity {
                        OpacityAnimator {
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: collectionList

                model: KDescendantsProxyModel {
                    model: Contact.ContactManager.contactCollections
                }

                delegate: DelegateChooser {
                    role: 'kDescendantExpandable'

                    DelegateChoice {
                        roleValue: true

                        Kirigami.BasicListItem {
                            id: collectionSourceItem

                            required property int index
                            required property string displayName
                            required property var decoration
                            required property var model
                            required property var collection
                            required property int kDescendantLevel
                            required property bool kDescendantExpanded
                            required property int collectionId
                            required property var checkState
                            required property color collectionColor

                            Layout.topMargin: 2 * Kirigami.Units.largeSpacing
                            width: ListView.view.width

                            label: displayName
                            labelItem {
                                color: visualFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                                font.weight: Font.DemiBold
                            }
                            leftPadding: if (Kirigami.Settings.isMobile) {
                                (Kirigami.Units.largeSpacing * 2 * kDescendantLevel)
                                    + (Kirigami.Units.iconSizes.smallMedium * (kDescendantLevel - 1))
                            } else {
                                (Kirigami.Units.largeSpacing * kDescendantLevel)
                                    + (Kirigami.Units.iconSizes.smallMedium * (kDescendantLevel - 1))
                            }
                            hoverEnabled: false
                            enabled: !root.parentDrawerCollapsed

                            separatorVisible: false

                            leadingPadding: if (Kirigami.Settings.isMobile) {
                                Kirigami.Units.largeSpacing * 2;
                            } else {
                                Kirigami.Units.largeSpacing
                            }
                            leading: Kirigami.Icon {
                                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                color: collectionSourceItem.labelItem.color
                                isMask: true
                                source: collectionSourceItem.decoration
                            }

                            Connections {
                                target: root.agentConfiguration

                                function onAgentProgressChanged(agentData) {
                                    if (agentData.instanceId === collectionSourceItem.collection.resource &&
                                        agentData.status === Akonadi.AgentConfiguration.Running) {

                                        loadingIndicator.visible = true;
                                    } else if (agentData.instanceId === collectionSourceItem.collection.resource) {
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
                                    source: collectionSourceItem.kDescendantExpanded ? 'arrow-up' : 'arrow-down'
                                    color: collectionSourceItem.labelItem.color
                                    isMask: true
                                }
                                ColoredCheckbox {
                                    id: collectionCheckbox

                                    Layout.fillHeight: true
                                    visible: collectionSourceItem.checkState != null
                                    color: collectionSourceItem.collectionColor ?? Kirigami.Theme.highlightedTextColor
                                    checked: collectionSourceItem.checkState === 2
                                    onCheckedChanged: root.collectionCheckChanged()
                                    onClicked: {
                                        // TODO port away from model
                                        collectionSourceItem.model.checkState = collectionSourceItem.checkState === 0 ? 2 : 0
                                        root.collectionCheckChanged()
                                    }
                                }
                            }

                            onClicked: collectionList.model.toggleChildren(collectionSourceItem.index)
                        }
                    }

                    DelegateChoice {
                        roleValue: false
                        Kirigami.BasicListItem {
                            id: collectionItem

                            required property int index
                            required property string displayName
                            required property var decoration
                            required property var model
                            required property var collection
                            required property int kDescendantLevel
                            required property bool kDescendantExpanded
                            required property int collectionId
                            required property var checkState
                            required property color collectionColor

                            width: ListView.view.width
                            label: displayName
                            labelItem.color: Kirigami.Theme.textColor
                            leftPadding: if (Kirigami.Settings.isMobile) {
                                (Kirigami.Units.largeSpacing * 2 * kDescendantLevel)
                                    + (Kirigami.Units.iconSizes.smallMedium * (kDescendantLevel - 1))
                            } else {
                                (Kirigami.Units.largeSpacing * kDescendantLevel)
                                    + (Kirigami.Units.iconSizes.smallMedium * (kDescendantLevel - 1))
                            }
                            separatorVisible: false
                            enabled: !root.drawerCollapsed

                            leading: Kirigami.Icon {
                                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                source: collectionItem.decoration
                            }
                            leadingPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                            trailing: ColoredCheckbox {
                                id: collectionCheckbox

                                visible: collectionItem.checkState != null
                                color: collectionItem.collectionColor
                                checked: collectionItem.checkState === 2
                                onCheckedChanged: root.collectionCheckChanged()
                            }

                            onClicked: {
                                collectionItem.model.checkState = collectionItem.checkState === 0 ? 2 : 0
                                root.collectionCheckChanged()
                            }
                        }
                    }
                }
            }
        }
    }
}
