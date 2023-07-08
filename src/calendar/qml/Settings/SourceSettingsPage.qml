// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.19 as Kirigami
import QtQuick.Layouts 1.15
import org.kde.kalendar.calendar 1.0
import org.kde.akonadi 1.0

Kirigami.ScrollablePage {
    id: sourcesSettingsPage
    title: i18n("Accounts")
    leftPadding: 0
    rightPadding: 0

    ColumnLayout {
        AgentConfigurationForm {
            mimetypes: [MimeTypes.calendar, MimeTypes.todo]
            title: i18n("Calendars")
            addPageTitle: i18n("Add New Calendar Source…")
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
        }
    }
}
