// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2022 Devin Lin <espidev@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import QtGraphicalEffects 1.15

import org.kde.kalendar 1.0
import org.kde.kalendar.mail 1.0
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kitemmodels 1.0 as KItemModels

import './mailpartview'
import './private'

QQC2.Page {
    id: root
    property var item
    property string subject
    property string from
    property string sender
    property string to
    property date dateTime

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    padding: Kirigami.Units.largeSpacing * 2

    header: QQC2.ToolBar {
        id: mailHeader
        padding: root.padding

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View

        background: Item {
            Rectangle {
                anchors.fill: parent
                color: Kirigami.Theme.alternateBackgroundColor
            }

            Kirigami.Separator {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
            }

            Kirigami.Separator {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }

        ColumnLayout {
            width: mailHeader.width - mailHeader.leftPadding - mailHeader.rightPadding
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true

                QQC2.Label {
                    text: root.from
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: root.dateTime.toLocaleString(Qt.locale(), Locale.ShortFormat)
                    horizontalAlignment: Text.AlignRight
                }
            }

            RowLayout {
                Layout.fillWidth: true

                QQC2.Label {
                    text: i18n('Sender:')
                    font.bold: true
                    visible: root.sender.length > 0 && root.sender !== root.from
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                }

                QQC2.Label {
                    visible: root.sender.length > 0 && root.sender !== root.from
                    text: root.sender
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Layout.fillWidth: true

                QQC2.Label {
                    text: i18n('To:')
                    font.bold: true
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                }

                QQC2.Label {
                    text: root.to
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }

    MailPartView {
        id: mailPartView
        anchors.fill: parent
        item: root.item
    }

    footer: QQC2.ToolBar {
        padding: root.padding

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View

        background: Item {
            Kirigami.Separator {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: undefined
                    bottom:  parent.bottom
                }
            }
        }

        Flow {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing
            Repeater {
                model: mailPartView.attachmentModel

                delegate: AttachmentDelegate {
                    name: model.name
                    type: model.type
                    icon.name: model.iconName

                    clip: true

                    actionIcon: 'download'
                    actionTooltip: i18n("Save attachment")
                    onExecute: mailPartView.attachmentModel.saveAttachmentToDisk(mailPartView.attachmentModel.index(index, 0))
                    onClicked: mailPartView.attachmentModel.openAttachment(mailPartView.attachmentModel.index(index, 0))
                    onPublicKeyImport: mailPartView.attachmentModel.importPublicKey(mailPartView.attachmentModel.index(index, 0))
                }
            }
        }
    }
}
