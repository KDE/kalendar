// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0

Kirigami.Page {
    id: deleteSheet

    signal deleteCollection(int collectionId)
    signal cancel

    // For calendar deletion
    property int collectionId
    property var collectionDetails

    padding: Kirigami.Units.largeSpacing

    title: collectionId ? i18n("Delete calendar") : i18n("Delete")

    QQC2.Action {
        id: deleteAction
        enabled: collectionId !== undefined
        shortcut: "Return"
        onTriggered: {
            deleteCollection(deleteSheet.collectionId);
        }
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Kirigami.Icon {
                Layout.fillHeight: true
                Layout.minimumHeight: Kirigami.Units.gridUnit * 3
                Layout.minimumWidth: height
                source: "dialog-warning"
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: if(collectionDetails) i18n("Do you want to delete calendar: \"%1\"?", collectionDetails.displayName)
                wrapMode: Text.WordWrap
            }
        }


        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Item {
                Layout.fillWidth: true
            }

            QQC2.Button {
                icon.name: "delete"
                text: i18n("Delete")
                onClicked: deleteCollection(deleteSheet.collectionId)
            }

            QQC2.Button {
                icon.name: "dialog-cancel"
                text: i18n("Cancel")
                onClicked: cancel()
            }
        }
    }
}

