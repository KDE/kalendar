// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami

Item {
    id: timePicker

    signal done()

    anchors.fill: parent

    property int hours: hourView.currentIndex
    property int minutes: minuteView.currentIndex * minuteMultiples
    property int seconds: secondsView.currentIndex

    Component.onCompleted: {
        var now = new Date()
        hourView.currentIndex = now.getHours()
        minuteView.currentIndex = now.getMinutes() / minuteMultiples
        secondsView.currentIndex = now.getSeconds()
    }

    property int minuteMultiples: 5
    property bool secondsPicker: false

    function setToTimeFromString(timeString) { // Accepts in format HH:MM:SS
        var splitTimeString = timeString.split(":");
        console.log(splitTimeString);
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
            Layout.fillWidth: true
            Layout.fillHeight: true

            // For some weird reason, the first swipeview used refuses to change the current index when swiping it.
            // This is a janky workaround.
            QQC2.SwipeView {
                visible: false
                Repeater {
                    model: 1
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                QQC2.ToolButton {
                    Layout.fillWidth: true
                    icon.name: "go-up"
                    enabled: hourView.currentIndex != 0
                    onClicked: hourView.currentIndex -= 1
                }
                QQC2.SwipeView {
                    id: hourView
                    orientation: Qt.Vertical
                    clip: true
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Repeater {
                        model: 24
                        delegate: Kirigami.Heading {
                            property int thisIndex: index

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            opacity: hourView.currentIndex == thisIndex ? 1 : 0.7
                            text: modelData < 10 ? String(modelData).padStart(2, "0") : modelData
                        }
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
                QQC2.SwipeView {
                    id: minuteView
                    orientation: Qt.Vertical
                    clip: true
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Repeater {
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

                    Repeater {
                        model: 60
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

