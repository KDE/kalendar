// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0
import org.kde.akonadi 1.0 as Akonadi

import org.kde.kalendar.calendar 1.0 as Kalendar

Kirigami.ScrollablePage {
    id: collectionPickerSheet
    title: switch (mode) {
    case Kalendar.CalendarApplication.Todo:
        return i18n("Choose a Task Calendar");
    case Kalendar.CalendarApplication.Event:
        return i18n("Choose a Calendar");
    case Kalendar.CalendarApplication.Contact:
        return i18n("Choose an Address Book");
    default:
        return 'BUG';
    }

    signal cancel
    signal collectionPicked(int collectionId)

    property int mode: Kalendar.CalendarApplication.Event

    ListView {
        id: collectionsList
        implicitWidth: Kirigami.Units.gridUnit * 30
        currentIndex: -1
        header: ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
        }

        model: KDescendantsProxyModel {
            model: Akonadi.CollectionPickerModel {
                id: collectionPickerModel
                mimeTypeFilter: switch (collectionPickerSheet.mode) {
                case Kalendar.CalendarApplication.Todo:
                    return [Akonadi.MimeTypes.todo];
                case Kalendar.CalendarApplication.Event:
                    return [Akonadi.MimeTypes.calendar];
                case Kalendar.CalendarApplication.Contact:
                    return [Akonadi.MimeTypes.address, Akonadi.MimeTypes.contactGroup];
                }
                excludeVirtualCollections: true

                accessRightsFilter: Akonadi.Collection.CanCreateItem
            }
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

                    onClicked: collectionPickerSheet.collectionPicked(collectionId);

                    trailing: Rectangle {
                        anchors.margins: Kirigami.Units.smallSpacing
                        color: model.collectionColor
                        radius: width * 0.5
                        width: height
                        height: Kirigami.Units.iconSizes.small
                    }
                }
            }
        }
    }

    footer: QQC2.DialogButtonBox {
        standardButtons: QQC2.DialogButtonBox.Cancel

        onRejected: cancel()
    }
}
