// SPDX-FileCopyrightText: 2016 Michael Bohlender <michael.bohlender@kdemail.net>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtQml.Models 2.2
import org.kde.kalendar 1.0
import org.kde.kalendar.mail 1.0
import org.kde.kirigami 2.19 as Kirigami

DelegateModel {
    id: root

    property string searchString: ""
    property bool autoLoadImages: false

    delegate: Item {
        id: partColumn

        width: ListView.view.width
        height: childrenRect.height

        function getType(securityLevel) {
            if (securityLevel == "good") {
                return Kirigami.MessageType.Positive
            }
            if (securityLevel == "bad") {
                return Kirigami.MessageType.Error
            }
            if (securityLevel == "notsogood") {
                return Kirigami.MessageType.Warning
            }
            return Kirigami.MessageType.Information
        }

        function getColor(securityLevel) {
            if (securityLevel == "good") {
                return Kirigami.Theme.positiveTextColor
            }
            if (securityLevel == "bad") {
                return Kirigami.Theme.negativeTextColor
            }
            if (securityLevel == "notsogood") {
                return Kirigami.Theme.neutralTextColor
            }
            return Kirigami.Theme.disabledColor
        }

        function getDetails(signatureDetails) {
            let details = "";
            if (signatureDetails.keyMissing) {
                details += i18n("This message has been signed using the key %1.", signatureDetails.keyId) + "\n";
                details += i18n("The key details are not available.") + "\n";
            } else {
                details += i18n("This message has been signed using the key %1 by %2.", signatureDetails.keyId, signatureDetails.signer) + "\n";
                if (signatureDetails.keyRevoked) {
                    details += i18n("The key was revoked.") + "\n"
                }
                if (signatureDetails.keyExpired) {
                    details += i18n("The key has expired.") + "\n"
                }
                if (signatureDetails.keyIsTrusted) {
                    details += i18n("You are trusting this key.") + "\n"
                }
                if (!signatureDetails.signatureIsGood && !signatureDetails.keyRevoked && !signatureDetails.keyExpired && !signatureDetails.keyIsTrusted) {
                    details += i18n("The signature is invalid.") + "\n"
                }
            }
            return details
        }

        ColumnLayout {
            id: buttons
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            spacing: Kirigami.Units.smallSpacing

            Kirigami.InlineMessage {
                id: encryptedButton
                Layout.fillWidth: true
                Layout.maximumWidth: parent.width
                icon.name: 'mail-encrypted'
                type: getType(model.encryptionSecurityLevel)
                visible: model.encrypted
                text: model.encryptionDetails.keyId == "" ? i18n("This message is encrypted but we don't have the key for it.") : i18n("This message is encrypted to the key: %1", model.encryptionDetails.keyId);
            }
            Kirigami.InlineMessage {
                id: signedButton
                Layout.fillWidth: true
                Layout.maximumWidth: parent.width
                icon.name: 'mail-signed'
                visible: model.signed
                type: getType(model.signatureSecurityLevel)
                text: getDetails(model.signatureDetails)
            }

            Loader {
                id: partLoader
                Layout.preferredHeight: item ? item.contentHeight : 0
                Layout.maximumWidth: parent.width
                Layout.fillWidth: true
                Binding {
                    target: partLoader.item
                    property: "searchString"
                    value: root.searchString
                    when: partLoader.status === Loader.Ready
                }
                Binding {
                    target: partLoader.item
                    property: "autoLoadImages"
                    value: root.autoLoadImages
                    when: partLoader.status === Loader.Ready
                }
            }
            Component.onCompleted: {
                switch (model.type) {
                    case "plain":
                        partLoader.setSource("TextPart.qml", {
                            content: model.content,
                            embedded: model.embedded,
                            type: model.type
                        })
                        break
                    case "html":
                        partLoader.setSource("HtmlPart.qml", {
                            content: model.content,
                        })
                        break;
                    case "error":
                        partLoader.setSource("ErrorPart.qml", {
                            errorType: model.errorType,
                            errorString: model.errorString,
                        })
                        break;
                    case "encapsulated":
                        partLoader.setSource("MailPart.qml", {
                            rootIndex: root.modelIndex(index),
                            model: root.model,
                            sender: model.sender,
                            date: model.date,
                        })
                        break;
                    case "ical":
                        partLoader.setSource("ICalPart.qml", {
                            content: model.content,
                        })
                        break;
                }
            }
        }
    }
}
