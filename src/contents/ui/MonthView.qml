// Copyright (C) 2018 Michael Bohlender, <bohlender@kolabsys.com>
// Copyright (C) 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar

import "dateutils.js" as DateUtils

Kirigami.Page {
    id: monthPage

    signal addIncidence(int type, date addDate)
    signal viewIncidence(var modelData, var collectionData)
    signal editIncidence(var incidencePtr, var collectionId)
    signal deleteIncidence(var incidencePtr, date deleteDate)
    signal completeTodo(var incidencePtr)
    signal addSubTodo(var parentWrapper)

    property var openOccurrence
    property alias startDate: dayView.startDate
    property alias currentDate: dayView.currentDate
    property alias calendarFilter: dayView.calendarFilter
    property alias month: dayView.month
    property int year: dayView.currentDate.getFullYear()
    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 40
    readonly property bool isTiny: width < Kirigami.Units.gridUnit * 18

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

    padding: 0

    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    actions {
        left: Kirigami.Action {
            icon.name: "go-previous"
            text: i18n("Previous month")
            onTriggered: setToDate(new Date(startDate.getFullYear(), startDate.getMonth()))
            displayHint: Kirigami.DisplayHint.IconOnly
        }
        right: Kirigami.Action {
            icon.name: "go-next"
            text: i18n("Next month")
            onTriggered: setToDate(new Date(startDate.getFullYear(), startDate.getMonth() + 2)) // Yes. I don't know.
            displayHint: Kirigami.DisplayHint.IconOnly
        }
        main: Kirigami.Action {
            icon.name: "go-jump-today"
            text: i18n("Today")
            onTriggered: setToDate(new Date())
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
                text: {
                    let longText = day.toLocaleString(Qt.locale(), "dddd");
                    let midText = day.toLocaleString(Qt.locale(), "ddd");
                    let shortText = midText.slice(0,1);
                    switch(Kalendar.Config.weekdayLabelLength) { // HACK: Ideally should use config enum
                        case 0: // Full
                            let chosenFormat = "dddd"
                            return monthPage.isLarge ? longText : monthPage.isTiny ? shortText : midText;
                        case 1: // Abbr
                            return monthPage.isTiny ? shortText : midText;
                        case 2: // Letter
                        default:
                            return shortText;
                    }
                }
                level: 2
                leftPadding: Kirigami.Units.smallSpacing
                rightPadding: Kirigami.Units.smallSpacing
                horizontalAlignment: {
                    switch(Kalendar.Config.weekdayLabelAlignment) { // HACK: Ideally should use config enum
                        case 0: // Left
                            return Text.AlignLeft;
                        case 1: // Center
                            return Text.AlignHCenter;
                        case 2: // Right
                            return Text.AlignRight;
                        default:
                            return Text.AlignHCenter;
                    }
                }
            }
        }

        weekHeaderDelegate: QQC2.Label {
            padding: Kirigami.Units.smallSpacing
            verticalAlignment: Qt.AlignTop
            horizontalAlignment: Qt.AlignHCenter
            text: DateUtils.getWeek(startDate, Qt.locale().firstDayOfWeek)
        }

        openOccurrence: monthPage.openOccurrence

        onAddIncidence: monthPage.addIncidence(type, addDate)
        onViewIncidence: monthPage.viewIncidence(modelData, collectionData)
        onEditIncidence: monthPage.editIncidence(incidencePtr, collectionId)
        onDeleteIncidence: monthPage.deleteIncidence(incidencePtr, deleteDate)
        onCompleteTodo: monthPage.completeTodo(incidencePtr)
        onAddSubTodo: monthPage.addSubTodo(parentWrapper)
    }
}

