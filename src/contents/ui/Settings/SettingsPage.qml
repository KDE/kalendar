// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.18 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kalendar 1.0

Kirigami.CategorizedSettings {
    objectName: "settingsPage"
    actions: [
        Kirigami.SettingAction {
            actionName: "appearance"
            text: i18n("Appearance")
            icon.name: "preferences-desktop-theme-global"
            page: Qt.resolvedUrl("ViewSettingsPage.qml")
        },
        Kirigami.SettingAction {
            actionName: "accounts"
            text: i18n("Accounts")
            icon.name: "preferences-system-users"
            page: Qt.resolvedUrl("SourceSettingsPage.qml")
        },
        Kirigami.SettingAction {
            actionName: "calendars"
            text: i18n("Calendars")
            icon.name: "korganizer"
            page: Qt.resolvedUrl("CalendarSettingsPage.qml")
        },
        Kirigami.SettingAction {
            actionName: "about"
            text: i18n("About Kalendar")
            icon.name: "help-about"
            page: Qt.resolvedUrl("AboutPage.qml")
        }
    ]
}
