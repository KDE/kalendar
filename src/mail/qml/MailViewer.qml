// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import org.kde.kalendar 1.0
import org.kde.kalendar.mail 1.0
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

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
        property color borderColor: Kirigami.Theme.textColor
        border.color: Qt.rgba(borderColor.r, borderColor.g, borderColor.b, 0.3)
        radius: Kirigami.Units.largeSpacing
    }

    header: QQC2.ToolBar {
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

        GridLayout {
            anchors.fill: parent
            columns: 3
            QQC2.Label {
                text: i18n('From:')
                Layout.rightMargin: Kirigami.Units.largeSpacing
            }

            QQC2.Label {
                text: root.from
            }

            QQC2.Label {
                text: root.dateTime.toLocaleString()
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
            }

            QQC2.Label {
                text: i18n('Sender:')
                visible: root.sender.length > 0 && root.sender !== root.from
                Layout.rightMargin: Kirigami.Units.largeSpacing
            }

            QQC2.Label {
                visible: root.sender.length > 0 && root.sender !== root.from
                text: root.sender
                Layout.columnSpan: 2
            }

            QQC2.Label {
                text: i18n('To:')
                Layout.rightMargin: Kirigami.Units.largeSpacing
            }

            QQC2.Label {
                text: root.to
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
