// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.0
import org.kde.kalendar 1.0
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0

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

                model: KDescendantsProxyModel {
                    model: CalendarManager.collections
                }
                delegate: DelegateChooser {
                    role: 'kDescendantExpandable'
                    DelegateChoice {
                        roleValue: true

                        Kirigami.BasicListItem {
                            label: display
                            labelItem.color: Kirigami.Theme.disabledTextColor
                            labelItem.font.weight: Font.DemiBold
                            topPadding: 2 * Kirigami.Units.largeSpacing
                            hoverEnabled: false
                            background: Item {}

                            separatorVisible: false

                            trailing: Kirigami.Icon {
                                width: Kirigami.Units.iconSizes.small
                                height: Kirigami.Units.iconSizes.small
                                source: model.kDescendantExpanded ? 'arrow-up' : 'arrow-down'
                                x: -4
                            }

                            onClicked: collectionsList.model.toggleChildren(index)
                        }
                    }

                    DelegateChoice {
                        roleValue: false
                        Kirigami.BasicListItem {
                            property int itemCollectionId: model.collectionId

                            label: display
                            labelItem.color: Kirigami.Theme.textColor
                            hoverEnabled: false
                            separatorVisible: false

                            trailing: ColoredCheckbox {
                                color: model.collectionColor
                                checked: model.checkState === 2
                                onClicked: model.checkState = model.checkState === 0 ? 2 : 0
                            }
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Controls.Button {
                Layout.alignment: Qt.AlignRight
                text: i18n("Change Calendar Color…")
                icon.name: "edit-entry"
                enabled: collectionsList.currentItem && collectionsList.currentItem.trailing.visible
                onClicked: {
                    colorDialog.color = collectionsList.currentItem.trailing.color;
                    colorDialog.open();
                }

                ColorDialog {
                    id: colorDialog
                    title: i18n("Choose Calendar Color")
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
