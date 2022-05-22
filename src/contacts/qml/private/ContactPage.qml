// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kalendar 1.0
import org.kde.kalendar.contact 1.0

Kirigami.ScrollablePage {
    id: page
    property int itemId
    title: addressee.name
    property int mode: KalendarApplication.Contact

    leftPadding: 0
    rightPadding: 0
    topPadding: 0

    property AddresseeWrapper addressee: AddresseeWrapper {
        addresseeItem: ContactManager.getItem(page.itemId)
    }

    actions {
        main: Kirigami.Action {
            iconName: "document-edit"
            text: i18n("Edit")
            onTriggered: {
                pageStack.pushDialogLayer(Qt.resolvedUrl("ContactEditorPage.qml"), {
                    mode: ContactEditor.EditMode,
                    item: page.addressee.addresseeItem,
                })
            }
        }
    }
    //    contextualActions: [
    //        Kirigami.Action {
    //            iconName: "delete"
    //            text: i18n("Delete contact")
    //            onTriggered: {
    //                KPeople.PersonPluginManager.deleteContact(page.personUri)
    //                pageStack.pop()
    //            }
    //        }
    //    ]
    //    left: Kirigami.Action {
    //        text: i18n("Cancel")
    //        icon.name: "dialog-cancel"
    //        visible: Kirigami.Settings.isMobile

    //        onTriggered: {
    //            pageStack.pop()
    //        }
    //    }
    //}

    Kirigami.Theme.colorSet: Kirigami.Theme.View

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

        Controls.ToolBar {
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
        Kirigami.FormLayout {
            id: contactForm
            twinFormLayouts: [addreseesForm, phoneForm, contactForm, businessForm]
            Layout.fillWidth: true
            Item {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Contact information")
            }

            Controls.Label {
                visible: text !== ""
                text: addressee.formattedName
                Kirigami.FormData.label: i18n("Name:")
            }

            Controls.Label {
                visible: text !== ""
                text: addressee.nickName
                Kirigami.FormData.label: i18n("Nickname:")
            }

            Controls.Label {
                id: blogFeed
                visible: addressee.blogFeed + '' !== ''
                // We do not always have the year
                text: `<a href="${addressee.blogFeed}">${addressee.blogFeed}</a>`
                Kirigami.FormData.label: i18n("Blog Feed:")
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally(addressee.blogFeed)
                    onPressed: Qt.openUrlExternally(addressee.blogFeed)
                }
            }

            Item {
                visible: birthday.visible || anniversary.visible || spousesName.visible
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Personal information")
            }

            Controls.Label {
                id: birthday
                visible: text !== ""
                // We do not always have the year
                text: if (addressee.birthday.getFullYear() === 0) {
                    return Qt.formatDate(addressee.birthday, i18nc('Day month format', 'dd.MM.'))
                } else {
                    return addressee.birthday.toLocaleDateString()
                }
                Kirigami.FormData.label: i18n("Birthday:")
            }

            Controls.Label {
                id: anniversary
                visible: text !== ""
                // We do not always have the year
                text: if (addressee.anniversary.getFullYear() === 0) {
                    return Qt.formatDate(addressee.anniversary, i18nc('Day month format', 'dd.MM.'))
                } else {
                    return addressee.anniversary.toLocaleDateString()
                }
                Kirigami.FormData.label: i18n("Anniversary:")
            }

            Controls.Label {
                id: spousesName
                visible: text !== ""
                text: addressee.spousesName
                Kirigami.FormData.label: i18n("Partner's name:")
            }
        }

        Kirigami.FormLayout {
            id: phoneForm
            twinFormLayouts: [emailForm, contactForm, businessForm]
            Layout.fillWidth: true

            Item {
                visible: phoneRepeater.count > 0
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18np("Phone Number", "Phone Numbers", addressee.phoneModel.count)
            }

            Repeater {
                id: phoneRepeater
                model: addressee.phoneModel
                Controls.Label {
                    visible: text !== ""
                    text: `<a href="tel:${model.display}">${model.display}</a>`
                    onLinkActivated: Qt.openUrlExternally(link)
                    Kirigami.FormData.label: i18nc("Label for a phone number type", "%1:", model.type)
                    Kirigami.FormData.labelAlignment: Qt.AlignTop
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally(`tel:${model.display}`)
                        onPressed: Qt.openUrlExternally(`tel:${model.display}`)
                    }
                }
            }
        }

        Kirigami.FormLayout {
            id: addreseesForm
            twinFormLayouts: [emailForm, phoneForm, contactForm, businessForm]
            Layout.fillWidth: true

            Item {
                visible: addressesRepeater.count > 0
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18np("Address", "Addresses", addressesRepeater.count)
            }

            Repeater {
                id: addressesRepeater
                model: addressee.addressesModel
                Controls.Label {
                    visible: text !== ""
                    text: model.formattedAddress
                    Kirigami.FormData.label: model.typeLabel ? i18nc("%1 is the type of the address, e.g. home, work, ...", "%1:", model.typeLabel) : i18n("Home:")
                    Kirigami.FormData.labelAlignment: Qt.AlignTop
                }
            }
        }

        Kirigami.FormLayout {
            id: businessForm
            twinFormLayouts: [emailForm, addreseesForm, contactForm, phoneForm]
            Layout.fillWidth: true

            Item {
                Kirigami.FormData.isSection: true
                visible: organization.visible || profession.visible || title.visible || department.visible || office.visible || managersName.visible || assistantsName.visible
                Kirigami.FormData.label: i18n("Business Information")
            }

            Controls.Label {
                id: organization
                visible: text !== ""
                text: addressee.organization
                Kirigami.FormData.label: i18n("Organization:")
            }

            Controls.Label {
                id: profession
                visible: text !== ""
                text: addressee.profession
                Kirigami.FormData.label: i18n("Profession:")
            }

            Controls.Label {
                id: title
                visible: text.trim() !== ""
                text: addressee.title
                Kirigami.FormData.label: i18n("Title:")
            }

            Controls.Label {
                id: department
                visible: text !== ""
                text: addressee.department
                Kirigami.FormData.label: i18n("Department:")
            }

            Controls.Label {
                id: office
                visible: text !== ""
                text: addressee.office
                Kirigami.FormData.label: i18n("Office:")
            }

            Controls.Label {
                id: managersName
                visible: text !== ""
                text: addressee.managersName
                Kirigami.FormData.label: i18n("Manager's name:")
            }

            Controls.Label {
                id: assistantsName
                visible: text !== ""
                text: addressee.assistantsName
                Kirigami.FormData.label: i18n("Assistants's name:")
            }
        }

        Kirigami.FormLayout {
            id: emailForm
            twinFormLayouts: [addreseesForm, phoneForm, contactForm, businessForm]
            Layout.fillWidth: true

            Item {
                Kirigami.FormData.isSection: true
                visible: emailRepeater.count > 0
                Kirigami.FormData.label: i18np("Email Address", "Email Addresses", emailRepeater.count > 0)
            }

            Repeater {
                id: emailRepeater
                model: addressee.emailModel
                Controls.Label {
                    visible: text !== ""
                    text: `<a href="mailto:${model.display}">${model.display}</a>`
                    onLinkActivated: Qt.openUrlExternally(link)
                    Kirigami.FormData.label: model.type
                    Kirigami.FormData.labelAlignment: Qt.AlignTop
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally(`mailto:${model.display}`)
                        onPressed: Qt.openUrlExternally(`mailto:${model.display}`)
                    }
                }
            }
        }
    }
}
