// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar.calendar 1.0 as Kalendar

DayGridView {
    id: dayView

    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 40
    readonly property bool isTiny: width < Kirigami.Units.gridUnit * 18

    objectName: "monthView"

    dayHeaderDelegate: QQC2.Control {
        Layout.maximumHeight: Kirigami.Units.gridUnit * 2
        contentItem: Kirigami.Heading {
            text: {
                const longText = day.toLocaleString(Qt.locale(), "dddd");
                const midText = day.toLocaleString(Qt.locale(), "ddd");
                const shortText = midText.slice(0,1);
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
        text: Kalendar.Utils.weekNumber(startDate)
        background: Rectangle {
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            color: Kirigami.Theme.backgroundColor
        }
    }
}
