// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls

import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm
import org.kde.kalendar.accounts 1.0

Kirigami.ScrollablePage {
    id: root
    title: i18n("Add Account")

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    leftPadding: 0
    rightPadding: 0
    topPadding: Kirigami.Units.gridUnit
    bottomPadding: Kirigami.Units.gridUnit

    footer: Controls.Control {
        id: footerToolBar

        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                implicitContentHeight + topPadding + bottomPadding)

        leftPadding: Kirigami.Units.smallSpacing
        rightPadding: Kirigami.Units.smallSpacing
        bottomPadding: Kirigami.Units.smallSpacing
        topPadding: Kirigami.Units.smallSpacing

        contentItem: RowLayout {
            spacing: parent.spacing

            // footer buttons
            Controls.DialogButtonBox {
                // we don't explicitly set padding, to let the style choose the padding
                id: dialogButtonBox
                standardButtons: Controls.DialogButtonBox.Close | Controls.DialogButtonBox.Save

                Layout.fillWidth: true
                Layout.alignment: dialogButtonBox.alignment

                position: Controls.DialogButtonBox.Footer

                onAccepted: {
                    newAccount.addAccount();
                    applicationWindow().pageStack.layers.pop();
                }
                onRejected: applicationWindow().pageStack.layers.pop()
            }
        }

        background: Rectangle {
            color: Kirigami.Theme.backgroundColor

            // separator above footer
            Kirigami.Separator {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }
    }

    ColumnLayout {
        spacing: 0
        width: root.width

        NewAccount {
            id: newAccount
        }

        MobileForm.FormCard {
            Layout.fillWidth: true

            contentItem: ColumnLayout {
                spacing: 0

                MobileForm.FormTextFieldDelegate {
                    id: nameDelegate
                    label: i18n("Name")
                    text: newAccount.name
                    onTextChanged: newAccount.name = text
                }

                MobileForm.FormDelegateSeparator { above: nameDelegate; below: emailDelegate }

                MobileForm.FormTextFieldDelegate {
                    id: emailDelegate
                    label: i18n("Email")
                    text: newAccount.email
                    onTextChanged: newAccount.email = text
                }

                MobileForm.FormDelegateSeparator { above: emailDelegate; below: passwordDelegate }

                MobileForm.FormTextFieldDelegate {
                    id: passwordDelegate
                    label: i18n("Password")
                    text: newAccount.password
                    onTextChanged: newAccount.password = text
                }

                MobileForm.FormDelegateSeparator { above: passwordDelegate; below: autoFillDelegate }

                MobileForm.AbstractFormDelegate {
                    id: autoFillDelegate
                    Layout.fillWidth: true
                    contentItem: RowLayout {
                        Controls.Label {
                            Layout.fillWidth: true
                            text: i18n("Auto-fill settings")
                        }

                        Controls.Button {
                            text: i18n("Fill")
                            icon.name: "search"
                            onClicked: newAccount.searchIspdbForConfig()
                        }
                    }
                }
            }
        }

        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing

            contentItem: ColumnLayout {
                spacing: 0

                MobileForm.FormCardHeader {
                    title: i18n("Receiving")
                }

                MobileForm.FormComboBoxDelegate {
                    id: receiveEmailProtocolDelegate
                    text: i18n("Protocol")
                    currentValue: newAccount.receivingMailProtocol === NewAccount.Imap ? "IMAP" : "POP3"
                    model: ["IMAP", "POP3"]
                    dialogDelegate: Controls.RadioDelegate {
                        implicitWidth: Kirigami.Units.gridUnit * 16
                        topPadding: Kirigami.Units.smallSpacing * 2
                        bottomPadding: Kirigami.Units.smallSpacing * 2

                        text: modelData
                        checked: receiveEmailProtocolDelegate.currentValue == modelData
                        onCheckedChanged: {
                            if (checked) {
                                receiveEmailProtocolDelegate.currentValue = modelData;
                                newAccount.receivingMailProtocol = modelData === "IMAP" ? NewAccount.Imap : NewAccount.Pop3;
                            }
                        }
                    }

                }

                MobileForm.FormDelegateSeparator { above: receiveEmailProtocolDelegate; below: receivingHostDelegate }

                MobileForm.FormTextFieldDelegate {
                    id: receivingHostDelegate
                    label: i18n("Host")
                    text: newAccount.receivingMailProtocol === NewAccount.Imap ? newAccount.imapHost : newAccount.pop3Host
                    onTextChanged: newAccount.receivingMailProtocol === NewAccount.Imap ? newAccount.imapHost = text : newAccount.pop3Host = savedText
                }

                MobileForm.FormDelegateSeparator { above: receivingHostDelegate; below: receivingPortDelegate }

                MobileForm.FormTextFieldDelegate {
                    id: receivingPortDelegate
                    label: i18n("Port")
                    text: newAccount.receivingMailProtocol === NewAccount.Imap ? newAccount.imapPort : newAccount.pop3Port
                    onTextChanged: newAccount.receivingMailProtocol === NewAccount.Imap ? newAccount.imapPort = text : newAccount.pop3Port = savedText
                }

                MobileForm.FormDelegateSeparator { above: receivingPortDelegate; below: receivingUsernameDelegate }

                MobileForm.FormTextFieldDelegate {
                    id: receivingUsernameDelegate
                    label: i18n("Username")
                    text: newAccount.receivingMailProtocol === NewAccount.Imap ? newAccount.imapUsername : newAccount.pop3Username
                    onTextChanged: newAccount.receivingMailProtocol === NewAccount.Imap ? newAccount.imapUsername = text : newAccount.pop3Username = savedText
                }

                MobileForm.FormDelegateSeparator { above: receivingUsernameDelegate; below: receivingPasswordDelegate }

                MobileForm.FormTextFieldDelegate {
                    id: receivingPasswordDelegate
                    label: i18n("Password")
                    text: newAccount.receivingMailProtocol === NewAccount.Imap ? newAccount.imapPassword : newAccount.pop3Password
                    onTextChanged: newAccount.receivingMailProtocol === NewAccount.Imap ? newAccount.imapPassword = text : newAccount.pop3Password = savedText
                    echoMode: TextInput.Password
                }
            }
        }

        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing

            contentItem: ColumnLayout {
                spacing: 0

                MobileForm.FormCardHeader {
                    title: i18n("Sending")
                }

                MobileForm.FormTextFieldDelegate {
                    id: smtpHostDelegate
                    label: i18n("Host")
                    text: newAccount.smtpHost
                    onTextChanged: newAccount.smtpHost = text
                }

                MobileForm.FormDelegateSeparator { above: smtpHostDelegate; below: smtpPortDelegate }

                MobileForm.FormTextFieldDelegate {
                    id: smtpPortDelegate
                    label: i18n("Port")
                    text: newAccount.smtpPort
                    onTextChanged: newAccount.smtpPort = text
                }

                MobileForm.FormDelegateSeparator { above: smtpPortDelegate; below: smtpUsernameDelegate }

                MobileForm.FormTextFieldDelegate {
                    id: smtpUsernameDelegate
                    label: i18n("Username")
                    text: newAccount.smtpUsername
                    onTextChanged: newAccount.smtpUsername = text
                }

                MobileForm.FormDelegateSeparator { above: smtpUsernameDelegate; below: smtpPasswordDelegate }

                MobileForm.FormTextFieldDelegate {
                    id: smtpPasswordDelegate
                    label: i18n("Password")
                    text: newAccount.smtpPassword
                    onTextChanged: newAccount.smtpPassword = text
                    echoMode: TextInput.Password
                }
            }
        }
    }
}
