// Copyright (C) 2018 Michael Bohlender, <bohlender@kolabsys.com>
// Copyright (C) 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import "dateutils.js" as DateUtils

Kirigami.Page {
    id: monthPage

    // More elegant way of sending this up to main.qml?
    signal viewEventReceived(var receivedModelData, var receivedCollectionData)
    signal editEventReceived(var receivedEventPtr, var receivedCollectionId)
    signal deleteEventReceived(var receivedEventPtr, date receivedDeleteDate)

    property alias startDate: dayView.startDate
    property alias currentDate: dayView.currentDate
    property alias calendarFilter: dayView.calendarFilter
    property alias month: dayView.month
    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 30

    padding: 0
    background: Rectangle {
        Kirigami.Theme.colorSet: monthPage.isLarge ? Kirigami.Theme.Header : Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    actions {
        left: Kirigami.Action {
            text: i18n("Previous")
            onTriggered: {
                dayView.month - 1 < 0 ? dayView.month = 11 : dayView.month -= 1
                let newDate = DateUtils.getFirstDayOfWeek(DateUtils.previousMonth(startDate))

                // Handling adding and subtracting months in Javascript can get *really* messy.
                newDate = DateUtils.addDaysToDate(newDate, 7)

                if (newDate.getMonth() === dayView.month) {
                    newDate = DateUtils.addDaysToDate(newDate, - 7)
                }
                if (newDate.getDate() < 14) {
                    newDate = DateUtils.addDaysToDate(newDate, - 7)
                }

                console.log(dayView.month)
                startDate = newDate
            }
        }
        right: Kirigami.Action {
            text: i18n("Next")
            onTriggered: {
                dayView.month = (dayView.month + 1) % 12
                let newDate = DateUtils.getFirstDayOfWeek(DateUtils.nextMonth(startDate))
                newDate = DateUtils.addDaysToDate(newDate, 7)

                if (newDate.getMonth() === dayView.month) {
                    newDate = DateUtils.addDaysToDate(newDate, - 7)
                }
                if (newDate.getDate() < 14) {
                    newDate = DateUtils.addDaysToDate(newDate, - 7)
                }

                startDate = newDate
            }
        }
    }

    MultiDayView {
        id: dayView
        objectName: "monthView"
        anchors.fill: parent
        daysToShow: daysPerRow * 6
        daysPerRow: 7
        paintGrid: true
        showDayIndicator: true
        dayHeaderDelegate: QQC2.Control {
            Layout.maximumHeight: Kirigami.Units.gridUnit * 2
            contentItem: Kirigami.Heading {
                text: day.toLocaleString(Qt.locale(), monthPage.isLarge ? "dddd" : "ddd")
                level: 2
                horizontalAlignment: monthPage.isLarge ? Text.AlignRight : Text.AlignHCenter
            }
            background: Rectangle {
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                color: Kirigami.Theme.backgroundColor
            }
        }

        weekHeaderDelegate: QQC2.Label {
            padding: Kirigami.Units.smallSpacing
            verticalAlignment: Qt.AlignTop
            horizontalAlignment: Qt.AlignHCenter
            text: DateUtils.getWeek(startDate, Qt.locale().firstDayOfWeek)
        }

        onViewEvent: viewEventReceived(modelData, collectionData)
        onEditEvent: editEventReceived(eventPtr, collectionId)
        onDeleteEvent: deleteEventReceived(eventPtr, deleteDate)

    }
}

