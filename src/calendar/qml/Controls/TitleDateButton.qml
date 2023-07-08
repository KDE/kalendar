// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.0 as QQC2
import QtQuick.Layouts 1.7
import org.kde.kirigami 2.12 as Kirigami
import org.kde.kalendar.calendar 1.0 as Calendar

QQC2.ToolButton {
    id: root
    implicitHeight: titleText.implicitHeight
    implicitWidth: titleText.implicitWidth

    property bool range: false
    property date lastDate
    readonly property date date: Calendar.DateTimeState.firstDayOfMonth

    contentItem: Kirigami.Heading {
        id: titleText
        topPadding: Kirigami.Units.smallSpacing
        bottomPadding: Kirigami.Units.smallSpacing
        leftPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
        rightPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing

        horizontalAlignment: Text.AlignHCenter
        text: {
            const locale = Qt.locale();
            const monthYearString = i18nc("%1 is month name, %2 is year", "<b>%1</b> %2", locale.standaloneMonthName(root.date.getMonth()), String(root.date.getFullYear()));

            if(!root.range) {
                return monthYearString;
            } else {
                const endRangeMonthYearString = i18nc("%1 is month name, %2 is year", "<b>%1</b> %2", locale.standaloneMonthName(root.lastDate.getMonth()), String(root.lastDate.getFullYear()));

                if(root.date.getFullYear() !== root.lastDate.getFullYear()) {
                    return i18nc("%1 is the month and year of the range start, %2 is the same for range end", "%1 - %2", monthYearString, endRangeMonthYearString);
                } else if(root.date.getMonth() !== root.lastDate.getMonth()) {
                    return i18nc("%1 is month of range start, %2 is month + year of range end", "<b>%1</b> - %2", locale.standaloneMonthName(root.date.getMonth()), endRangeMonthYearString);
                } else {
                    return monthYearString;
                }
            }
        }
    }
}
