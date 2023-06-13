// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.18 as Kirigami
import QtQuick.Layouts 1.15
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm
import org.kde.akonadi 1.0 as Akonadi

Kirigami.ScrollablePage {
    id: root

    title: i18nc("@title:window", "Settings")

    leftPadding: 0
    rightPadding: 0

    ColumnLayout {
        Akonadi.AgentConfigurationForm {
            mimetypes: [Akonadi.MimeTypes.contactGroup, Akonadi.MimeTypes.address]
            title: i18n("Contact Books")
            addPageTitle: i18n("Add New Address Book Source…")
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
        }
    }
}
