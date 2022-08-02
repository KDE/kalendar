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
                            id: calendarSourceItem
                            label: display
                            labelItem.color: Kirigami.Theme.disabledTextColor
                            labelItem.font.weight: Font.DemiBold
                            topPadding: 2 * Kirigami.Units.largeSpacing
                            background: Item {}
                            leftPadding: Kirigami.Settings.isMobile ?
                                (Kirigami.Units.largeSpacing * 2 * model.kDescendantLevel) + (Kirigami.Units.iconSizes.smallMedium * (model.kDescendantLevel - 1)) :
                                (Kirigami.Units.largeSpacing * model.kDescendantLevel) + (Kirigami.Units.iconSizes.smallMedium * (model.kDescendantLevel - 1))
                            hoverEnabled: false

                            separatorVisible: false

                            leading: Kirigami.Icon {
                                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                color: calendarSourceItem.labelItem.color
                                isMask: true
                                source: model.decoration
                            }
                            leadingPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                            trailing: RowLayout {
                                Kirigami.Icon {
                                    implicitWidth: Kirigami.Units.iconSizes.small
                                    implicitHeight: Kirigami.Units.iconSizes.small
                                    source: model.kDescendantExpanded ? 'arrow-up' : 'arrow-down'
                                    color: calendarSourceItem.labelItem.color
                                    isMask: true
                                }
                                ColoredCheckbox {
                                    Layout.fillHeight: true
                                    visible: model.checkState != null
                                    color: model.collectionColor
                                    checked: model.checkState === 2
                                    onClicked: model.checkState = model.checkState === 0 ? 2 : 0
                                }
                            }

                            onClicked: collectionsList.model.toggleChildren(index)

                            CalendarItemTapHandler {
                                collectionId: model.collectionId
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: false
                        Kirigami.BasicListItem {
                            id: calendarItem
                            property int itemCollectionId: model.collectionId

                            label: display
                            labelItem.color: Kirigami.Theme.textColor
                            hoverEnabled: false
                            separatorVisible: false
                            leftPadding: Kirigami.Settings.isMobile ?
                                (Kirigami.Units.largeSpacing * 2 * model.kDescendantLevel) + (Kirigami.Units.iconSizes.smallMedium * (model.kDescendantLevel - 1)) :
                                (Kirigami.Units.largeSpacing * model.kDescendantLevel) + (Kirigami.Units.iconSizes.smallMedium * (model.kDescendantLevel - 1))

                            trailing: ColoredCheckbox {
                                color: model.collectionColor
                                checked: model.checkState === 2
                                onClicked: model.checkState = model.checkState === 0 ? 2 : 0
                            }

                            CalendarItemTapHandler {
                                collectionId: model.collectionId

                                property Component deleteCalendarPageComponent: Component {
                                    DeleteCalendarPage {
                                        id: deletePage
                                        onDeleteCollection: {
                                            CalendarManager.deleteCollection(collectionId);
                                            closeDialog();
                                        }
                                        onCancel: closeDialog()
                                    }
                                }

                                onDeleteCalendar: {
                                    const openDialogWindow = pageStack.pushDialogLayer(deleteCalendarPageComponent, {
                                        collectionId: model.collectionId,
                                        collectionDetails: CalendarManager.getCollectionDetails(model.collectionId),
                                    }, {
                                        width: Kirigami.Units.gridUnit * 30,
                                        height: Kirigami.Units.gridUnit * 6
                                    });

                                    if(!Kirigami.Settings.isMobile) {
                                        openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
                                    }
                                }
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
