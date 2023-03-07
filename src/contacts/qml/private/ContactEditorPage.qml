// SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1

import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm
import org.kde.kalendar.contact 1.0
import org.kde.akonadi 1.0 as Akonadi

Kirigami.ScrollablePage {
    id: root

    property alias mode: contactEditor.mode
    property alias item: contactEditor.item

    property bool displayAdvancedNameFields: false
    property bool saving: false

    readonly property ContactEditor contactEditor: ContactEditor {
        id: contactEditor
        mode: ContactEditor.CreateMode
        onFinished: root.closeDialog()
        onErrorOccured: {
            errorContainer.errorMessage = errorMsg;
            errorContainer.contentItem.visible = true;
        }
        onItemChangedExternally: itemChangedExternallySheet.open()
    }

    QQC2.Action {
        id: submitAction
        enabled: contactEditor.contact.formattedName.length > 0
        shortcut: "Return"
        onTriggered: {
            root.saving = true;
            if (toAddPhone.text.length > 0) {
                contactEditor.contact.phoneModel.addPhoneNumber(toAddPhone.text, newPhoneTypeCombo.currentValue)
            }
            if (toAddEmail.text.length > 0) {
                contactEditor.contact.emailModel.addEmail(toAddEmail.text, newEmailType.currentValue);
            }
            contactEditor.saveContactInAddressBook()
            ContactConfig.lastUsedAddressBookCollection = addressBookComboBox.defaultCollectionId;
            ContactConfig.save();
        }
    }

    title: if (mode === ContactEditor.CreateMode) {
        return i18n("Add Contact");
    } else {
        return i18n("Edit Contact");
    }

    enabled: !contactEditor.isReadOnly

    //property FileDialog fileDialog: FileDialog {
    //    id: fileDialog

    //    onAccepted: {
    //        root.pendingPhoto = ContactController.preparePhoto(currentFile)
    //    }
    //}

    header: QQC2.Control {
        id: errorContainer
        property bool displayError: false
        property string errorMessage: ''
        padding: contentItem.visible ? Kirigami.Units.smallSpacing : 0
        leftPadding: padding
        rightPadding: padding
        topPadding: padding
        bottomPadding: padding
        contentItem: Kirigami.InlineMessage {
            type: Kirigami.MessageType.Error
            visible: errorContainer.displayError
            text: errorContainer.errorMessage
            showCloseButton: true
        }
    }

    leftPadding: 0
    rightPadding: 0

    ColumnLayout {
        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            contentItem: ColumnLayout {
                spacing: 0

                Akonadi.MobileCollectionComboBox {
                    id: addressBookComboBox

                    text: i18n("Address book:")
                    Layout.fillWidth: true
                    enabled: mode === ContactEditor.CreateMode

                    defaultCollectionId: if (mode === ContactEditor.CreateMode) {
                        return ContactConfig.lastUsedAddressBookCollection;
                    } else {
                        return contactEditor.collectionId;
                    }

                    mimeTypeFilter: [Akonadi.MimeTypes.address, Akonadi.MimeTypes.contactGroup]
                    accessRightsFilter: Akonadi.Collection.CanCreateItem
                    onUserSelectedCollection: contactEditor.setDefaultAddressBook(collection)
                }

                //QQC2.Button {
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

                MobileForm.FormDelegateSeparator { above: addressBookComboBox; below: nameDelegate }

                MobileForm.AbstractFormDelegate {
                    id: nameDelegate
                    Layout.fillWidth: true
                    contentItem: ColumnLayout {
                        QQC2.Label {
                            text: i18n("Name")
                            Layout.fillWidth: true
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            QQC2.TextField {
                                id: textField
                                Accessible.description: i18n("Name")
                                Layout.fillWidth: true
                                text: contactEditor.contact.formattedName
                                onTextEdited: contactEditor.contact.formattedName = text
                                placeholderText: i18n("Contact name")
                            }
                            QQC2.Button {
                                icon.name: 'settings-configure'
                                onClicked: displayAdvancedNameFields = !displayAdvancedNameFields
                                QQC2.ToolTip {
                                    text: i18n('Advanced')
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    visible: displayAdvancedNameFields

                    MobileForm.FormDelegateSeparator {}

                    MobileForm.FormComboBoxDelegate {
                        text: i18n("Honorific prefix")

                        editable: true
                        model: [i18n('Dr.'), i18n("Miss"), i18n("Mr."), i18n("Mrs."), i18n("Ms."), i18n("Prof.")]
                        currentIndex: -1
                        editText: contactEditor.contact.prefix
                        onCurrentValueChanged: contactEditor.contact.prefix = currentValue
                    }

                    MobileForm.FormDelegateSeparator {}

                    MobileForm.FormTextFieldDelegate {
                        label: i18n("Given name")
                        onTextChanged: contactEditor.contact.givenName = text
                        text: contactEditor.contact.givenName
                        placeholderText: i18n("First name or chosen name")
                    }

                    MobileForm.FormDelegateSeparator {}

                    MobileForm.FormTextFieldDelegate {
                        label: i18n("Additional name")
                        onTextChanged: contactEditor.contact.additionalName = text
                        text: contactEditor.contact.additionalName
                        placeholderText: i18n("Middle name or other name")
                    }

                    MobileForm.FormDelegateSeparator {}

                    MobileForm.FormTextFieldDelegate {
                        label: i18n("Family name:")
                        onTextChanged: contactEditor.contact.familyName = text
                        text: contactEditor.contact.familyName
                        placeholderText: i18n("Surname or last name")
                    }

                    MobileForm.FormDelegateSeparator {}

                    MobileForm.FormComboBoxDelegate {
                        text: i18n("Honorific suffix")
                        onCurrentValueChanged: contactEditor.contact.suffix = currentValue
                        editable: true
                        editText: contactEditor.contact.suffix
                        model: [i18n('I'), i18n("II"), i18n("III"), i18n("Jr."), i18n("Sr.")]
                        currentIndex: -1
                    }

                    MobileForm.FormDelegateSeparator {}

                    MobileForm.FormTextFieldDelegate {
                        label: i18n("Nickname")
                        onTextChanged: contactEditor.contact.nickName = text
                        text: contactEditor.contact.nickName
                        placeholderText: i18n("Alternative name")
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
                    title: i18n("Phone")
                }

                Repeater {
                    id: phoneRepeater
                    model: contactEditor.contact.phoneModel

                    delegate: RowLayout {
                        QQC2.ComboBox {
                            model: ListModel {id: phoneTypeModel; dynamicRoles: true }
                            Component.onCompleted: {
                                [
                                    { value: PhoneModel.Home, text: i18n("Home") },
                                    { value: PhoneModel.Work, text: i18n("Work") },
                                    { value: PhoneModel.Msg, text: i18n("Messaging") },
                                    { value: PhoneModel.Voice, text: i18n("Voice") },
                                    { value: PhoneModel.Fax, text: i18n("Fax") },
                                    { value: PhoneModel.Cell, text: i18n("Cell") },
                                    { value: PhoneModel.Video, text: i18n("Video") },
                                    { value: PhoneModel.Bbs, text: i18n("Mailbox") },
                                    { value: PhoneModel.Modem, text: i18n("Modem") },
                                    { value: PhoneModel.Car, text: i18n("Car") },
                                    { value: PhoneModel.Isdn, text: i18n("ISDN") },
                                    { value: PhoneModel.Psc, text: i18n("PCS") },
                                    { value: PhoneModel.Pager, text: i18n("Pager") },
                                    { value: PhoneModel.Undefined, text: i18n("Undefined") },
                                ].forEach((type) => {
                                    phoneTypeModel.append(type);
                                });
                                currentIndex = indexOfValue(typeValue)
                            }
                            textRole: "text"
                            valueRole: "value"
                            onCurrentValueChanged: type = currentValue
                        }
                        QQC2.TextField {
                            id: phoneField
                            text: model.display
                            inputMethodHints: Qt.ImhDialableCharactersOnly
                            Layout.fillWidth: true
                            onTextChanged: model.display = text
                        }
                        QQC2.Button {
                            icon.name: "list-remove"
                            implicitWidth: implicitHeight
                            onClicked: contactEditor.contact.phoneModel.deletePhoneNumber(index)
                        }
                    }
                }
                MobileForm.AbstractFormDelegate {
                    Layout.fillWidth: true
                    contentItem: RowLayout {
                        visible: !root.saving
                        QQC2.ComboBox {
                            id: newPhoneTypeCombo
                            model: ListModel {id: phoneTypeModel; dynamicRoles: true }
                            Component.onCompleted: {
                                [
                                    { value: PhoneModel.Home, text: i18n("Home") },
                                    { value: PhoneModel.Work, text: i18n("Work") },
                                    { value: PhoneModel.Msg, text: i18n("Messaging") },
                                    { value: PhoneModel.Voice, text: i18n("Voice") },
                                    { value: PhoneModel.Fax, text: i18n("Fax") },
                                    { value: PhoneModel.Cell, text: i18n("Cell") },
                                    { value: PhoneModel.Video, text: i18n("Video") },
                                    { value: PhoneModel.Bbs, text: i18n("Mailbox") },
                                    { value: PhoneModel.Modem, text: i18n("Modem") },
                                    { value: PhoneModel.Car, text: i18n("Car") },
                                    { value: PhoneModel.Isdn, text: i18n("ISDN") },
                                    { value: PhoneModel.Psc, text: i18n("PCS") },
                                    { value: PhoneModel.Pager, text: i18n("Pager") }
                                ].forEach((type) => {
                                    phoneTypeModel.append(type);
                                });
                            }
                            textRole: "text"
                            valueRole: "value"
                            currentIndex: 0
                        }
                        QQC2.TextField {
                            id: toAddPhone
                            Layout.fillWidth: true
                            placeholderText: i18n("+33 7 55 23 68 67")
                            inputMethodHints: Qt.ImhDialableCharactersOnly
                        }

                        // button to add additional text field
                        QQC2.Button {
                            icon.name: "list-add"
                            implicitWidth: implicitHeight
                            enabled: toAddPhone.text.length > 0
                            onClicked: {
                                contactEditor.contact.phoneModel.addPhoneNumber(toAddPhone.text, newPhoneTypeCombo.currentValue)
                                toAddPhone.text = '';
                                newPhoneTypeCombo.currentIndex = 0;
                            }
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
                    title: i18n("E-mail")
                }

                Repeater {
                    id: emailRepeater
                    model: contactEditor.contact.emailModel

                    delegate: MobileForm.AbstractFormDelegate {
                        id: emailRow
                        Layout.fillWidth: true
                        contentItem: RowLayout {
                            QQC2.ComboBox {
                                id: emailTypeBox
                                model: ListModel {id: emailTypeModel; dynamicRoles: true }
                                Component.onCompleted: {
                                    [
                                        { value: EmailModel.Unknown, text: "Unknown" },
                                        { value: EmailModel.Home, text: i18n("Home") },
                                        { value: EmailModel.Work, text: i18n("Work") },
                                        { value: EmailModel.Other, text: i18n("Other") }
                                    ].forEach((type) => {
                                        emailTypeModel.append(type);
                                    });
                                }
                                textRole: "text"
                                valueRole: "value"
                                currentIndex: typeValue
                                onCurrentValueChanged: type = currentValue
                            }
                            QQC2.TextField {
                                id: textField
                                Layout.fillWidth: true
                                text: model.display
                                inputMethodHints: Qt.ImhEmailCharactersOnly
                                onTextChanged: model.display = text;
                            }
                            QQC2.Button {
                                icon.name: "list-remove"
                                implicitWidth: implicitHeight
                                QQC2.ToolTip {
                                    text: i18n("Remove email")
                                }
                                onClicked: contactEditor.contact.emailModel.deleteEmail(index)
                            }
                        }
                    }
                }
                MobileForm.AbstractFormDelegate {
                    Layout.fillWidth: true
                    contentItem: RowLayout {
                        visible: !root.saving
                        QQC2.ComboBox {
                            id: newEmailType
                            model: ListModel {id: newEmailTypeModel; dynamicRoles: true }
                            textRole: "text"
                            valueRole: "value"
                            currentIndex: 0
                            Component.onCompleted: {
                                [
                                    { value: EmailModel.Home, text: i18n("Home") },
                                    { value: EmailModel.Work, text: i18n("Work") },
                                    { value: EmailModel.Both, text: i18n("Both") },
                                    { value: EmailModel.Other, text: i18n("Other…") }
                                ].forEach((type) => {
                                    newEmailTypeModel.append(type);
                                });
                            }
                        }
                        QQC2.TextField {
                            id: toAddEmail
                            Layout.fillWidth: true
                            placeholderText: i18n("user@example.org")
                            inputMethodHints: Qt.ImhEmailCharactersOnly
                        }

                        QQC2.Button {
                            icon.name: "list-add"
                            implicitWidth: implicitHeight
                            enabled: toAddEmail.text.length > 0
                            QQC2.ToolTip {
                                text: i18n("Add email")
                            }
                            onClicked: {
                                contactEditor.contact.emailModel.addEmail(toAddEmail.text, newEmailType.currentValue);
                                toAddEmail.text = '';
                                newEmailType.currentIndex = 0;
                            }
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
                    title: i18n("Instant Messenger")
                }

                Repeater {
                    model: contactEditor.contact.imppModel

                    delegate: MobileForm.AbstractFormDelegate {
                        id: imppDelegate

                        required property int index
                        required property string url
                        required property var model

                        background: Item {}
                        Layout.fillWidth: true

                        contentItem: RowLayout {
                            QQC2.TextField {
                                id: imppField
                                text: imppDelegate.url
                                inputMethodHints: Qt.ImhEmailCharactersOnly
                                Layout.fillWidth: true
                                onTextChanged: imppDelegate.model.url = text
                            }

                            QQC2.Button {
                                icon.name: "list-remove"
                                implicitWidth: implicitHeight
                                onClicked: contactEditor.contact.imppModel.deleteImpp(imppDelegate.index);
                            }
                        }
                    }
                }

                MobileForm.AbstractFormDelegate {
                    background: Item {}
                    Layout.fillWidth: true
                    contentItem: RowLayout {
                        QQC2.TextField {
                            id: toAddImpp
                            Layout.fillWidth: true
                            placeholderText: i18n("protocol:person@example.com")
                            inputMethodHints: Qt.ImhEmailCharactersOnly
                        }

                        // button to add additional text field
                        QQC2.Button {
                            icon.name: "list-add"
                            implicitWidth: implicitHeight
                            enabled: toAddImpp.text.length > 0
                            onClicked: {
                                contactEditor.contact.imppModel.addImpp(toAddImpp.text);
                                toAddImpp.text = "";
                            }
                        }
                    }
                }

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
        }
    }


    footer: ColumnLayout {
        spacing: 0

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        QQC2.DialogButtonBox {
            Layout.fillWidth: true

            standardButtons: QQC2.DialogButtonBox.Cancel

            QQC2.Button {
                icon.name: mode === ContactEditor.EditMode ? "document-save" : "list-add"
                text: mode === ContactEditor.EditMode ? i18n("Save") : i18n("Add")
                enabled: contactEditor.contact.formattedName.length > 0
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            onRejected: {
                ContactConfig.lastUsedAddressBookCollection = addressBookComboBox.defaultCollectionId;
                ContactConfig.save();
                root.closeDialog();
            }
            onAccepted: submitAction.trigger();
        }
    }

    property QQC2.Dialog itemChangedExternallySheet: QQC2.Dialog {
        id: itemChangedExternallySheet
        visible: false
        title: i18n('Warning')
        modal: true
        focus: true
        x: (parent.width - width) / 2
        y: parent.height / 3
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 30)

        contentItem: ColumnLayout {
            Kirigami.Heading {
                level: 4
                text: i18n('This contact was changed elsewhere during editing.')
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            QQC2.Label {
                text: i18n('Which changes should be kept?')
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
        onRejected: itemChangedExternallySheet.close()
        onAccepted: {
            contactEditor.fetchItem();
            itemChangedExternallySheet.close();
        }

        footer: QQC2.DialogButtonBox {
            QQC2.Button {
                text: i18n("Current changes")
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            QQC2.Button {
                text: i18n("External changes")
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.RejectRole
            }
        }
    }
}
