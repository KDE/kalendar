// SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1
import org.kde.kirigami 2.19 as Kirigami

import QtQuick.Templates 2.15 as T

import org.kde.kalendar.contact 1.0
import org.kde.akonadi 1.0 as Akonadi

Kirigami.ScrollablePage {
    id: root

    property alias mode: contactEditor.mode

    property ContactEditor contactEditor: ContactEditor {
        id: contactEditor
        mode: ContactEditor.CreateMode
    }

    title: if (mode === ContactEditor.CreateMode) {
        return i18n("Adding contact");
    } else {
        return i18n("Adding contact");
    }

    enabled: !contactEditor.isReadOnly

    FileDialog {
        id: fileDialog

        onAccepted: {
            root.pendingPhoto = ContactController.preparePhoto(currentFile)
        }
    }

    Kirigami.FormLayout {
        id: form
        Layout.fillWidth: true

        QQC2.ComboBox {
            id: addressBookComboBox

            Kirigami.FormData.label: i18n("Address Book:")
            Layout.fillWidth: true

            textRole: "display"
            valueRole: "collectionId"

            // indicator: Rectangle {
            //     id: indicatorDot
            //     implicitHeight: calendarCombo.implicitHeight * 0.4
            //     implicitWidth: implicitHeight
            //     x: calendarCombo.mirrored ? calendarCombo.leftPadding : calendarCombo.width - (calendarCombo.leftPadding * 3) - Kirigami.Units.iconSizes.smallMedium
            //     y: calendarCombo.topPadding + (calendarCombo.availableHeight - height) / 2
            //     radius: width * 0.5
            //     // color: CalendarManager.getCollectionDetails(calendarCombo.currentValue).color
            // }

            model: Akonadi.CollectionComboBoxModel {
                id: collectionComboBoxModel
                mimeTypeFilter: [Akonadi.MimeTypes.address, Akonadi.MimeTypes.contactGroup]
                accessRightsFilter: Akonadi.Collection.CanCreateItem
                onCurrentIndexChanged: addressBookComboBox.currentIndex = currentIndex
                onCurrentCollectionChanged: contactEditor.setDefaultAddressBook(currentCollection)
            }
            delegate: Kirigami.BasicListItem {
                label: display
                icon: decoration
                trailing: Rectangle {
                    anchors.margins: Kirigami.Units.smallSpacing
                    width: height
                    radius: width * 0.5
                    color: collectionColor
                }
            }
            currentIndex: -1
            onCurrentIndexChanged: if (currentIndex !== -1) {
                collectionComboBoxModel.currentIndex = currentIndex;
            }

            popup.z: 1000
        }

        //Controls.Button {
        //    Kirigami.FormData.label: i18n("Photo")

        //    // Square button
        //    implicitWidth: Kirigami.Units.gridUnit * 5
        //    implicitHeight: implicitWidth

        //    contentItem: Item {
        //        // Doesn't like to be scaled when being the direct contentItem
        //        Kirigami.Icon {
        //            anchors.fill: parent
        //            anchors.margins: Kirigami.Units.smallSpacing

        //            Connections {
        //                target: root
        //                function onSave() {
        //                    addressee.photo = root.pendingPhoto
        //                }
        //            }

        //            source: {
        //                if (root.pendingPhoto.isEmpty) {
        //                    return "user-identity"
        //                } else if (root.pendingPhoto.isIntern) {
        //                    return root.pendingPhoto.data
        //                } else {
        //                    return root.pendingPhoto.url
        //                }
        //            }
        //        }
        //    }

        //    onClicked: fileDialog.open()
        //}

        QQC2.TextField {
            id: name
            Kirigami.FormData.label: i18n("Name:")
            Layout.fillWidth: true
            text: contactEditor.contact.name
            onTextChanged: contactEditor.contact.name = text
        }

        //ColumnLayout {
        //    id: phoneNumber
        //    Layout.fillWidth: true
        //    Kirigami.FormData.label: i18n("Phone:")
        //    Repeater {
        //        model: pendingPhoneNumbers

        //        delegate: RowLayout {
        //            Controls.TextField {
        //                id: phoneField
        //                text: modelData.number
        //                inputMethodHints: Qt.ImhDialableCharactersOnly
        //                Layout.fillWidth: true
        //                onAccepted: {
        //                    root.pendingPhoneNumbers[index].number = text
        //                }

        //                Connections {
        //                    target: root
        //                    function onSave() {
        //                        phoneField.accepted()
        //                        addressee.phoneNumbers = root.pendingPhoneNumbers
        //                    }
        //                }
        //            }
        //            Controls.Button {
        //                icon.name: "list-remove"
        //                implicitWidth: implicitHeight
        //                onClicked: {
        //                    var newList = root.pendingPhoneNumbers.filter((value, index) => index != model.index)
        //                    root.pendingPhoneNumbers = newList
        //                }
        //            }
        //        }
        //    }
        //    RowLayout {
        //        Controls.TextField {
        //            id: toAddPhone
        //            Layout.fillWidth: true
        //            placeholderText: i18n("+1 555 2368")
        //            inputMethodHints: Qt.ImhDialableCharactersOnly
        //        }

        //        // add last text field on save()
        //        Connections {
        //            target: root;
        //            function onSave() {
        //                if (toAddPhone.text !== "") {
        //                    var numbers = pendingPhoneNumbers
        //                    numbers.push(ContactController.createPhoneNumber(toAddPhone.text))
        //                    pendingPhoneNumbers = numbers
        //                }

        //                addressee.phoneNumbers = root.pendingPhoneNumbers
        //            }
        //        }

        //        // button to add additional text field
        //        Controls.Button {
        //            icon.name: "list-add"
        //            implicitWidth: implicitHeight
        //            enabled: toAddPhone.text.length > 0
        //            onClicked: {
        //                var numbers = pendingPhoneNumbers
        //                numbers.push(ContactController.createPhoneNumber(toAddPhone.text))
        //                pendingPhoneNumbers = numbers
        //                toAddPhone.text = ""
        //            }
        //        }
        //    }
        //}

        //ColumnLayout {
        //    id: email
        //    Layout.fillWidth: true
        //    Kirigami.FormData.label: i18n("E-mail:")

        //    Repeater {
        //        model: root.pendingEmails

        //        delegate: RowLayout {
        //            Controls.TextField {
        //                id: textField
        //                Layout.fillWidth: true
        //                text: modelData.email
        //                inputMethodHints: Qt.ImhEmailCharactersOnly

        //                onAccepted: {
        //                    root.pendingEmails[index].email = text
        //                }

        //                Connections {
        //                    target: root
        //                    function onSave() {
        //                        textField.accepted()
        //                        addressee.emails = root.pendingEmails
        //                    }
        //                }
        //            }
        //            Controls.Button {
        //                icon.name: "list-remove"
        //                implicitWidth: implicitHeight
        //                onClicked: {
        //                    root.pendingEmails = root.pendingEmails.filter((value, index) => index != model.index)
        //                }
        //            }
        //        }
        //    }
        //    RowLayout {
        //        Controls.TextField {
        //            id: toAddEmail
        //            Layout.fillWidth: true
        //            placeholderText: i18n("user@example.org")
        //            inputMethodHints: Qt.ImhEmailCharactersOnly
        //        }

        //        // add last text field on save()
        //        Connections {
        //            target: root;
        //            function onSave() {
        //                if (toAddEmail.text !== "") {
        //                    var emails = root.pendingEmails
        //                    emails.push(ContactController.createEmail(toAddEmail.text))
        //                    root.pendingEmails = emails
        //                }

        //                addressee.emails = root.pendingEmails
        //            }
        //        }

        //        // button to add additional text field
        //        Controls.Button {
        //            icon.name: "list-add"
        //            implicitWidth: implicitHeight
        //            enabled: toAddEmail.text.length > 0
        //            onClicked: {
        //                var emails = root.pendingEmails
        //                emails.push(ContactController.createEmail(toAddEmail.text))
        //                root.pendingEmails = emails
        //                toAddEmail.text = ""
        //            }
        //        }
        //    }
        //}

        //ColumnLayout {
        //    id: impp
        //    Layout.fillWidth: true
        //    Kirigami.FormData.label: i18n("Instant Messenger:")

        //    Repeater {
        //        model: root.pendingImpps

        //        delegate: RowLayout {
        //            Controls.TextField {
        //                id: imppField
        //                text: modelData.address
        //                inputMethodHints: Qt.ImhEmailCharactersOnly
        //                Layout.fillWidth: true
        //                onAccepted: {
        //                    root.pendingImpps[index].address = text
        //                }

        //                Connections {
        //                    target: root
        //                    onSave: {
        //                        imppField.accepted()
        //                        addressee.impps = root.pendingImpps
        //                    }
        //                }
        //            }
        //            Controls.Button {
        //                icon.name: "list-remove"
        //                implicitWidth: implicitHeight
        //                onClicked: {
        //                    root.pendingImpps = root.pendingImpps.filter((value, index) => index != model.index)
        //                }
        //            }
        //        }
        //    }
        //    RowLayout {
        //        Controls.TextField {
        //            id: toAddImpp
        //            Layout.fillWidth: true
        //            placeholderText: i18n("protocol:person@example.com")
        //            inputMethodHints: Qt.ImhEmailCharactersOnly
        //        }

        //        // add last text field on save()
        //        Connections {
        //            target: root;
        //            function onSave() {
        //                if (toAddImpp.text !== "") {
        //                    var impps = root.pendingImpps
        //                    impps.push(ContactController.createImpp(toAddImpp.text))
        //                    root.pendingImpps = impps
        //                }

        //                addressee.impps = root.pendingImpps
        //            }
        //        }

        //        // button to add additional text field
        //        Controls.Button {
        //            icon.name: "list-add"
        //            implicitWidth: implicitHeight
        //            enabled: toAddImpp.text.length > 0
        //            onClicked: {
        //                var impps = root.pendingImpps
        //                impps.push(ContactController.createImpp(toAddImpp.text))
        //                pendingImpps = impps
        //                toAddImpp.text = ""
        //            }
        //        }
        //    }
        //}

        //KirigamiDateTime.DateInput {
        //    id: birthday
        //    Kirigami.FormData.label: i18n("Birthday:")

        //    selectedDate: addressee.birthday

        //    Connections {
        //        target: root
        //        function onSave() {
        //            addressee.birthday = birthday.selectedDate // TODO birthday is not writable
        //        }
        //    }
        //}
    }

    //footer: T.Control {
    //    id: footerToolBar

    //    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
    //                            implicitContentWidth + leftPadding + rightPadding)
    //    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
    //                            implicitContentHeight + topPadding + bottomPadding)

    //    leftPadding: Kirigami.Units.smallSpacing
    //    rightPadding: Kirigami.Units.smallSpacing
    //    bottomPadding: Kirigami.Units.smallSpacing
    //    topPadding: Kirigami.Units.smallSpacing + footerSeparator.implicitHeight

    //    contentItem: RowLayout {
    //        spacing: parent.spacing

    //        // footer buttons
    //        Controls.DialogButtonBox {
    //            // we don't explicitly set padding, to let the style choose the padding
    //            id: dialogButtonBox
    //            standardButtons: Controls.DialogButtonBox.Close | Controls.DialogButtonBox.Save

    //            Layout.fillWidth: true
    //            Layout.alignment: dialogButtonBox.alignment

    //            position: Controls.DialogButtonBox.Footer

    //            onAccepted: {
    //                root.save();
    //                switch(root.state) {
    //                    case "create":
    //                        if (!KPeople.PersonPluginManager.addContact({ "vcard": ContactController.addresseeToVCard(addressee) }))
    //                            console.warn("could not create contact")
    //                        break;
    //                    case "update":
    //                        if (!root.person.setContactCustomProperty("vcard", ContactController.addresseeToVCard(addressee)))
    //                            console.warn("Could not save", addressee.url)
    //                        break;
    //                }
    //                root.closeDialog()
    //            }
    //            onRejected: root.closeDialog()
    //        }
    //    }

    //    background: Item {
    //        // separator above footer
    //        Kirigami.Separator {
    //            id: footerSeparator
    //            visible: root.contentItem.height < root.contentItem.flickableItem.contentHeight
    //            width: parent.width
    //            anchors.top: parent.top
    //        }
    //    }
    //}


    footer: QQC2.DialogButtonBox {
        standardButtons: QQC2.DialogButtonBox.Cancel

        QQC2.Button {
            icon.name: mode === ContactEditor.EditMode ? "document-save" : "list-add"
            text: ContactEditor.CreateMode ? i18n("Save") : i18n("Add")
            enabled: root.validDates && incidenceWrapper.summary && incidenceWrapper.collectionId
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
        }

        onRejected: cancel()
        onAccepted: submitAction.trigger()
    }
}
