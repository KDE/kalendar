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

MobileForm.FormCard {
    id: root

    required property ContactEditor contactEditor
    required property bool mode

    Layout.fillWidth: true
    Layout.topMargin: Kirigami.Units.largeSpacing

    property alias addressBookComboBoxId: addressBookComboBox.defaultCollectionId;
    property alias addressBookComboBox: addressBookComboBox

    contentItem: ColumnLayout {
        spacing: 0

        Akonadi.MobileCollectionComboBox {
            id: addressBookComboBox

            text: i18n("Address book:")
            Layout.fillWidth: true
            enabled: mode === ContactEditor.CreateMode

            defaultCollectionId: if (mode === ContactEditor.CreateMode) {
                return Config.lastUsedAddressBookCollection;
            } else {
                return contactEditor.collectionId;
            }

            mimeTypeFilter: [Akonadi.MimeTypes.address, Akonadi.MimeTypes.contactGroup]
            accessRightsFilter: Akonadi.Collection.CanCreateItem
            onUserSelectedCollection: collection => contactEditor.setDefaultAddressBook(collection)
        }

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

        MobileForm.FormDelegateSeparator {}

        MobileForm.FormTextFieldDelegate {
            id: blogFeedUrl
            label: i18n("Blog Feed")
            text: contactEditor.contact.blogFeed
            onTextEdited: contactEditor.contact.blogFeed = text
            placeholderText: i18n("https://planet.kde.org/")
        }
    }
}
