// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import "dateutils.js" as DateUtils

Item {
    id: timePicker

    signal done()
    signal timeChanged(int hours, int minutes, int seconds)
    signal minuteMultiplesAboutToChange(int minuteMultiples)

    anchors.fill: parent

    property int timeZoneOffset: 0
    property date dateTime: new Date()

    property int hours: dateTime.getHours()
    property int minutes: dateTime.getMinutes()
    property int seconds: dateTime.getSeconds()

    property int minuteMultiples: 5
    property bool secondsPicker: false

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

    function setToTimeFromString(timeString) { // Accepts in format HH:MM:SS
        var splitTimeString = timeString.split(":");
        switch (splitTimeString.length) {
            case 3:
                dateTime = new Date (dateTime.setHours(Number(splitTimeString[0]),
                                                       Number(splitTimeString[1]),
                                                       Number(splitTimeString[2])));
                break;
            case 2:
                dateTime = new Date (dateTime.setHours(Number(splitTimeString[0]),
                                                       Number(splitTimeString[1])));
                break;
            case 1:
                dateTime = new Date (dateTime.setHours(Number(splitTimeString[0])));
                break;
            case 0:
                return;
        }
    }

    GridLayout {
        anchors.fill: parent
        columns: timePicker.secondsPicker ? 5 : 3
        rows: 5

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
            Layout.row: 2
            Layout.column: 0

            model: 24

            onCurrentIndexChanged: timePicker.dateTime = new Date (timePicker.dateTime.setHours(currentIndex))

            delegate: Kirigami.Heading {
                property int thisIndex: index

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: hourView.currentIndex == thisIndex ? 1 : 0.7
                text: modelData < 10 ? String(modelData).padStart(2, "0") : modelData
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
            wrap: true

            property int selectedIndex: 0

            // We don't want our selected time to get reset when we update minuteMultiples, on which the model depends
            Connections { // Gets called before model regen
                target: timePicker
                onMinuteMultiplesAboutToChange: minuteView.selectedIndex = minuteView.currentIndex * timePicker.minuteMultiples
            }
            onModelChanged: currentIndex = selectedIndex / timePicker.minuteMultiples
            onCurrentIndexChanged: timePicker.dateTime = new Date (timePicker.dateTime.setHours(timePicker.dateTime.getHours(),
                                                                                                currentIndex * timePicker.minuteMultiples))

            model: (60 / timePicker.minuteMultiples) // So we can adjust the minute intervals selectable by the user (model goes up to 59)
            delegate: Kirigami.Heading {
                property int thisIndex: index
                property int minuteToDisplay: modelData * timePicker.minuteMultiples

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: minuteView.currentIndex == thisIndex ? 1 : 0.7
                text: minuteToDisplay < 10 ? String(minuteToDisplay).padStart(2, "0") : minuteToDisplay
            }
        }


        Kirigami.Heading {
            Layout.row: 2
            Layout.column: 3
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            visible: timePicker.secondsPicker
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

            onCurrentIndexChanged: timePicker.dateTime = new Date (timePicker.dateTime.setHours(timePicker.dateTime.getHours(),
                                                                                                timePicker.dateTime.getMinutes(),
                                                                                                currentIndex))

            delegate: Kirigami.Heading {
                property int thisIndex: index

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: secondsView.currentIndex == thisIndex ? 1 : 0.7
                text: modelData < 10 ? String(modelData).padStart(2, "0") : modelData
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

        QQC2.Button {
            Layout.row: 4
            Layout.columnSpan: timePicker.secondsPicker ? 5 : 3
            Layout.fillWidth: true
            text: i18n("Done")
            onClicked: done()
        }
    }
}

