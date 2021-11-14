// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami

Item {
    id: timePicker

    signal done()
    signal timeChanged(int hours, int minutes, int seconds)
    signal minuteMultiplesAboutToChange(int minuteMultiples)

    anchors.fill: parent

    property int hours
    property int minutes
    property int seconds

    property int minuteMultiples: 5
    property bool secondsPicker: false

    onMinutesChanged: {
        if (minutes % minuteMultiples !== 0) {
            minuteMultiplesAboutToChange(minuteMultiples);
            minuteMultiples = 1;
        }
    }

    function wheelHandler(parent, wheel) {
        if(parent.currentIndex == parent.count - 1) {
            wheel.angleDelta.y < 0 ? parent.currentIndex = 0 : parent.currentIndex -= 1;
        } else if(parent.currentIndex == 0) {
            wheel.angleDelta.y < 0 ? parent.currentIndex += 1 : parent.currentIndex = parent.count - 1;
        } else {
            wheel.angleDelta.y < 0 ? parent.currentIndex += 1 : parent.currentIndex -= 1;
        }
    }

    GridLayout {
        anchors.fill: parent
        columns: timePicker.secondsPicker ? 5 : 3
        rows: 4

        RowLayout {
            Layout.row: 0
            Layout.column: 0
            Layout.columnSpan: timePicker.secondsPicker ? 5 : 3
            QQC2.Label {
                text: i18n("Min. Interval:")
            }
            QQC2.SpinBox {
                Layout.fillWidth: true
                from: 1
                value: minuteMultiples
                onValueChanged: {
                    minuteMultiplesAboutToChange(minuteMultiples);
                    minuteMultiples = value;
                }
            }
        }

        QQC2.ToolButton {
            Layout.fillWidth: true
            Layout.row: 1
            Layout.column: 0
            icon.name: "go-up"
            enabled: hourView.currentIndex != 0
            onClicked: hourView.currentIndex -= 1
        }
        QQC2.ToolButton {
            Layout.fillWidth: true
            Layout.row: 1
            Layout.column: 2
            icon.name: "go-up"
            enabled: minuteView.currentIndex != 0
            onClicked: minuteView.currentIndex -= 1
        }
        QQC2.ToolButton {
            Layout.fillWidth: true
            Layout.row: 1
            Layout.column: 4
            icon.name: "go-up"
            enabled: secondsView.currentIndex != 0
            onClicked: secondsView.currentIndex -= 1
            visible: timePicker.secondsPicker
        }

        QQC2.Tumbler {
            id: hourView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.row: 2
            Layout.column: 0
            wrap: true

            model: 24
            currentIndex: timePicker.hours
            onCurrentIndexChanged: timePicker.hours = currentIndex

            delegate: Kirigami.Heading {
                property int thisIndex: index

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: hourView.currentIndex == thisIndex ? 1 : 0.7
                font.bold: hourView.currentIndex == thisIndex
                text: modelData < 10 ? String(modelData).padStart(2, "0") : modelData
            }

            MouseArea {
                anchors.fill: parent
                onWheel: timePicker.wheelHandler(parent, wheel)
            }
        }

        Kirigami.Heading {
            Layout.row: 2
            Layout.column: 1
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: ":"
        }

        QQC2.Tumbler {
            id: minuteView
            Layout.fillWidth: true
            Layout.fillHeight: true
            wrap: true

            property int selectedIndex: 0

            // We don't want our selected time to get reset when we update minuteMultiples, on which the model depends
            Connections { // Gets called before model regen
                target: timePicker
                onMinuteMultiplesAboutToChange: minuteView.selectedIndex = minuteView.currentIndex * timePicker.minuteMultiples
                onMinutesChanged: minuteView.currentIndex = minutes / timePicker.minuteMultiples
            }
            onModelChanged: currentIndex = selectedIndex / timePicker.minuteMultiples
            currentIndex: timePicker.minutes
            onCurrentIndexChanged: timePicker.minutes = currentIndex * timePicker.minuteMultiples

            model: (60 / timePicker.minuteMultiples) // So we can adjust the minute intervals selectable by the user (model goes up to 59)
            delegate: Kirigami.Heading {
                property int thisIndex: index
                property int minuteToDisplay: modelData * timePicker.minuteMultiples

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: minuteView.currentIndex == thisIndex ? 1 : 0.7
                font.bold: minuteView.currentIndex == thisIndex
                text: minuteToDisplay < 10 ? String(minuteToDisplay).padStart(2, "0") : minuteToDisplay
            }

            MouseArea {
                anchors.fill: parent
                onWheel: timePicker.wheelHandler(parent, wheel)
            }
        }


        Kirigami.Heading {
            Layout.row: 2
            Layout.column: 3
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            visible: timePicker.secondsPicker
            font.bold: true
            text: ":"
        }

        QQC2.Tumbler {
            id: secondsView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.row: 2
            Layout.column: 4
            visible: timePicker.secondsPicker
            model: 60

            currentIndex: timePicker.seconds
            onCurrentIndexChanged: timePicker.seconds = currentIndex

            delegate: Kirigami.Heading {
                property int thisIndex: index

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: secondsView.currentIndex == thisIndex ? 1 : 0.7
                font.bold: secondsView.currentIndex == thisIndex
                text: modelData < 10 ? String(modelData).padStart(2, "0") : modelData
            }

            MouseArea {
                anchors.fill: parent
                onWheel: timePicker.wheelHandler(parent, wheel)
            }
        }

        QQC2.ToolButton {
            Layout.fillWidth: true
            Layout.row: 3
            Layout.column: 0
            icon.name: "go-down"
            enabled: hourView.currentIndex < hourView.count - 1
            onClicked: hourView.currentIndex += 1
        }
        QQC2.ToolButton {
            Layout.fillWidth: true
            Layout.row: 3
            Layout.column: 2
            icon.name: "go-down"
            enabled: minuteView.currentIndex < minuteView.count - 1
            onClicked: minuteView.currentIndex += 1
        }
        QQC2.ToolButton {
            Layout.fillWidth: true
            Layout.row: 3
            Layout.column: 4
            icon.name: "go-down"
            enabled: secondsView.currentIndex < secondsView.count - 1
            onClicked: secondsView.currentIndex += 1
            visible: timePicker.secondsPicker
        }
    }
}

