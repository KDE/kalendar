// SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.6
import QtQuick.Controls 2.2 as Controls
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import org.kde.kirigami 2.4 as Kirigami
import org.kde.people 1.0 as KPeople

import org.kde.kirigamiaddons.dateandtime 0.1 as KirigamiDateTime
import QtQuick.Templates 2.15 as T

import org.kde.kalendar.contact 1.0

Kirigami.ScrollablePage {
    id: root

    property QtObject person
    property var addressee: ContactController.emptyAddressee()

    property var pendingPhoneNumbers: addressee.phoneNumbers
    property var pendingEmails: addressee.emails
    property var pendingImpps: addressee.impps
    property var pendingPhoto: addressee.photo

    signal save()

    states: [
        State {
            name: "create"
            PropertyChanges { target: root; title: i18n("Adding contact") }
        },
        State {
            name: "update"
            PropertyChanges { target: root; title: i18n("Editing contact") }
        }
    ]

    enabled: !person || person.isEditable

    FileDialog {
        id: fileDialog

        onAccepted: {
            root.pendingPhoto = ContactController.preparePhoto(currentFile)
        }
    }

    Kirigami.FormLayout {
        id: form
        Layout.fillWidth: true

        Controls.Button {
            Kirigami.FormData.label: i18n("Photo")

            // Square button
            implicitWidth: Kirigami.Units.gridUnit * 5
            implicitHeight: implicitWidth

            contentItem: Item {
                // Doesn't like to be scaled when being the direct contentItem
                Kirigami.Icon {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing

                    Connections {
                        target: root
                        function onSave() {
                            addressee.photo = root.pendingPhoto
                        }
                    }

                    source: {
                        if (root.pendingPhoto.isEmpty) {
                            return "user-identity"
                        } else if (root.pendingPhoto.isIntern) {
                            return root.pendingPhoto.data
                        } else {
                            return root.pendingPhoto.url
                        }
                    }
                }
            }

            onClicked: fileDialog.open()
        }

        Controls.TextField {
            id: name
            Kirigami.FormData.label: i18n("Name:")
            Layout.fillWidth: true
            text: addressee.formattedName
            onAccepted: {
                addressee.formattedName = text
            }

            Connections {
                target: root
                function onSave() {
                    name.accepted()
                }
            }
        }

        ColumnLayout {
            id: phoneNumber
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Phone:")
            Repeater {
                model: pendingPhoneNumbers

                delegate: RowLayout {
                    Controls.TextField {
                        id: phoneField
                        text: modelData.number
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        Layout.fillWidth: true
                        onAccepted: {
                            root.pendingPhoneNumbers[index].number = text
                        }

                        Connections {
                            target: root
                            function onSave() {
                                phoneField.accepted()
                                addressee.phoneNumbers = root.pendingPhoneNumbers
                            }
                        }
                    }
                    Controls.Button {
                        icon.name: "list-remove"
                        implicitWidth: implicitHeight
                        onClicked: {
                            var newList = root.pendingPhoneNumbers.filter((value, index) => index != model.index)
                            root.pendingPhoneNumbers = newList
                        }
                    }
                }
            }
            RowLayout {
                Controls.TextField {
                    id: toAddPhone
                    Layout.fillWidth: true
                    placeholderText: i18n("+1 555 2368")
                    inputMethodHints: Qt.ImhDialableCharactersOnly
                }

                // add last text field on save()
                Connections {
                    target: root;
                    function onSave() {
                        if (toAddPhone.text !== "") {
                            var numbers = pendingPhoneNumbers
                            numbers.push(ContactController.createPhoneNumber(toAddPhone.text))
                            pendingPhoneNumbers = numbers
                        }

                        addressee.phoneNumbers = root.pendingPhoneNumbers
                    }
                }

                // button to add additional text field
                Controls.Button {
                    icon.name: "list-add"
                    implicitWidth: implicitHeight
                    enabled: toAddPhone.text.length > 0
                    onClicked: {
                        var numbers = pendingPhoneNumbers
                        numbers.push(ContactController.createPhoneNumber(toAddPhone.text))
                        pendingPhoneNumbers = numbers
                        toAddPhone.text = ""
                    }
                }
            }
        }

        ColumnLayout {
            id: email
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("E-mail:")

            Repeater {
                model: root.pendingEmails

                delegate: RowLayout {
                    Controls.TextField {
                        id: textField
                        Layout.fillWidth: true
                        text: modelData.email
                        inputMethodHints: Qt.ImhEmailCharactersOnly

                        onAccepted: {
                            root.pendingEmails[index].email = text
                        }

                        Connections {
                            target: root
                            function onSave() {
                                textField.accepted()
                                addressee.emails = root.pendingEmails
                            }
                        }
                    }
                    Controls.Button {
                        icon.name: "list-remove"
                        implicitWidth: implicitHeight
                        onClicked: {
                            root.pendingEmails = root.pendingEmails.filter((value, index) => index != model.index)
                        }
                    }
                }
            }
            RowLayout {
                Controls.TextField {
                    id: toAddEmail
                    Layout.fillWidth: true
                    placeholderText: i18n("user@example.org")
                    inputMethodHints: Qt.ImhEmailCharactersOnly
                }

                // add last text field on save()
                Connections {
                    target: root;
                    function onSave() {
                        if (toAddEmail.text !== "") {
                            var emails = root.pendingEmails
                            emails.push(ContactController.createEmail(toAddEmail.text))
                            root.pendingEmails = emails
                        }

                        addressee.emails = root.pendingEmails
                    }
                }

                // button to add additional text field
                Controls.Button {
                    icon.name: "list-add"
                    implicitWidth: implicitHeight
                    enabled: toAddEmail.text.length > 0
                    onClicked: {
                        var emails = root.pendingEmails
                        emails.push(ContactController.createEmail(toAddEmail.text))
                        root.pendingEmails = emails
                        toAddEmail.text = ""
                    }
                }
            }
        }

        ColumnLayout {
            id: impp
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Instant Messenger:")

            Repeater {
                model: root.pendingImpps

                delegate: RowLayout {
                    Controls.TextField {
                        id: imppField
                        text: modelData.address
                        inputMethodHints: Qt.ImhEmailCharactersOnly
                        Layout.fillWidth: true
                        onAccepted: {
                            root.pendingImpps[index].address = text
                        }

                        Connections {
                            target: root
                            onSave: {
                                imppField.accepted()
                                addressee.impps = root.pendingImpps
                            }
                        }
                    }
                    Controls.Button {
                        icon.name: "list-remove"
                        implicitWidth: implicitHeight
                        onClicked: {
                            root.pendingImpps = root.pendingImpps.filter((value, index) => index != model.index)
                        }
                    }
                }
            }
            RowLayout {
                Controls.TextField {
                    id: toAddImpp
                    Layout.fillWidth: true
                    placeholderText: i18n("protocol:person@example.com")
                    inputMethodHints: Qt.ImhEmailCharactersOnly
                }

                // add last text field on save()
                Connections {
                    target: root;
                    function onSave() {
                        if (toAddImpp.text !== "") {
                            var impps = root.pendingImpps
                            impps.push(ContactController.createImpp(toAddImpp.text))
                            root.pendingImpps = impps
                        }

                        addressee.impps = root.pendingImpps
                    }
                }

                // button to add additional text field
                Controls.Button {
                    icon.name: "list-add"
                    implicitWidth: implicitHeight
                    enabled: toAddImpp.text.length > 0
                    onClicked: {
                        var impps = root.pendingImpps
                        impps.push(ContactController.createImpp(toAddImpp.text))
                        pendingImpps = impps
                        toAddImpp.text = ""
                    }
                }
            }
        }

        KirigamiDateTime.DateInput {
            id: birthday
            Kirigami.FormData.label: i18n("Birthday:")

            selectedDate: addressee.birthday

            Connections {
                target: root
                function onSave() {
                    addressee.birthday = birthday.selectedDate // TODO birthday is not writable
                }
            }
        }
    }

    footer: T.Control {
        id: footerToolBar

        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                implicitContentHeight + topPadding + bottomPadding)

        leftPadding: Kirigami.Units.smallSpacing
        rightPadding: Kirigami.Units.smallSpacing
        bottomPadding: Kirigami.Units.smallSpacing
        topPadding: Kirigami.Units.smallSpacing + footerSeparator.implicitHeight

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
                    root.save();
                    switch(root.state) {
                        case "create":
                            if (!KPeople.PersonPluginManager.addContact({ "vcard": ContactController.addresseeToVCard(addressee) }))
                                console.warn("could not create contact")
                            break;
                        case "update":
                            if (!root.person.setContactCustomProperty("vcard", ContactController.addresseeToVCard(addressee)))
                                console.warn("Could not save", addressee.url)
                            break;
                    }
                    root.closeDialog()
                }
                onRejected: root.closeDialog()
            }
        }

        background: Item {
            // separator above footer
            Kirigami.Separator {
                id: footerSeparator
                visible: root.contentItem.height < root.contentItem.flickableItem.contentHeight
                width: parent.width
                anchors.top: parent.top
            }
        }
    }
}
