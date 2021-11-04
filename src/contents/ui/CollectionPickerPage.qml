// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0

import org.kde.kalendar 1.0 as Kalendar

Kirigami.ScrollablePage {
    id: collectionPickerSheet
    title: todoMode ? i18n("Choose a Task Calendar") : i18n("Choose a Calendar")

    signal collectionPicked(int collectionId)

    property bool todoMode: false;

    ListView {
        id: collectionsList
        implicitWidth: Kirigami.Units.gridUnit * 30
        currentIndex: -1
        header: ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
        }

        model: KDescendantsProxyModel {
            model: collectionPickerSheet.todoMode ? Kalendar.CalendarManager.selectableTodoCalendars : Kalendar.CalendarManager.selectableCalendars
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
                    label: display
                    labelItem.color: Kirigami.Theme.textColor

                    hoverEnabled: false

                    separatorVisible: false

                    onClicked: collectionPickerSheet.collectionPicked(collectionId);

                    trailing: Rectangle {
                        color: model.collectionColor
                        radius: Kirigami.Units.smallSpacing
                        width: height
                        height: Kirigami.Units.iconSizes.small
                    }
                }
            }
        }
    }
}
