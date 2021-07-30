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
    signal addIncidenceReceived(int receivedType, date receivedAddDate)
    signal viewIncidenceReceived(var receivedModelData, var receivedCollectionData)
    signal editIncidenceReceived(var receivedIncidencePtr, var receivedCollectionId)
    signal deleteIncidenceReceived(var receivedIncidencePtr, date receivedDeleteDate)
    signal completeTodoReceived(var receivedIncidencePtr)

    property alias startDate: dayView.startDate
    property alias currentDate: dayView.currentDate
    property alias calendarFilter: dayView.calendarFilter
    property alias month: dayView.month
    property int year: dayView.currentDate.getFullYear()
    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 30

    function setToDate(date) {
        let newDate = new Date(date)
        dayView.month = newDate.getMonth()
        year = newDate.getFullYear()

        newDate = DateUtils.getFirstDayOfWeek(DateUtils.getFirstDayOfMonth(newDate))

        // Handling adding and subtracting months in Javascript can get *really* messy.
        newDate = DateUtils.addDaysToDate(newDate, 7)

        if (newDate.getMonth() === dayView.month) {
            newDate = DateUtils.addDaysToDate(newDate, - 7)
        }
        if (newDate.getDate() < 14) {
            newDate = DateUtils.addDaysToDate(newDate, - 7)
        }

        startDate = newDate;
    }

    topPadding: 0
    rightPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.largeSpacing
    leftPadding: 0

    background: Rectangle {
        Kirigami.Theme.colorSet: monthPage.isLarge ? Kirigami.Theme.Header : Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    actions {
        left: Kirigami.Action {
            icon.name: "go-previous"
            text: i18n("Previous month")
            onTriggered: setToDate(new Date(startDate.getFullYear(), startDate.getMonth()))
        }
        right: Kirigami.Action {
            icon.name: "go-next"
            text: i18n("Next month")
            onTriggered: setToDate(new Date(startDate.getFullYear(), startDate.getMonth() + 2)) // Yes. I don't know.
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

        onAddIncidence: addIncidenceReceived(type, addDate)
        onViewIncidence: viewIncidenceReceived(modelData, collectionData)
        onEditIncidence: editIncidenceReceived(incidencePtr, collectionId)
        onDeleteIncidence: deleteIncidenceReceived(incidencePtr, deleteDate)
        onCompleteTodo: completeTodoReceived(incidencePtr)
    }
}

