// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.0
import org.kde.kalendar 1.0

Kirigami.Page {
    title: i18n("Calendars")
    ColumnLayout {
        anchors.fill: parent
        Controls.ScrollView {
            Component.onCompleted: background.visible = true
            Layout.fillWidth: true
            Layout.fillHeight: true
            ListView {
                id: collectionsList

                model: CalendarManager.collections
                delegate: Kirigami.BasicListItem {
                    property int itemCollectionId: collectionId
                    leftPadding: ((Kirigami.Units.gridUnit * 2) * (kDescendantLevel - 1)) + Kirigami.Units.largeSpacing
                    leading: Controls.CheckBox {
                        visible: model.checkState != null
                        checked: model.checkState == 2
                        onClicked: model.checkState = (checked ? 2 : 0)
                    }
                    trailing: Rectangle {
                        Layout.fillHeight: true
                        width: height
                        radius: 5
                        color: collectionColor
                        visible: collectionColor !== undefined
                    }
                    label: display
                    icon: decoration
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Controls.Button {
                Layout.alignment: Qt.AlignRight
                text: i18n("Change calendar color")
                icon.name: "edit-entry"
                enabled: collectionsList.currentItem && collectionsList.currentItem.trailing.visible
                onClicked: {
                    colorDialog.color = collectionsList.currentItem.trailing.color;
                    colorDialog.open();
                }

                ColorDialog {
                    id: colorDialog
                    title: i18n("Choose calendar color")
                    onAccepted: {
                        CalendarManager.setCollectionColor(collectionsList.currentItem.itemCollectionId, color)
                    }
                    onRejected: {
                        close();
                    }
                }
            }
        }
    }
}
