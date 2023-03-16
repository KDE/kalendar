// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.15 as Kirigami

QQC2.ComboBox {
    id: root

    required property bool isTodo

    visible: incidenceForm.isTodo
    textRole: "display"
    valueRole: "value"

    Kirigami.FormData.label: i18n("Priority:")

    model: [
        {display: i18n("Unassigned"), value: 0},
        {display: i18n("1 (Highest Priority)"), value: 1},
        {display: i18n("2"), value: 2},
        {display: i18n("3"), value: 3},
        {display: i18n("4"), value: 4},
        {display: i18n("5 (Medium Priority)"), value: 5},
        {display: i18n("6"), value: 6},
        {display: i18n("7"), value: 7},
        {display: i18n("8"), value: 8},
        {display: i18n("9 (Lowest Priority)"), value: 9}
    ]
}
