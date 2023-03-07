// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kalendar 1.0
import org.kde.kalendar.contact 1.0
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm

Kirigami.ScrollablePage {
    id: page
    property int itemId
    title: addressee.formattedName
    property int mode: KalendarApplication.Contact

    leftPadding: 0
    rightPadding: 0

    property AddresseeWrapper addressee: AddresseeWrapper {
        id: addressee
        addresseeItem: ContactManager.getItem(page.itemId)
    }

    function openEditor() {
        pageStack.pushDialogLayer(Qt.resolvedUrl("ContactEditorPage.qml"), {
            mode: ContactEditor.EditMode,
            item: page.addressee.addresseeItem,
        })
    }

    actions {
        main: Kirigami.Action {
            iconName: "document-edit"
            text: i18nc("@action:inmenu", "Edit")
            onTriggered: openEditor()
        }

        contextualActions: DeleteContactAction {
            name: page.addressee.formattedName
            item: page.addressee.addresseeItem
        }

        left: Kirigami.Action {
            text: i18n("Cancel")
            icon.name: "dialog-cancel"
            visible: Kirigami.Settings.isMobile

            onTriggered: {
                pageStack.pop()
            }
        }
    }

    function callNumber(number) {
        Qt.openUrlExternally("tel:" + number)
    }

    function sendSms(number) {
        Qt.openUrlExternally("sms:" + number)
    }

    Component {
        id: callPopup

        PhoneNumberDialog {}
    }

    header: ColumnLayout {
        spacing: 0
        Header {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 8

            source: addressee.photo.isIntern ? addressee.photo.data : addressee.photo.url

            backgroundSource: "qrc:/fallbackBackground.png"

            contentItems: Kirigami.Heading {
                text: addressee.formattedName
                color: "#fcfcfc"
            }
        }

        QQC2.ToolBar {
            Layout.fillWidth: true
            contentItem: Kirigami.ActionToolBar {
                id: toolbar

                actions: [
                    Kirigami.Action {
                        text: i18n("Call")
                        iconName: "call-start"
                        visible: addressee.phoneNumbers.length > 0
                        onTriggered: {
                            const model = addressee.phoneNumbers;

                            if (addressee.phoneNumbers.length === 1) {
                                page.callNumber(model[0].normalizedNumber);
                            } else {
                                const pop = callPopup.createObject(page, {
                                    numbers: addressee.phoneNumbers,
                                    title: i18n("Select number to call")
                                });
                                pop.onNumberSelected.connect(number => callNumber(number));
                                pop.open();
                            }
                        }
                    },
                    Kirigami.Action {
                        text: i18n("Send SMS")
                        iconName: "mail-message"
                        visible: addressee.phoneNumbers.length > 0
                        onTriggered: {
                            const model = addressee.phoneNumbers;

                            if (addressee.phoneNumbers.length === 1) {
                                page.sendSms(model[0].normalizedNumber);
                            } else {
                                const pop = callPopup.createObject(page, {
                                    numbers: addressee.phoneNumbers,
                                    title: i18n("Select number to send message to"),
                                });
                                pop.onNumberSelected.connect(number => sendSms(number));
                                pop.open();
                            }
                        }
                    },
                    Kirigami.Action {
                        text: i18n("Send email")
                        iconName: "mail-message"
                        visible: addressee.preferredEmail.length > 0
                        onTriggered: Qt.openUrlExternally(`mailto:${addressee.preferredEmail}`)
                    },
                    Kirigami.Action {
                        text: i18n("Show QR Code")
                        iconName: 'view-barcode-qr'
                        onTriggered: pageStack.layers.push(Qt.resolvedUrl('./QrCodePage.qml'), {
                            qrCodeData: addressee.qrCodeData(),
                        })
                    }
                ]
            }
        }
    }

    ColumnLayout {
        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing

            contentItem: ColumnLayout {
                spacing: 0

                MobileForm.FormCardHeader {
                    title: i18n("Contact information")
                }

                MobileForm.FormTextDelegate {
                    visible: description !== ""
                    description: addressee.formattedName
                    text: i18n("Name:")
                }

                MobileForm.FormTextDelegate {
                    visible: description !== ""
                    description: addressee.nickName
                    text: i18n("Nickname:")
                }

                MobileForm.FormButtonDelegate {
                    id: blogFeed
                    visible: addressee.blogFeed + '' !== ''
                    text: i18n("Blog Feed:")
                    // We do not always have the year
                    description: `<a href="${addressee.blogFeed}">${addressee.blogFeed}</a>`
                    onClicked: Qt.openUrlExternally(addressee.blogFeed)
                }
            }
        }

        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            visible: birthday.visible || anniversary.visible || spousesName.visible

            contentItem: ColumnLayout {
                spacing: 0

                MobileForm.FormCardHeader {
                    title: i18n("Personal information")
                }

                MobileForm.FormTextDelegate {
                    id: birthday
                    visible: description !== ""
                    text: i18n("Birthday:")
                    // We do not always have the year
                    description: if (addressee.birthday.getFullYear() === 0) {
                        return Qt.formatDate(addressee.birthday, i18nc('Day month format', 'dd.MM.'))
                    } else {
                        return addressee.birthday.toLocaleDateString()
                    }
                }

                MobileForm.FormTextDelegate {
                    id: anniversary
                    visible: description !== ""
                    // We do not always have the year
                    description: if (addressee.anniversary.getFullYear() === 0) {
                        return Qt.formatDate(addressee.anniversary, i18nc('Day month format', 'dd.MM.'))
                    } else {
                        return addressee.anniversary.toLocaleDateString()
                    }
                    text: i18n("Anniversary:")
                }

                MobileForm.FormTextDelegate {
                    id: spousesName
                    visible: description !== ""
                    description: addressee.spousesName
                    text: i18n("Partner's name:")
                }
            }
        }

        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing

            visible: phoneRepeater.count > 0

            contentItem: ColumnLayout {
                spacing: 0

                MobileForm.FormCardHeader {
                    title: i18np("Phone Number", "Phone Numbers", addressee.phoneModel.count)
                }

                Repeater {
                    id: phoneRepeater

                    model: addressee.phoneModel
                    delegate: MobileForm.FormButtonDelegate {
                        required property string phoneNumber
                        required property string type

                        visible: text.length > 0
                        text: i18nc("Label for a phone number type", "%1:", type)
                        description: phoneNumber
                        onClicked: Qt.openUrlExternally(link)
                    }
                }
            }
        }

        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing

            visible: addressesRepeater.count > 0

            contentItem: ColumnLayout {
                spacing: 0

                MobileForm.FormCardHeader {
                    title: i18np("Address", "Addresses", addressesRepeater.count)
                }


                Repeater {
                    id: addressesRepeater
                    model: addressee.addressesModel

                    delegate: MobileForm.FormTextDelegate {
                        required property string formattedAddress
                        required property string typeLabel

                        visible: text.length > 0

                        text: typeLabel ? i18nc("%1 is the type of the address, e.g. home, work, ...", "%1:", typeLabel) : i18n("Home:")
                        description: formattedAddress
                    }
                }
            }
        }

        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing

            visible: imppRepeater.count > 0

            contentItem: ColumnLayout {
                spacing: 0

                MobileForm.FormCardHeader {
                    title: i18n("Instant Messaging")
                }

                Repeater {
                    id: imppRepeater

                    model: addressee.imppModel
                    delegate: MobileForm.FormButtonDelegate {
                        id: imppDelegate

                        required property string url
                        readonly property var parts: url.split(':')
                        readonly property string protocol: parts.length > 0 ? parts[0] : ''
                        readonly property string address: parts.length > 0 ? parts.slice(1, parts.length).join(':') : ''
                        readonly property bool isMatrix: protocol === 'matrix'

                        visible: text !== ""
                        text: i18nc("Label for a messaging protocol", "%1:", isMatrix ? 'Matrix' : protocol)
                        description: address

                        onClicked: Qt.openUrlExternally(parent.url)
                    }
                }
            }
        }

        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing

            visible: addressee.organization.length > 0
                || addressee.profession.length > 0
                || addressee.title.length > 0
                || addressee.department.length > 0
                || addressee.office.length > 0
                || addressee.managersName.length > 0
                || addressee.assistantsName.length > 0

            contentItem: ColumnLayout {
                spacing: 0

                MobileForm.FormCardHeader {
                    title: i18n("Business Information")
                }

                MobileForm.FormTextDelegate {
                    id: organization
                    visible: description.length > 0
                    text: i18n("Organization:")
                    description: addressee.organization
                }

                MobileForm.FormTextDelegate {
                    id: profession
                    visible: description.length > 0
                    text: i18n("Profession:")
                    description: addressee.profession
                }

                MobileForm.FormTextDelegate {
                    id: title
                    visible: description !== ''
                    text: i18n("Title:")
                    description: addressee.title
                }

                MobileForm.FormTextDelegate {
                    id: department
                    visible: description !== ''
                    text: i18n("Department:")
                    description: addressee.department
                }

                MobileForm.FormTextDelegate {
                    id: office
                    visible: description.length > 0
                    text: i18n("Office:")
                    description: addressee.office
                }

                MobileForm.FormTextDelegate {
                    id: managersName
                    visible: description.length > 0
                    text: i18n("Manager's name:")
                    description: addressee.managersName
                }

                MobileForm.FormTextDelegate {
                    id: assistantsName
                    visible: description.length > 0
                    text: i18n("Assistants's name:")
                    description: addressee.assistantsName
                }
            }
        }

        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing

            visible: imppRepeater.count > 0

            contentItem: ColumnLayout {
                spacing: 0

                MobileForm.FormCardHeader {
                    title: i18np("Email Address", "Email Addresses", emailRepeater.count > 0)
                }

                Repeater {
                    id: emailRepeater

                    model: addressee.emailModel
                    delegate: MobileForm.FormButtonDelegate {
                        required property string email

                        text: email
                        onClicked: Qt.openUrlExternally(`mailto:${email}`)
                    }
                }
            }
        }
    }
}
