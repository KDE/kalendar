// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami

Item {
    id: datepicker

    signal datePicked(date pickedDate)

    property date selectedDate: new Date() // Decides calendar span
    property date clickedDate: new Date() // User's chosen date
    property date today: new Date()
    property int year: selectedDate.getFullYear()
    property int month: selectedDate.getMonth()
    property int firstDay: new Date(year, month, 1).getDay() // 0 Sunday to 6 Saturday

    function prevMonth() {
        selectedDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth() - 1, selectedDate.getDate())
    }

    function nextMonth() {
        selectedDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth() + 1, selectedDate.getDate())
    }

    function prevYear() {
        selectedDate = new Date(selectedDate.getFullYear() - 1, selectedDate.getMonth(), selectedDate.getDate())
    }

    function nextYear() {
        selectedDate = new Date(selectedDate.getFullYear() + 1, selectedDate.getMonth(), selectedDate.getDate())
    }

    function prevDecade() {
        selectedDate = new Date(selectedDate.getFullYear() - 10, selectedDate.getMonth(), selectedDate.getDate())
    }

    function nextDecade() {
        selectedDate = new Date(selectedDate.getFullYear() + 10, selectedDate.getMonth(), selectedDate.getDate())
    }

    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            id: headingRow
            Layout.fillWidth: true

            Kirigami.Heading {
                id: monthLabel
                Layout.fillWidth: true
                text: selectedDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                level: 1
            }
            QQC2.ToolButton {
                icon.name: 'go-previous-view'
                onClicked: {
                    if (pickerView.currentIndex == 1) { // monthGrid index
                        prevYear()
                    } else if (pickerView.currentIndex == 2) { // yearGrid index
                        prevDecade()
                    } else { // dayGrid index
                        prevMonth()
                    }
                }
            }
            QQC2.ToolButton {
                icon.name: 'go-jump-today'
                onClicked: selectedDate = new Date()
            }
            QQC2.ToolButton {
                icon.name: 'go-next-view'
                onClicked: {
                    if (pickerView.currentIndex == 1) { // monthGrid index
                        nextYear()
                    } else if (pickerView.currentIndex == 2) { // yearGrid index
                        nextDecade()
                    } else { // dayGrid index
                        nextMonth()
                    }
                }
            }
        }

        QQC2.TabBar {
            id: rangeBar
            currentIndex: pickerView.currentIndex
            Layout.fillWidth: true

            QQC2.TabButton {
                id: daysViewCheck
                Layout.fillWidth: true
                text: i18n("Days")
                onClicked: pickerView.currentIndex = 0 // dayGrid is first item in pickerView
            }
            QQC2.TabButton {
                id: monthsViewCheck
                Layout.fillWidth: true
                text: i18n("Months")
                onClicked: pickerView.currentIndex = 1
            }
            QQC2.TabButton {
                id: yearsViewCheck
                Layout.fillWidth: true
                text: i18n("Years")
                onClicked: pickerView.currentIndex = 2
            }
        }

        QQC2.SwipeView {
            id: pickerView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            QQC2.ButtonGroup {
                buttons: dayGrid.children
            }
            GridLayout {
                id: dayGrid
                columns: 7
                rows: 6
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Kirigami.Units.smallSpacing

                Repeater {
                    model: 7
                    delegate: QQC2.Label {
                        Layout.fillWidth: true
                        height: dayGrid / dayGrid.rows
                        horizontalAlignment: Text.AlignHCenter
                        opacity: 0.7
                        text: Qt.locale().dayName(index + Qt.locale().firstDayOfWeek, Locale.ShortFormat) // dayName() loops back over beyond index 6
                    }
                }

                Repeater {
                    model: dayGrid.columns * dayGrid.rows // 42 cells per month

                    delegate: QQC2.Button {
                        // Stop days overflowing from the grid by creating an adjusted offset
                        property int firstDayOfWeekOffset: Qt.locale().firstDayOfWeek >= 4 ?
                                                           Qt.locale().firstDayOfWeek - 7 + 1 :
                                                           Qt.locale().firstDayOfWeek + 1
                        // add locale offset for correct firstDayOfWeek
                        property int dateToUse: index + firstDayOfWeekOffset - (datepicker.firstDay <= 1 ?
                                                                                datepicker.firstDay + 7:
                                                                                datepicker.firstDay)
                        property date date: new Date(datepicker.year, datepicker.month, dateToUse)
                        property bool sameMonth: date.getMonth() === month
                        property bool isToday: date.getDate() === datepicker.today.getDate() &&
                            date.getMonth() === datepicker.today.getMonth() &&
                            date.getFullYear() === datepicker.today.getFullYear()

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        flat: true
                        highlighted: this.isToday
                        checkable: true
                        checked: date.getDate() === clickedDate.getDate() &&
                            date.getMonth() === clickedDate.getMonth() &&
                            date.getFullYear() === clickedDate.getFullYear()
                        opacity: sameMonth ? 1 : 0.7
                        text: date.getDate()
                        onClicked: datePicked(date), clickedDate = date
                    }
                }
            }

            GridLayout {
                id: monthGrid
                columns: 3
                rows: 4
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Kirigami.Units.smallSpacing

                Repeater {
                    model: monthGrid.columns * monthGrid.rows
                    delegate: QQC2.Button {
                        property int monthToUse: index
                        property date date: new Date(year, monthToUse)
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        flat: true
                        text: Qt.locale().monthName(date.getMonth())
                        onClicked: selectedDate = new Date(date), pickerView.currentIndex = 0
                    }
                }
            }

            GridLayout {
                id: yearGrid
                columns: 3
                rows: 4
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Kirigami.Units.smallSpacing

                Repeater {
                    model: yearGrid.columns * yearGrid.rows
                    delegate: QQC2.Button {
                        property int yearToUse: index - 1 + (Math.floor(year/10)*10) // Display a decade, e.g. 2019 - 2030
                        property date date: new Date(yearToUse, 0)
                        property bool sameDecade: Math.floor(yearToUse / 10) == Math.floor(year / 10)
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        flat: true
                        opacity: sameDecade ? 1 : 0.7
                        text: date.getFullYear()
                        onClicked: selectedDate = new Date(date), pickerView.currentIndex = 1
                    }
                }
            }
        }
    }
}



