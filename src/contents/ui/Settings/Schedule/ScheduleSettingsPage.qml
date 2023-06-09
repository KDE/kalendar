// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.18 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kalendar 1.0

Kirigami.CategorizedSettings {
    objectName: "settingsPage"
    actions: [
        Kirigami.SettingAction {
            text: i18n("Free/Busy")
            icon.name: "view-calendar-month"
            page: Qt.resolvedUrl("FreeBusySettingsPage.qml")
        }
        //  TODO: add Availability configuration here
    ]
}
