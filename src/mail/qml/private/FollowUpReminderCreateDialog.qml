// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar
import org.kde.akonadi 1.0 as Akonadi
import QtQuick.Controls 2.15 as QQC2
import "qrc:/"

Kirigami.ScrollablePage {
    id: root

    property date date: new Date()

    title: i18nc("@title:window", "Create follow up reminder")

    ColumnLayout {
        Kirigami.FormLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            DateCombo {
                Layout.fillWidth: true
                Kirigami.FormData.label: i18n('Date:')
                dateTime: root.date
                onNewDateChosen: todo(day, month, year)
            }

            Akonadi.CollectionComboBox {
                Layout.fillWidth: true
                Kirigami.FormData.label: i18n('Store task in:')
                defaultCollectionId: Kalendar.Config.lastUsedTodoCollection
                mimeTypeFilter: [Akonadi.MimeTypes.calendar, Akonadi.MimeTypes.todo]
                accessRightsFilter: Akonadi.Collection.CanCreateItem
            }
        }
    }

    footer: QQC2.DialogButtonBox {
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
    }
}
