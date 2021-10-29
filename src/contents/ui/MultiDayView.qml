// Copyright (C) 2018 Michael Bohlender, <bohlender@kolabsys.com>
// Copyright (C) 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Item {
    id: root
    property alias bgLoader: backgroundLoader.item
    property date currentDate
    // Getting the components once makes this faster when we need them repeatedly
    property int currentDay: currentDate ? currentDate.getDate() : null
    property int currentMonth: currentDate ? currentDate.getMonth() : null
    property int currentYear: currentDate ? currentDate.getFullYear() : null
    property Component dayHeaderDelegate
    property var dayHeight: ((height - bgLoader.dayLabels.height) / numberOfRows) - spacing
    property double dayWidth: Kalendar.Config.showWeekNumbers ? ((width - weekHeaderWidth) / daysPerRow) - spacing : // No spacing on right, spacing in between weekheader and monthgrid
    (width - weekHeaderWidth - (spacing * (daysPerRow - 1))) / daysPerRow // No spacing on left or right of month grid when no week header
    property int daysPerRow: 7
    property int daysToShow: daysPerRow * 6
    property var filter
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)
    required property bool loadModel
    property int month

    //Internal
    property int numberOfLinesShown: 0
    property int numberOfRows: (daysToShow / daysPerRow)
    property var openOccurrence
    property bool paintGrid: true
    property bool showDayIndicator: true
    property real spacing: Kalendar.Config.monthGridBorderWidth
    property date startDate
    property Component weekHeaderDelegate
    property double weekHeaderWidth: Kalendar.Config.showWeekNumbers ? Kirigami.Units.gridUnit * 1.5 : 0

    height: implicitHeight
    implicitHeight: (numberOfRows > 1 ? Kirigami.Units.gridUnit * 10 * numberOfRows : numberOfLinesShown * Kirigami.Units.gridUnit) + bgLoader.dayLabels.height

    signal addIncidence(int type, date addDate)
    signal addSubTodo(var parentWrapper)
    signal completeTodo(var incidencePtr)
    signal deleteIncidence(var incidencePtr, date deleteDate)
    signal deselect
    signal editIncidence(var incidencePtr, var collectionId)
    signal viewIncidence(var modelData, var collectionData)

    Loader {
        id: modelLoader
        active: root.loadModel
        asynchronous: true

        sourceComponent: Kalendar.MultiDayIncidenceModel {
            periodLength: 7

            model: Kalendar.IncidenceOccurrenceModel {
                id: occurrenceModel
                calendar: Kalendar.CalendarManager.calendar
                filter: root.filter ? root.filter : {}
                length: root.daysToShow
                objectName: "incidenceOccurrenceModel"
                start: root.startDate
            }
        }
    }
    Kirigami.Separator {
        id: gridBackground
        visible: backgroundLoader.status === Loader.Ready

        anchors {
            fill: parent
            topMargin: root.bgLoader.dayLabels.height
        }
    }
    Loader {
        id: backgroundLoader
        active: true
        anchors.fill: parent
        asynchronous: true

        sourceComponent: Column {
            id: rootBackgroundColumn
            property alias dayLabels: dayLabelsComponent

            anchors.fill: parent
            spacing: root.spacing

            DayLabels {
                id: dayLabelsComponent
                anchors.left: parent.left
                anchors.leftMargin: Kalendar.Config.showWeekNumbers ? weekHeaderWidth + root.spacing : 0
                anchors.right: parent.right
                dayWidth: root.dayWidth
                daysToShow: root.daysPerRow
                delegate: root.dayHeaderDelegate
                spacing: root.spacing
                startDate: root.startDate
            }
            Repeater {
                model: root.numberOfRows

                //One row => one week
                Item {
                    clip: true
                    height: root.dayHeight
                    width: parent.width

                    RowLayout {
                        height: parent.height
                        spacing: root.spacing
                        width: parent.width

                        Loader {
                            id: weekHeader
                            property date startDate: DateUtils.addDaysToDate(root.startDate, index * 7)

                            Layout.fillHeight: true
                            Layout.preferredWidth: weekHeaderWidth
                            active: Kalendar.Config.showWeekNumbers
                            sourceComponent: root.weekHeaderDelegate
                            visible: Kalendar.Config.showWeekNumbers
                        }
                        Item {
                            id: dayDelegate
                            property date startDate: DateUtils.addDaysToDate(root.startDate, index * 7)

                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            //Grid
                            Row {
                                height: parent.height
                                spacing: root.spacing

                                Repeater {
                                    id: gridRepeater
                                    model: root.daysPerRow

                                    Item {
                                        id: gridItem
                                        property date date: DateUtils.addDaysToDate(dayDelegate.startDate, modelData)
                                        property int day: date.getDate()
                                        property date gridSquareDate: date
                                        property bool isCurrentMonth: month === root.month
                                        property bool isToday: day === root.currentDay && month === root.currentMonth && year === root.currentYear
                                        property int month: date.getMonth()
                                        property int year: date.getFullYear()

                                        height: root.dayHeight
                                        width: root.dayWidth

                                        Rectangle {
                                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                                            Kirigami.Theme.inherit: false
                                            anchors.fill: parent
                                            color: gridItem.isToday ? Kirigami.Theme.activeBackgroundColor : gridItem.isCurrentMonth ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                                            DayMouseArea {
                                                addDate: gridItem.date
                                                anchors.fill: parent

                                                onAddNewIncidence: addIncidence(type, addDate)
                                                onDeselect: root.deselect()
                                            }
                                        }

                                        // Day number
                                        RowLayout {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            visible: root.showDayIndicator

                                            QQC2.Label {
                                                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                                                color: Kirigami.Theme.highlightColor
                                                padding: Kirigami.Units.smallSpacing
                                                text: i18n("<b>Today</b>")
                                                visible: gridItem.isToday && gridItem.width > Kirigami.Units.gridUnit * 5
                                            }
                                            QQC2.Label {
                                                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                                color: gridItem.isToday ? Kirigami.Theme.highlightColor : (!gridItem.isCurrentMonth ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor)
                                                font.bold: gridItem.isToday
                                                padding: Kirigami.Units.smallSpacing
                                                text: gridItem.date.toLocaleDateString(Qt.locale(), gridItem.day == 1 ? "d MMM" : "d")
                                                visible: root.showDayIndicator
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Column {
        id: rootForegroundColumn
        spacing: root.spacing

        anchors {
            fill: parent
            leftMargin: Kalendar.Config.showWeekNumbers ? weekHeaderWidth + root.spacing : 0
            topMargin: root.bgLoader.dayLabels.height + root.spacing
        }

        //Weeks
        Repeater {
            model: modelLoader.item

            //One row => one week
            Item {
                clip: true
                height: root.dayHeight
                width: parent.width

                RowLayout {
                    height: parent.height
                    spacing: root.spacing
                    width: parent.width

                    Item {
                        id: dayDelegate
                        property date startDate: periodStartDate

                        Layout.fillHeight: true
                        Layout.fillWidth: true

                        QQC2.ScrollView {
                            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                            anchors {
                                fill: parent
                                // Offset for date
                                topMargin: root.showDayIndicator ? Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 1.5 : 0
                            }
                            ListView {
                                id: linesRepeater
                                Layout.fillWidth: true
                                Layout.rightMargin: spacing
                                clip: true
                                model: incidences
                                spacing: root.dayWidth < (Kirigami.Units.gridUnit * 5 + Kirigami.Units.smallSpacing * 2) ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing

                                onCountChanged: {
                                    root.numberOfLinesShown = count;
                                }

                                DayMouseArea {
                                    id: listViewMenu
                                    anchors.fill: parent
                                    z: -1

                                    function useGridSquareDate(type, root, globalPos) {
                                        for (var i in root.children) {
                                            var child = root.children[i];
                                            var localpos = child.mapFromGlobal(globalPos.x, globalPos.y);
                                            if (child.contains(localpos) && child.gridSquareDate) {
                                                addIncidence(type, child.gridSquareDate);
                                            } else {
                                                useGridSquareDate(type, child, globalPos);
                                            }
                                        }
                                    }

                                    onAddNewIncidence: useGridSquareDate(type, applicationWindow().contentItem, this.mapToGlobal(clickX, clickY))
                                    onDeselect: root.deselect()
                                }

                                delegate: Item {
                                    id: line
                                    height: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing

                                    //Incidences
                                    Repeater {
                                        id: incidencesRepeater
                                        model: modelData

                                        MultiDayViewIncidenceDelegate {
                                            dayWidth: root.dayWidth
                                            horizontalSpacing: linesRepeater.spacing
                                            isDark: root.isDark
                                            openOccurrenceId: root.openOccurrence ? root.openOccurrence.incidenceId : ""
                                            parentViewSpacing: root.spacing
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
