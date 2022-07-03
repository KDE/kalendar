// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kalendar 1.0
import org.kde.kalendar.contact 1.0

Kirigami.Action {
    property string name
    property var item

    icon.name: "delete"
    text: i18nc("@action:inmenu", "Delete contact")
    onTriggered: {
        const dialog = deleteContactConfirmationDialogComponent.createObject(applicationWindow())
        dialog.open()
    }

    Component {
        id: deleteContactConfirmationDialogComponent
        QQC2.Dialog {
            id: deleteContactConfirmationDialog
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
                    text: i18n('Do you really want to delete your contact: %1?', name)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                QQC2.Label {
                    text: i18n("You won't be able to revert this action")
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            onRejected: deleteContactConfirmationDialog.close()
            onAccepted: {
                ContactManager.deleteItem(item)
                if (applicationWindow().pageStack.depth > 1) {
                    applicationWindow().pageStack.pop()
                }
                deleteContactConfirmationDialog.close();
            }

            footer: QQC2.DialogButtonBox {
                QQC2.Button {
                    text: i18n("Cancel")
                    QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.RejectRole
                }
                QQC2.Button {
                    text: i18n("Delete contact")
                    QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
                }
            }
        }
    }
}
