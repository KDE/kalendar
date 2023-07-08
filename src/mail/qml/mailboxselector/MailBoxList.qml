// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import Qt.labs.qmlmodels 1.0

import org.kde.kirigami 2.15 as Kirigami
import org.kde.kitemmodels 1.0
import org.kde.kalendar.mail 1.0

ListView {
    id: mailList

    model: KDescendantsProxyModel {
        id: foldersModel
        model: MailManager.foldersModel
    }

    onModelChanged: currentIndex = -1

    signal folderChosen()

    delegate: DelegateChooser {
        role: 'kDescendantExpandable'

        DelegateChoice {
            roleValue: true

            ColumnLayout {
                spacing: 0
                width: ListView.view.width

                Kirigami.BasicListItem {
                    id: categoryHeader

                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.largeSpacing * 2

                    bottomPadding: Kirigami.Units.largeSpacing
                    leftPadding: Kirigami.Units.largeSpacing * (model.kDescendantLevel )

                    label: model.display
                    highlighted: visualFocus
                    hoverEnabled: false
                    separatorVisible: false

                    labelItem.color: visualFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                    labelItem.font.weight: Font.DemiBold

                    leading: Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                        isMask: true
                        color: categoryHeader.labelItem.color
                        source: "folder-symbolic"
                    }
                    leadingPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                    trailing: Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                        source: model.kDescendantExpanded ? 'arrow-up' : 'arrow-down'
                        isMask: true
                        color: categoryHeader.labelItem.color
                    }

                    onClicked: mailList.model.toggleChildren(index)
                }
            }
        }

        DelegateChoice {
            roleValue: false

            QQC2.ItemDelegate {
                id: controlRoot
                text: model.display
                width: ListView.view.width
                padding: Kirigami.Units.largeSpacing
                leftPadding: Kirigami.Units.largeSpacing * model.kDescendantLevel

                property bool chosen: false

                Connections {
                    target: mailList

                    function onFolderChosen() {
                        if (controlRoot.chosen) {
                            controlRoot.chosen = false;
                            controlRoot.highlighted = true;
                        } else {
                            controlRoot.highlighted = false;
                        }
                    }
                }

                property bool showSelected: (controlRoot.pressed === true || (controlRoot.highlighted === true && applicationWindow().wideScreen))

                background: Rectangle {
                    color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, controlRoot.showSelected ? 0.5 : hoverHandler.hovered ? 0.2 : 0)

                    // indicator rectangle
                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            topMargin: 1
                            bottom: parent.bottom
                            bottomMargin: 1
                        }

                        width: 4
                        visible: controlRoot.highlighted
                        color: Kirigami.Theme.highlightColor
                    }

                    HoverHandler {
                        id: hoverHandler
                        // disable hover input on mobile because touchscreens trigger hover feedback and do not "unhover" in Qt
                        enabled: !Kirigami.Settings.isMobile
                    }
                }

                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing

                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignVCenter
                        source: model.decoration
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        Layout.preferredWidth: Layout.preferredHeight
                    }

                    QQC2.Label {
                        leftPadding: controlRoot.mirrored ? (controlRoot.indicator ? controlRoot.indicator.width : 0) + controlRoot.spacing : 0
                        rightPadding: !controlRoot.mirrored ? (controlRoot.indicator ? controlRoot.indicator.width : 0) + controlRoot.spacing : 0

                        text: controlRoot.text
                        font: controlRoot.font
                        color: Kirigami.Theme.textColor
                        elide: Text.ElideRight
                        visible: controlRoot.text
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        Layout.alignment: Qt.AlignLeft
                        Layout.fillWidth: true
                    }

                    QQC2.Label {
                        property int unreadCount: MailCollectionHelper.unreadCount(model.collection)
                        text: unreadCount
                        visible: unreadCount > 0
                        padding: Kirigami.Units.smallSpacing
                        color: Kirigami.Theme.textColor
                        font: Kirigami.Theme.smallFont
                        Layout.minimumWidth: height
                        horizontalAlignment: Text.AlignHCenter
                        background: Rectangle {
                            visible: unreadCount > 0
                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                            color: Kirigami.Theme.disabledTextColor
                            opacity: 0.3
                            radius: height / 2
                        }
                    }
                }

                onClicked: {
                    model.checkState = model.checkState === 0 ? 2 : 0
                    MailManager.loadMailCollection(foldersModel.mapToSource(foldersModel.index(model.index, 0)));

                    controlRoot.chosen = true;
                    mailList.folderChosen();
                }
            }
        }
    }
}
