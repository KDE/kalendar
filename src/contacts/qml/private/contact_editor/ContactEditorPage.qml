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

    function isNotEmptyStr(str) {
        return str.trim().length > 0;
    }
    QQC2.Action {
        id: submitAction
        enabled: contactEditor.contact.formattedName.length > 0
        shortcut: "Return"
        onTriggered: {
            root.saving = true;
            if (phoneEditorId.phoneText.length > 0) {
                contactEditor.contact.phoneModel.addPhoneNumber(phoneEditorId.phoneText, phoneEditorId.newPhoneTypeComboText)
            }
            if (emailEditorId.toAddEmailText > 0) {
                contactEditor.contact.emailModel.addEmail(emailEditorId.toAddEmailText, emailEditorId.newEmailTypeCurrentValue);
            }
            contactEditor.saveContactInAddressBook()
            Config.lastUsedAddressBookCollection = addressBookId.addressBookComboBoxId;
            Config.save();
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
        PhotoEditor {
            contactEditor: root.contactEditor
        }

        AddressBookEditorCard {
            id: addressBookEditorCard
            contactEditor: root.contactEditor
            mode: root.mode
        }

        BusinessEditorCard {
            contactEditor: root.contactEditor
        }

        PhoneEditorCard {
            contactEditor: root.contactEditor
        }

        EmailEditorCard {
            contactEditor: root.contactEditor
        }

        InstantMessengerEditorCard {
            contactEditor: root.contactEditor
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
                Config.lastUsedAddressBookCollection = addressBookEditorCard.addressBookComboBox.defaultCollectionId;
                Config.save();
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
