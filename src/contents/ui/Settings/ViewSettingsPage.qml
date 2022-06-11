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
            Kirigami.FormData.label: i18n("General settings")
        }
        Controls.CheckBox {
            text: i18n("Show sub-tasks in calendar views")
            checked: Config.showSubtodosInCalendarViews
            enabled: !Config.isShowSubtodosInCalendarViewsImmutable
            onClicked: {
                Config.showSubtodosInCalendarViews = !Config.showSubtodosInCalendarViews;
                Config.save();
            }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Past event transparency:")
            Layout.fillWidth: true
            Controls.Slider {
                stepSize: 1.0
                from: 0.0
                to: 100.0
                value: Config.pastEventsTransparencyLevel * 100
                onMoved: {
                    Config.pastEventsTransparencyLevel = value / 100;
                    Config.save();
                }
            }
        }

        Kirigami.Separator {
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
                text: i18n("Left")
                enabled: !Config.isWeekdayLabelAlignmentImmutable
                checked: Config.weekdayLabelAlignment === value
            }
            Controls.RadioButton {
                property int value: Config.Center
                text: i18n("Center")
                enabled: !Config.isWeekdayLabelAlignmentImmutable
                checked: Config.weekdayLabelAlignment === value
            }
            Controls.RadioButton {
                property int value: Config.Right
                text: i18n("Right")
                enabled: !Config.isWeekdayLabelAlignmentImmutable
                checked: Config.weekdayLabelAlignment === value
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
                text: i18n("Full name (Monday)")
                enabled: !Config.isWeekdayLabelLengthImmutable
                checked: Config.weekdayLabelLength === value
            }
            Controls.RadioButton {
                property int value: Config.Abbreviated
                text: i18n("Abbreviated (Mon)")
                enabled: !Config.isWeekdayLabelLengthImmutable
                checked: Config.weekdayLabelLength === value
            }
            Controls.RadioButton {
                property int value: Config.Letter
                text: i18n("Letter only (M)")
                enabled: !Config.isWeekdayLabelLengthImmutable
                checked: Config.weekdayLabelLength === value
            }
        }
        Controls.CheckBox {
            text: i18n("Show week numbers")
            checked: Config.showWeekNumbers
            enabled: !Config.isShowWeekNumbersImmutable
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
                value: Config.monthGridBorderWidth
                onValueModified: {
                    Config.monthGridBorderWidth = value;
                    Config.save();
                }
                from: 0
                to: 50
            }
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: Kirigami.Units.gridUnit * 4
                implicitHeight: height
                height: Config.monthGridBorderWidth
                color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.15)
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Week View settings")
        }
        GridLayout {
            id: recurWeekdayRuleLayout
            Layout.fillWidth: true

            columns: 7

            Repeater {
                model: 7
                delegate: Controls.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName(Qt.locale().firstDayOfWeek + index, Locale.ShortFormat)
                }
            }

            Controls.CheckBox {
                checked: Config.showDay1
                onClicked: {
                    Config.showDay1 = !Config.showDay1;
                    Config.save();
                }
            }
            Controls.CheckBox {
                checked: Config.showDay2
                onClicked: {
                    Config.showDay2 = !Config.showDay2;
                    Config.save();
                }
            }
            Controls.CheckBox {
                checked: Config.showDay3
                onClicked: {
                    Config.showDay3 = !Config.showDay3;
                    Config.save();
                }
            }
            Controls.CheckBox {
                checked: Config.showDay4
                onClicked: {
                    Config.showDay4 = !Config.showDay4;
                    Config.save();
                }
            }
            Controls.CheckBox {
                checked: Config.showDay5
                onClicked: {
                    Config.showDay5 = !Config.showDay5;
                    Config.save();
                }
            }
            Controls.CheckBox {
                checked: Config.showDay6
                onClicked: {
                    Config.showDay6 = !Config.showDay6;
                    Config.save();
                }
            }
            Controls.CheckBox {
                checked: Config.showDay7
                onClicked: {
                    Config.showDay7 = !Config.showDay7;
                    Config.save();
                }
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
                text: i18n("Show week headers")
                checked: Config.showWeekHeaders
                enabled: !Config.isShowWeekHeadersImmutable
                onClicked: {
                    Config.showWeekHeaders = !Config.showWeekHeaders;
                    Config.save();
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Tasks View settings")
        }
        Controls.CheckBox {
            text: i18n("Show completed sub-tasks")
            checked: Config.showCompletedSubtodos
            enabled: !Config.isShowCompletedSubtodosImmutable
            onClicked: {
                Config.showCompletedSubtodos = !Config.showCompletedSubtodos;
                Config.save();
            }
        }
    }
}
