// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later
import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kalendar 1.0

Kirigami.ScrollablePage {
    title: i18n("Views")

    Kirigami.FormLayout {
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Month View settings")
        }
        Controls.ButtonGroup {
            buttons: weekdayLabelAlignmentButtonColumn.children
            exclusive: true

            onClicked: {
                Config.weekdayLabelAlignment = button.value;
                Config.save();
            }
        }
        Column {
            id: weekdayLabelAlignmentButtonColumn
            Kirigami.FormData.label: i18n("Weekday label alignment:")
            Kirigami.FormData.labelAlignment: Qt.AlignTop

            Controls.RadioButton {
                property int value: Config.Left

                checked: Config.weekdayLabelAlignment === value
                enabled: !Config.isWeekdayLabelAlignmentImmutable
                text: i18n("Left")
            }
            Controls.RadioButton {
                property int value: Config.Center

                checked: Config.weekdayLabelAlignment === value
                enabled: !Config.isWeekdayLabelAlignmentImmutable
                text: i18n("Center")
            }
            Controls.RadioButton {
                property int value: Config.Right

                checked: Config.weekdayLabelAlignment === value
                enabled: !Config.isWeekdayLabelAlignmentImmutable
                text: i18n("Right")
            }
        }
        Controls.ButtonGroup {
            buttons: weekdayLabelLengthButtonColumn.children
            exclusive: true

            onClicked: {
                Config.weekdayLabelLength = button.value;
                Config.save();
            }
        }
        Column {
            id: weekdayLabelLengthButtonColumn
            Kirigami.FormData.label: i18n("Weekday label length:")
            Kirigami.FormData.labelAlignment: Qt.AlignTop

            Controls.RadioButton {
                property int value: Config.Full

                checked: Config.weekdayLabelLength === value
                enabled: !Config.isWeekdayLabelLengthImmutable
                text: i18n("Full name (Monday)")
            }
            Controls.RadioButton {
                property int value: Config.Abbreviated

                checked: Config.weekdayLabelLength === value
                enabled: !Config.isWeekdayLabelLengthImmutable
                text: i18n("Abbreviated (Mon)")
            }
            Controls.RadioButton {
                property int value: Config.Letter

                checked: Config.weekdayLabelLength === value
                enabled: !Config.isWeekdayLabelLengthImmutable
                text: i18n("Letter only (M)")
            }
        }
        Controls.CheckBox {
            checked: Config.showWeekNumbers
            enabled: !Config.isShowWeekNumbersImmutable
            text: i18n("Show week numbers")

            onClicked: {
                Config.showWeekNumbers = !Config.showWeekNumbers;
                Config.save();
            }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Grid border width (pixels):")
            Layout.fillWidth: true

            Controls.SpinBox {
                Layout.fillWidth: true
                from: 0
                to: 50
                value: Config.monthGridBorderWidth

                onValueModified: {
                    Config.monthGridBorderWidth = value;
                    Config.save();
                }
            }
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.15)
                height: Config.monthGridBorderWidth
                implicitHeight: height
                width: Kirigami.Units.gridUnit * 4
            }
        }
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Schedule View settings")
        }
        Column {
            Kirigami.FormData.label: i18n("Headers:")
            Kirigami.FormData.labelAlignment: Qt.AlignTop

            Controls.CheckBox {
                checked: Config.showMonthHeader
                enabled: !Config.isShowMonthHeaderImmutable
                text: i18n("Show month header")

                onClicked: {
                    Config.showMonthHeader = !Config.showMonthHeader;
                    Config.save();
                }
            }
            Controls.CheckBox {
                checked: Config.showWeekHeaders
                enabled: !Config.isShowWeekHeadersImmutable
                text: i18n("Show week headers")

                onClicked: {
                    Config.showWeekHeaders = !Config.showWeekHeaders;
                    Config.save();
                }
            }
        }
    }
}
