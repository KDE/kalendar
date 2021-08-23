// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kalendar 1.0

Kirigami.Page {
    title: i18n("General")

    Kirigami.FormLayout {
        anchors.fill: parent
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Maps")
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Enable maps:")

            Controls.CheckBox {
                checked: Config.enableMaps
                enabled: !Config.isEnableMapsImmutable
                onClicked: {
                    Config.enableMaps = !Config.enableMaps;
                    Config.save();
                }
            }
            Controls.Label {
                font: Kirigami.Theme.smallFont
                text: i18n("May cause crashing on some systems.")
            }
        }
        Controls.ButtonGroup {
            buttons: locationMarkerButtonColumn.children
            exclusive: true
            onClicked: {
                Config.locationMarker = button.value;
                Config.save();
            }
        }
        Column {
            id: locationMarkerButtonColumn
            Kirigami.FormData.label: i18n("Location marker:")
            Kirigami.FormData.labelAlignment: Qt.AlignTop

            Controls.RadioButton {
                property int value: 0 // HACK: Ideally should use config enum
                text: i18n("Circle (shows area of location)")
                enabled: Config.enableMaps && !Config.isLocationMarkerImmutable
                checked: Config.locationMarker === value
            }
            Controls.RadioButton {
                property int value: 1 // HACK: Ideally should use config enum
                text: i18n("Pin (shows exact location)")
                enabled: Config.enableMaps && !Config.isLocationMarkerImmutable
                checked: Config.locationMarker === value
            }
        }
    }
}
