// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar

import "dateutils.js" as DateUtils

DayGridView {
    id: dayView

    signal viewDatesChanged(date startDate, date firstDayOfMonth, int month, int year)

    property bool isLarge: true
    property bool isTiny: false

    function setToDate(date) {
        foregroundLoader.active = false;

        month = date.getMonth();
        year = date.getFullYear();
        let firstDayOfMonth = new Date(year, month, 1);
        let newDate = DateUtils.getFirstDayOfWeek(firstDayOfMonth)

        // Handling adding and subtracting months in Javascript can get *really* messy.
        newDate = DateUtils.addDaysToDate(newDate, 7)

        if (newDate.getMonth() === month) {
            newDate = DateUtils.addDaysToDate(newDate, - 7)
        }
        if (newDate.getDate() < 14) {
            newDate = DateUtils.addDaysToDate(newDate, - 7)
        }

        startDate = newDate;
        viewDatesChanged(startDate, firstDayOfMonth, month, year);

        foregroundLoader.active = true;
    }

    objectName: "monthView"

    dayHeaderDelegate: QQC2.Control {
        Layout.maximumHeight: Kirigami.Units.gridUnit * 2
        contentItem: Kirigami.Heading {
            text: {
                let longText = day.toLocaleString(Qt.locale(), "dddd");
                let midText = day.toLocaleString(Qt.locale(), "ddd");
                let shortText = midText.slice(0,1);
                switch(Kalendar.Config.weekdayLabelLength) {
                    case Kalendar.Config.Full:
                        let chosenFormat = "dddd"
                        return dayView.isLarge ? longText : dayView.isTiny ? shortText : midText;
                    case Kalendar.Config.Abbreviated:
                        return dayView.isTiny ? shortText : midText;
                    case Kalendar.Config.Letter:
                    default:
                        return shortText;
                }
            }
            level: 2
            leftPadding: Kirigami.Units.smallSpacing
            rightPadding: Kirigami.Units.smallSpacing
            horizontalAlignment: {
                switch(Kalendar.Config.weekdayLabelAlignment) {
                    case Kalendar.Config.Left:
                        return Text.AlignLeft;
                    case Kalendar.Config.Center:
                        return Text.AlignHCenter;
                    case Kalendar.Config.Right:
                        return Text.AlignRight;
                    default:
                        return Text.AlignHCenter;
                }
            }
        }
    }

    weekHeaderDelegate: QQC2.Label {
        padding: Kirigami.Units.smallSpacing
        verticalAlignment: Qt.AlignTop
        horizontalAlignment: Qt.AlignHCenter
        text: DateUtils.getWeek(startDate, Qt.locale().firstDayOfWeek)
        background: Rectangle {
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            color: Kirigami.Theme.backgroundColor
        }
    }
}

