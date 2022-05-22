// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.19 as Kirigami
import org.kde.kalendar.contact 1.0
import org.kde.akonadi 1.0 as Akonadi

Kirigami.ScrollablePage {
    id: root
    property alias mode: contactGroupEditor.mode
    property var item
    title: mode === ContactGroupEditor.EditMode && contactGroupEditor.name ? i18n('Edit %1', contactGroupEditor.name) : i18n('Create Contact Group')

    onItemChanged: contactGroupEditor.loadContactGroup(item)

    property ContactGroupEditor contactGroupEditor: ContactGroupEditor {
        id: contactGroupEditor
        mode: ContactGroupEditor.CreateMode
        onFinished: root.closeDialog()
        onErrorOccured: {
            errorContainer.errorMessage = error;
            errorContainer.visible = true;
        }
        onItemChangedExternally: itemChangedExternallySheet.open()
    }

    QQC2.Action {
        id: submitAction
        enabled: contactGroupEditor.name.length > 0
        shortcut: "Return"
        onTriggered: {
            contactGroupEditor.saveContactGroup()
            ContactConfig.lastUsedAddressBookCollection = addressBookComboBox.defaultCollectionId;
            ContactConfig.save();
        }
    }

    header: QQC2.Control {
        id: errorContainer
        property bool displayError: false
        property string errorMessage: ''
        padding: Kirigami.Units.smallSpacing
        contentItem: Kirigami.InlineMessage {
            type: Kirigami.MessageType.Error
            visible: errorContainer.displayError
            text: errorContainer.errorMessage
            showCloseButton: true
        }
    }

    ColumnLayout {
        Kirigami.FormLayout {
            Layout.fillWidth: true

            Akonadi.CollectionComboBox {
                id: addressBookComboBox

                Kirigami.FormData.label: i18n("Address Book:")
                Layout.fillWidth: true
                enabled: mode === ContactGroupEditor.CreateMode

                defaultCollectionId: if (mode === ContactGroupEditor.CreateMode) {
                    return ContactConfig.lastUsedAddressBookCollection;
                } else {
                    return contactGroupEditor.collectionId;
                }

                mimeTypeFilter: [Akonadi.MimeTypes.address, Akonadi.MimeTypes.contactGroup]
                accessRightsFilter: Akonadi.Collection.CanCreateItem
                onSelectedCollectionChanged: contactGroupEditor.setDefaultAddressBook(collection)
            }

            QQC2.TextField {
                Kirigami.FormData.label: i18n("Name:")
                text: contactGroupEditor.name
                onTextChanged: contactGroupEditor.name = text;
            }

            ColumnLayout {
                Kirigami.FormData.label: repeater.count > 0 ? i18n("Members:") : ''
                Kirigami.FormData.labelAlignment: repeater.count > 1 ? Qt.AlignTop : Qt.AlignVCenter
                Repeater {
                    id: repeater
                    model: contactGroupEditor.groupModel
                    RowLayout {
                        QQC2.TextField {
                            text: model.display
                            enabled: false
                            implicitWidth: Kirigami.Units.gridUnit * 10
                        }
                        QQC2.TextField {
                            text: model.email
                            enabled: false
                            implicitWidth: Kirigami.Units.gridUnit * 10
                        }
                        QQC2.Button {
                            icon.name: 'list-remove'
                            onClicked: contactGroupEditor.groupModel.removeContact(index)
                        }
                    }
                }
            }
            RowLayout {
                Kirigami.FormData.label: repeater.count === 0 ? i18n("Members:") : ''
                Kirigami.FormData.labelAlignment: Qt.AlignVCenter
                QQC2.ComboBox {
                    id: nameSearch
                    textRole: 'display'
                    valueRole: 'gid'
                    model: ContactsModel {}
                    editable: true
                    implicitWidth: Kirigami.Units.gridUnit * 10
                    onCurrentIndexChanged: {
                        const allEmail = nameSearch.model.data(nameSearch.model.index(currentIndex, 0), ContactsModel.AllEmailsRole);
                        const preferredEmail = nameSearch.model.data(nameSearch.model.index(currentIndex, 0), ContactsModel.EmailRole);
                        emailSearch.currentIndex = emailSearch.indexOfValue(preferredEmail);
                        emailSearch.model = allEmail;
                    }
                }
                QQC2.ComboBox {
                    id: emailSearch
                    enabled: model.length !== 0
                    model: []
                    implicitWidth: Kirigami.Units.gridUnit * 10
                }

                QQC2.Button {
                    icon.name: 'list-add'
                    enabled: emailSearch.currentIndex > 0 || (emailSearch.editText.length > 0 && nameSearch.editText.length > 0)
                    onClicked: {
                        contactGroupEditor.groupModel.addContactFromReference(nameSearch.currentValue, emailSearch.currentValue)
                        emailSearch.editText = '';
                        nameSearch.editText = '';
                        emailSearch.currentIndex = -1;
                    }
                }
            }
            QQC2.Label {
                text: i18n('Only contacts with an email address can be added to a contact group')
                font: Kirigami.Theme.smallFont
            }
        }
    }

    footer: QQC2.DialogButtonBox {
        standardButtons: QQC2.DialogButtonBox.Cancel

        QQC2.Button {
            icon.name: mode === ContactGroupEditor.EditMode ? "document-save" : "list-add"
            text: mode === ContactGroupEditor.EditMode ? i18n("Save") : i18n("Add")
            enabled: contactGroupEditor.name.length > 0
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
        }

        onRejected: {
            ContactConfig.lastUsedAddressBookCollection = addressBookComboBox.defaultCollectionId;
            ContactConfig.save();
            root.closeDialog();
        }
        onAccepted: submitAction.trigger()
    }

    property QQC2.Dialog itemChangedExternallySheet: QQC2.Dialog {
        id: itemChangedExternallySheet
        visible: false
        title: i18n('Warning')
        modal: true
        focus: true
        x: (parent.width - width) / 2
        y: parent.height / 3
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 20)

        contentItem: ColumnLayout {
            Kirigami.Heading {
                level: 4
                text: i18n('This contact group was changed elsewhere during editing.')
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
            contactGroupEditor.fetchItem();
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