// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.19 as Kirigami
import QtQuick.Layouts 1.15
import org.kde.kalendar 1.0
import org.kde.akonadi 1.0

Kirigami.ScrollablePage {
    id: sourcesSettingsPage
    title: i18n("Accounts")

    ColumnLayout {
        AgentConfigurationForm {
            mimetypes: [MimeTypes.calendar, MimeTypes.todo]
            title: i18n("Calendars")
            addPageTitle: i18n("Add New Calendar Source…")
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
        }

        AgentConfigurationForm {
            mimetypes: [MimeTypes.contactGroup, MimeTypes.address]
            title: i18n("Contact Books")
            addPageTitle: i18n("Add New Address Book Source…")
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
        }

        // TODO actually we should show identity instead as an identity contains a receiving and sending account
        AgentConfigurationForm {
            visible: Config.enableMailIntegration
            mimetypes: [MimeTypes.mail]
            title: i18n("Mail Accounts")
            addPageTitle: i18n("Add New mail account…")
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
        }
    }
}
