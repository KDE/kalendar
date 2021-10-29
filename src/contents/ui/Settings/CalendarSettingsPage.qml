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
            Layout.fillHeight: true
            Layout.fillWidth: true

            Component.onCompleted: background.visible = true

            ListView {
                id: collectionsList
                delegate: DelegateChooser {
                    role: 'kDescendantExpandable'

                    DelegateChoice {
                        roleValue: true

                        Kirigami.BasicListItem {
                            hoverEnabled: false
                            label: display
                            labelItem.color: Kirigami.Theme.disabledTextColor
                            labelItem.font.weight: Font.DemiBold
                            separatorVisible: false
                            topPadding: 2 * Kirigami.Units.largeSpacing

                            onClicked: collectionsList.model.toggleChildren(index)

                            background: Item {
                            }
                            trailing: Kirigami.Icon {
                                height: Kirigami.Units.iconSizes.small
                                source: model.kDescendantExpanded ? 'arrow-up' : 'arrow-down'
                                width: Kirigami.Units.iconSizes.small
                                x: -4
                            }
                        }
                    }
                    DelegateChoice {
                        roleValue: false

                        Kirigami.BasicListItem {
                            property int itemCollectionId: model.collectionId

                            hoverEnabled: false
                            label: display
                            labelItem.color: Kirigami.Theme.textColor
                            separatorVisible: false

                            trailing: ColoredCheckbox {
                                checked: model.checkState === 2
                                color: model.collectionColor

                                onClicked: model.checkState = model.checkState === 0 ? 2 : 0
                            }
                        }
                    }
                }
                model: KDescendantsProxyModel {
                    model: CalendarManager.collections
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true

            Controls.Button {
                Layout.alignment: Qt.AlignRight
                enabled: collectionsList.currentItem && collectionsList.currentItem.trailing.visible
                icon.name: "edit-entry"
                text: i18n("Change Calendar Color…")

                onClicked: {
                    colorDialog.color = collectionsList.currentItem.trailing.color;
                    colorDialog.open();
                }

                ColorDialog {
                    id: colorDialog
                    title: i18n("Choose Calendar Color")

                    onAccepted: {
                        CalendarManager.setCollectionColor(collectionsList.currentItem.itemCollectionId, color);
                    }
                    onRejected: {
                        close();
                    }
                }
            }
        }
    }
}
