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

    property int hours: hourView.currentIndex
    property int minutes: minuteView.currentIndex * minuteMultiples
    property int seconds: secondsView.currentIndex

    property int minuteMultiples: 5
    property bool secondsPicker: false

    onHoursChanged: {
        hours = hours % 24;
        hourView.currentIndex = hours;
        timeChanged(hours, minutes, seconds);
    }
    onMinutesChanged: {
        minutes = minutes % 60;
        if (minutes % minuteMultiples != 0) {
            minuteMultiplesAboutToChange(minuteMultiples);
            minuteMultiples = 1;
        }
        minuteView.currentIndex = minutes * minuteMultiples;
        timeChanged(hours, minutes, seconds);
    }
    onSecondsChanged: {
        seconds = seconds % 60;
        secondsView.currentIndex = seconds;
        timeChanged(hours, minutes, seconds);
    }

    Component.onCompleted: {
        var now = new Date();
        hourView.currentIndex = now.getHours();
        minuteView.currentIndex = now.getMinutes() / minuteMultiples;
        secondsView.currentIndex = now.getSeconds();
    }

    function setToTimeFromDate(date) {
        hourView.currentIndex = date.getHours();
        minuteView.currentIndex = date.getMinutes() / minuteMultiples;
        secondsView.currentIndex = date.getSeconds();
    }

    function setToTimeFromString(timeString) { // Accepts in format HH:MM:SS
        var splitTimeString = timeString.split(":");
        switch (splitTimeString.length) {
            case 3:
                secondsView.currentIndex = Number(splitTimeString[2]);
            case 2:
                minuteView.currentIndex = Number(splitTimeString[1]) / minuteMultiples;
            case 1:
                hourView.currentIndex = Number(splitTimeString[0]);
            case 0:
                return;
        }
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            QQC2.Label {
                text: i18n("Min. interval:")
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

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                QQC2.ToolButton {
                    Layout.fillWidth: true
                    icon.name: "go-up"
                    enabled: hourView.currentIndex != 0
                    onClicked: hourView.currentIndex -= 1
                }
                QQC2.Tumbler {
                    id: hourView
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: 24

                    onCurrentIndexChanged: timePicker.hours = currentIndex

                    delegate: Kirigami.Heading {
                        property int thisIndex: index

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        opacity: hourView.currentIndex == thisIndex ? 1 : 0.7
                        text: modelData < 10 ? String(modelData).padStart(2, "0") : modelData
                    }
                }
                QQC2.ToolButton {
                    Layout.fillWidth: true
                    icon.name: "go-down"
                    enabled: hourView.currentIndex < hourView.count - 1
                    onClicked: hourView.currentIndex += 1
                }
            }

            Kirigami.Heading {
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: ":"
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                QQC2.ToolButton {
                    Layout.fillWidth: true
                    icon.name: "go-up"
                    enabled: minuteView.currentIndex != 0
                    onClicked: minuteView.currentIndex -= 1
                }
                QQC2.Tumbler {
                    id: minuteView
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    property int selectedIndex: 0

                    // We don't want our selected time to get reset when we update minuteMultiples, on which the model depends
                    Connections { // Gets called before model regen
                        target: timePicker
                        onMinuteMultiplesAboutToChange: minuteView.selectedIndex = minuteView.currentIndex * timePicker.minuteMultiples
                    }
                    onModelChanged: currentIndex = selectedIndex / timePicker.minuteMultiples
                    onCurrentIndexChanged: timePicker.minutes = currentIndex * timePicker.minuteMultiples

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
                QQC2.ToolButton {
                    Layout.fillWidth: true
                    icon.name: "go-down"
                    enabled: minuteView.currentIndex < minuteView.count - 1
                    onClicked: minuteView.currentIndex += 1
                }
            }

            Kirigami.Heading {
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                visible: timePicker.secondsPicker
                text: ":"
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: timePicker.secondsPicker

                QQC2.ToolButton {
                    Layout.fillWidth: true
                    icon.name: "go-up"
                    enabled: secondsView.currentIndex != 0
                    onClicked: secondsView.currentIndex -= 1
                }
                QQC2.SwipeView {
                    id: secondsView
                    orientation: Qt.Vertical
                    clip: true
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    QQC2.Tumbler {
                        model: 60

                        onCurrentIndexChanged: timePicker.hours = currentIndex

                        delegate: Kirigami.Heading {
                            property int thisIndex: index

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            opacity: secondsView.currentIndex == thisIndex ? 1 : 0.7
                            text: modelData < 10 ? String(modelData).padStart(2, "0") : modelData
                        }
                    }
                }
                QQC2.ToolButton {
                    Layout.fillWidth: true
                    icon.name: "go-down"
                    enabled: secondsView.currentIndex < secondsView.count - 1
                    onClicked: secondsView.currentIndex += 1
                }
            }
        }

        QQC2.Button {
            Layout.fillWidth: true
            text: i18n("Done")
            onClicked: done()
        }
    }
}

