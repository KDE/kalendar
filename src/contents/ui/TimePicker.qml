// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later
import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import "dateutils.js" as DateUtils

Item {
    id: timePicker
    property date dateTime: new Date()
    property int hours: dateTime.getHours()
    property int minuteMultiples: 5
    property int minutes: dateTime.getMinutes()
    property int seconds: dateTime.getSeconds()
    property bool secondsPicker: false
    property int timeZoneOffset: 0

    anchors.fill: parent

    signal done
    signal minuteMultiplesAboutToChange(int minuteMultiples)
    function setToTimeFromString(timeString) {
        // Accepts in format HH:MM:SS
        var splitTimeString = timeString.split(":");
        switch (splitTimeString.length) {
        case 3:
            dateTime = new Date(dateTime.setHours(Number(splitTimeString[0]), Number(splitTimeString[1]), Number(splitTimeString[2])));
            break;
        case 2:
            dateTime = new Date(dateTime.setHours(Number(splitTimeString[0]), Number(splitTimeString[1])));
            break;
        case 1:
            dateTime = new Date(dateTime.setHours(Number(splitTimeString[0])));
            break;
        case 0:
            return;
        }
    }
    signal timeChanged(int hours, int minutes, int seconds)
    function wheelHandler(parent, wheel) {
        if (parent.currentIndex == parent.count - 1) {
            wheel.angleDelta.y < 0 ? parent.currentIndex = 0 : parent.currentIndex -= 1;
        } else if (parent.currentIndex == 0) {
            wheel.angleDelta.y < 0 ? parent.currentIndex += 1 : parent.currentIndex = parent.count - 1;
        } else {
            wheel.angleDelta.y < 0 ? parent.currentIndex += 1 : parent.currentIndex -= 1;
        }
    }

    onDateTimeChanged: {
        hourView.currentIndex = dateTime.getHours();
        minuteView.currentIndex = dateTime.getMinutes() / minuteMultiples;
        secondsView.currentIndex = dateTime.getSeconds();
    }
    onMinutesChanged: {
        if (minutes % minuteMultiples !== 0) {
            minuteMultiplesAboutToChange(minuteMultiples);
            minuteMultiples = 1;
        }
    }

    GridLayout {
        anchors.fill: parent
        columns: timePicker.secondsPicker ? 5 : 3
        rows: 5

        RowLayout {
            Layout.column: 0
            Layout.columnSpan: timePicker.secondsPicker ? 5 : 3
            Layout.row: 0

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
            Layout.column: 0
            Layout.fillWidth: true
            Layout.row: 1
            enabled: hourView.currentIndex != 0
            icon.name: "go-up"

            onClicked: hourView.currentIndex -= 1
        }
        QQC2.ToolButton {
            Layout.column: 2
            Layout.fillWidth: true
            Layout.row: 1
            enabled: minuteView.currentIndex != 0
            icon.name: "go-up"

            onClicked: minuteView.currentIndex -= 1
        }
        QQC2.ToolButton {
            Layout.column: 4
            Layout.fillWidth: true
            Layout.row: 1
            enabled: secondsView.currentIndex != 0
            icon.name: "go-up"
            visible: timePicker.secondsPicker

            onClicked: secondsView.currentIndex -= 1
        }
        QQC2.Tumbler {
            id: hourView
            Layout.column: 0
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.row: 2
            model: 24
            wrap: true

            onCurrentIndexChanged: timePicker.dateTime = new Date(timePicker.dateTime.setHours(currentIndex))

            MouseArea {
                anchors.fill: parent

                onWheel: timePicker.wheelHandler(parent, wheel)
            }

            delegate: Kirigami.Heading {
                property int thisIndex: index

                horizontalAlignment: Text.AlignHCenter
                opacity: hourView.currentIndex == thisIndex ? 1 : 0.7
                text: modelData < 10 ? String(modelData).padStart(2, "0") : modelData
                verticalAlignment: Text.AlignVCenter
            }
        }
        Kirigami.Heading {
            Layout.column: 1
            Layout.row: 2
            horizontalAlignment: Text.AlignHCenter
            text: ":"
            verticalAlignment: Text.AlignVCenter
        }
        QQC2.Tumbler {
            id: minuteView
            property int selectedIndex: 0

            Layout.fillHeight: true
            Layout.fillWidth: true
            model: (60 / timePicker.minuteMultiples) // So we can adjust the minute intervals selectable by the user (model goes up to 59)
            wrap: true

            onCurrentIndexChanged: timePicker.dateTime = new Date(timePicker.dateTime.setHours(timePicker.dateTime.getHours(), currentIndex * timePicker.minuteMultiples))
            onModelChanged: currentIndex = selectedIndex / timePicker.minuteMultiples

            // We don't want our selected time to get reset when we update minuteMultiples, on which the model depends
            Connections {
                // Gets called before model regen
                target: timePicker

                onMinuteMultiplesAboutToChange: minuteView.selectedIndex = minuteView.currentIndex * timePicker.minuteMultiples
            }
            MouseArea {
                anchors.fill: parent

                onWheel: timePicker.wheelHandler(parent, wheel)
            }

            delegate: Kirigami.Heading {
                property int minuteToDisplay: modelData * timePicker.minuteMultiples
                property int thisIndex: index

                horizontalAlignment: Text.AlignHCenter
                opacity: minuteView.currentIndex == thisIndex ? 1 : 0.7
                text: minuteToDisplay < 10 ? String(minuteToDisplay).padStart(2, "0") : minuteToDisplay
                verticalAlignment: Text.AlignVCenter
            }
        }
        Kirigami.Heading {
            Layout.column: 3
            Layout.row: 2
            horizontalAlignment: Text.AlignHCenter
            text: ":"
            verticalAlignment: Text.AlignVCenter
            visible: timePicker.secondsPicker
        }
        QQC2.Tumbler {
            id: secondsView
            Layout.column: 4
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.row: 2
            model: 60
            visible: timePicker.secondsPicker

            onCurrentIndexChanged: timePicker.dateTime = new Date(timePicker.dateTime.setHours(timePicker.dateTime.getHours(), timePicker.dateTime.getMinutes(), currentIndex))

            MouseArea {
                anchors.fill: parent

                onWheel: timePicker.wheelHandler(parent, wheel)
            }

            delegate: Kirigami.Heading {
                property int thisIndex: index

                horizontalAlignment: Text.AlignHCenter
                opacity: secondsView.currentIndex == thisIndex ? 1 : 0.7
                text: modelData < 10 ? String(modelData).padStart(2, "0") : modelData
                verticalAlignment: Text.AlignVCenter
            }
        }
        QQC2.ToolButton {
            Layout.column: 0
            Layout.fillWidth: true
            Layout.row: 3
            enabled: hourView.currentIndex < hourView.count - 1
            icon.name: "go-down"

            onClicked: hourView.currentIndex += 1
        }
        QQC2.ToolButton {
            Layout.column: 2
            Layout.fillWidth: true
            Layout.row: 3
            enabled: minuteView.currentIndex < minuteView.count - 1
            icon.name: "go-down"

            onClicked: minuteView.currentIndex += 1
        }
        QQC2.ToolButton {
            Layout.column: 4
            Layout.fillWidth: true
            Layout.row: 3
            enabled: secondsView.currentIndex < secondsView.count - 1
            icon.name: "go-down"
            visible: timePicker.secondsPicker

            onClicked: secondsView.currentIndex += 1
        }
        QQC2.Button {
            Layout.columnSpan: timePicker.secondsPicker ? 5 : 3
            Layout.fillWidth: true
            Layout.row: 4
            text: i18n("Done")

            onClicked: done()
        }
    }
}
