// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar
import org.kde.akoandi 1.0 as Akonadi
import QtQuick.Controls 2.15 as QQC2

QQC2.Dialog {
    standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel

    header: Kirigami.Heading {
        text: i18nc("@title:window", "Select Date")
    }

    contentItem: ColumnLayout {
        Kalendar.DatePicker {
        }

        Akonadi.CollectionComboBox {}
    }

}
