// SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import org.kde.kitemmodels 1.0 as KItemModels
import org.kde.kalendar.mail 1.0


Kirigami.ScrollablePage {
    id: mailComposition
    title: i18nc("@title:window", "New Message")
    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0
    topPadding: Kirigami.Units.largeSpacing

    property MailHeaderModel mailHeaderModel: MailHeaderModel {}
    
    GridLayout {
        columns: 2
        anchors.fill: parent

        QQC2.Label {
            text: i18n("From:")
            Layout.leftMargin: Kirigami.Units.largeSpacing
        }

        QQC2.TextField {
            id: from
            Layout.fillWidth: true
            Layout.rightMargin: Kirigami.Units.largeSpacing
        }

        QQC2.Label {
            text: i18n("Identity:")
            Layout.leftMargin: Kirigami.Units.largeSpacing
        }

        QQC2.ComboBox {
            id: identity
            model: IdentityModel {}
            textRole: "display"
            valueRole: "uoid"
            onCurrentIndexChanged: {
                from.text = model.email(currentValue)
            }
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.fillWidth: true
        }

        Repeater {
            model: mailHeaderModel
            QQC2.ComboBox {
                id: control
                Layout.row: index + 2
                Layout.column: 0
                Layout.leftMargin: Kirigami.Units.largeSpacing
                textRole: "text"
                valueRole: "value"
                Component.onCompleted: currentIndex = Math.min(mailHeaderModel.rowCount() - 1, 1);
                onCurrentIndexChanged: mailHeaderModel.updateHeaderType(index, currentValue);
                model: [
                    { value: MailHeaderModel.To, text: i18n("To:") },
                    { value: MailHeaderModel.CC, text: i18n("CC:") },
                    { value: MailHeaderModel.BCC, text: i18n("BCC:") },
                    { value: MailHeaderModel.ReplyTo, text: i18n("Reply-To:") },
                ]
            }
        }
        Repeater {
            model: mailHeaderModel
            QQC2.TextField {
                id: controlsText
                Layout.row: index + 2
                Layout.column: 1
                Layout.fillWidth: true
                Layout.rightMargin: Kirigami.Units.largeSpacing
                wrapMode: Text.Wrap
                KeyNavigation.priority: KeyNavigation.BeforeItem
                onTextChanged: mailHeaderModel.updateModel(index, text);
            }
        }

        QQC2.Label {
            id: subject
            text: i18n("Subject:")
            Layout.leftMargin: Kirigami.Units.largeSpacing
        }
        QQC2.TextField {
            id: subjectText
            Layout.fillWidth: true
            Layout.rightMargin: Kirigami.Units.largeSpacing
            wrapMode: Text.Wrap
            KeyNavigation.priority: KeyNavigation.BeforeItem
            KeyNavigation.tab: mailContent
        }
        
        QQC2.TextArea {
            id: mailContent
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            background: Rectangle {
                color: Kirigami.Theme.backgroundColor
            }

            Kirigami.Theme.colorSet: Kirigami.Theme.View
            Kirigami.Theme.inherit: false

            textFormat: TextEdit.PlainText
            textMargin: 10
            wrapMode: Text.Wrap
            KeyNavigation.priority: KeyNavigation.BeforeItem
            KeyNavigation.tab: attachment
        }
    }

    footer: QQC2.ToolBar {
        contentItem: RowLayout {
            QQC2.ToolButton {
                id: attachment
                icon.name: 'document-import'
                KeyNavigation.priority: KeyNavigation.BeforeItem
                KeyNavigation.tab: discardDraft
            }
            QQC2.ToolButton {
                id: discardDraft
                icon.name: 'user-trash'
            }
            Item {
                Layout.fillWidth: true
            }
            QQC2.ToolButton {
                id: sendButton
                text: i18n("Send")
                icon.name: 'document-send'
            }
        }
    }
}