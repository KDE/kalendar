// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kalendar 1.0

Kirigami.ScrollablePage {
    id: page
    property var contact
    property int itemId
    title: addressee.name
    property int mode: KalendarApplication.Contact

    leftPadding: 0
    rightPadding: 0
    topPadding: 0

    property AddresseeWrapper addressee: AddresseeWrapper {
        addresseeItem: ContactManager.getItem(page.itemId)
    }

    //actions {
    //    main: Kirigami.Action {
    //        iconName: "document-edit"
    //        text: i18n("Edit")
    //        onTriggered: {
    //            pageStack.pushDialogLayer(Qt.resolvedUrl("AddContactPage.qml"), {
    //                state: "update",
    //                person: personData.person,
    //                addressee: page.addressee
    //            })
    //        }
    //    }
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

    ColumnLayout {
        spacing: 0
        Header {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 8

            source: addressee.photo.isIntern ? addressee.photo.data : addressee.photo.url

            backgroundSource: "qrc:/fallbackBackground.png"

            contentItems: [
                Kirigami.Heading {
                    text: addressee.name
                    color: "#fcfcfc"
                    level: 2
                },
                Repeater {
                    model: addressee.phoneNumbers
                    Kirigami.Heading {
                        text: modelData.normalizedNumber
                        color: "#fcfcfc"
                        level: 3
                    }
                }
            ]
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
                            applicationWindow().showPassiveNotification(i18n("Call support is not implemented yet"));
                            //const model = addressee.phoneNumbers

                            //if (addressee.phoneNumbers.length === 1) {
                            //    page.callNumber(model[0].normalizedNumber)
                            //} else {
                            //    var pop = callPopup.createObject(page, {numbers: addressee.phoneNumbers, title: i18n("Select number to call")})
                            //    pop.onNumberSelected.connect(number => callNumber(number))
                            //    pop.open()
                            //}
                        }
                    },
                    Kirigami.Action {
                        text: i18n("Send SMS")
                        iconName: "mail-message"
                        visible: addressee.phoneNumbers.length > 0
                        onTriggered: {
                            applicationWindow().showPassiveNotification(i18n("SMS support is not implemented yet"));
                            //var model = addressee.phoneNumbers

                            //if (addressee.phoneNumbers.length === 1) {
                            //    page.sendSms(model[0].normalizedNumber)
                            //} else {
                            //    var pop = callPopup.createObject(page, {
                            //        numbers: addressee.phoneNumbers,
                            //        title: i18n("Select number to send message to"),
                            //    })
                            //    pop.onNumberSelected.connect(number => sendSms(number))
                            //    pop.open()
                            //}
                        }
                    },
                    Kirigami.Action {
                        text: i18n("Send email")
                        iconName: "mail-message"
                        visible: addressee.preferredEmail.length > 0
                        onTriggered: Qt.openUrlExternally(`mailto:${addressee.preferredEmail}`)
                    }
                ]
            }
        }

        Kirigami.FormLayout {
            width: parent.width
            Controls.Label {
                visible: text !== ""
                // We do not always have the year
                text: if (addressee.birthday.getFullYear() === 0) {
                    return Qt.formatDate(addressee.birthday, "dd.MM.")
                } else {
                    return Qt.formatDate(addressee.birthday)
                }
                Kirigami.FormData.label: i18n("Birthday:")
            }
            Repeater {
                model: addressee.addressesModel
                Controls.Label {
                    visible: text !== ""
                    text: model.formattedAddress
                    Kirigami.FormData.label: i18nc("%1 is the type of the address, e.g. home, work, ...", "%1:", model.typeLabel)
                    Kirigami.FormData.labelAlignment: Qt.AlignTop
                }
            }
        }
    }
}
