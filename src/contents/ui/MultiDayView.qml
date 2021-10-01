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

    signal addIncidence(int type, date addDate)
    signal viewIncidence(var modelData, var collectionData)
    signal editIncidence(var incidencePtr, var collectionId)
    signal deleteIncidence(var incidencePtr, date deleteDate)
    signal completeTodo(var incidencePtr)
    signal addSubTodo(var parentWrapper)

    property var openOccurrence

    property int daysToShow: daysPerRow * 6
    property int daysPerRow: 7
    property double weekHeaderWidth: Kalendar.Config.showWeekNumbers ? Kirigami.Units.gridUnit * 1.5 : 0
    property double dayWidth: Kalendar.Config.showWeekNumbers ?
        ((width - weekHeaderWidth) / daysPerRow) - spacing : // No spacing on right, spacing in between weekheader and monthgrid
        (width - weekHeaderWidth - (spacing * (daysPerRow - 1))) / daysPerRow // No spacing on left or right of month grid when no week header
    property date currentDate
    // Getting the components once makes this faster when we need them repeatedly
    property int currentDay: currentDate ? currentDate.getDate() : null
    property int currentMonth: currentDate ? currentDate.getMonth() : null
    property int currentYear: currentDate ? currentDate.getFullYear() : null
    property date startDate
    property var calendarFilter
    property bool paintGrid: true
    property bool showDayIndicator: true
    property var filter
    property Component dayHeaderDelegate
    property Component weekHeaderDelegate
    property int month
    property alias bgLoader: backgroundLoader.item

    //Internal
    property int numberOfLinesShown: 0
    property int numberOfRows: (daysToShow / daysPerRow)
    property var dayHeight: ((height - bgLoader.dayLabels.height) / numberOfRows) - spacing
    property real spacing: Kalendar.Config.monthGridBorderWidth
    required property bool loadModel
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    implicitHeight: (numberOfRows > 1 ? Kirigami.Units.gridUnit * 10 * numberOfRows : numberOfLinesShown * Kirigami.Units.gridUnit) + bgLoader.dayLabels.height
    height: implicitHeight

    Loader {
        id: modelLoader
        active: root.loadModel
        asynchronous: true
        sourceComponent: Kalendar.MultiDayIncidenceModel {
            periodLength: 7
            model: Kalendar.IncidenceOccurrenceModel {
                id: occurrenceModel
                objectName: "incidenceOccurrenceModel"
                start: root.startDate
                length: root.daysToShow
                filter: root.filter ? root.filter : {}
                calendar: Kalendar.CalendarManager.calendar
            }
        }
    }

    Kirigami.Separator {
        id: gridBackground
        anchors {
            fill: parent
            topMargin: root.bgLoader.dayLabels.height
        }
        visible: backgroundLoader.status === Loader.Ready
    }

    Loader {
        id: backgroundLoader
        anchors.fill: parent
        active: true
        asynchronous: true
        sourceComponent: Column {
            id: rootBackgroundColumn
            spacing: root.spacing
            anchors.fill: parent

            property alias dayLabels: dayLabelsComponent
            DayLabels {
                id: dayLabelsComponent
                delegate: root.dayHeaderDelegate
                startDate: root.startDate
                dayWidth: root.dayWidth
                daysToShow: root.daysPerRow
                spacing: root.spacing
                anchors.leftMargin: Kalendar.Config.showWeekNumbers ? weekHeaderWidth + root.spacing : 0
                anchors.left: parent.left
                anchors.right: parent.right
            }

            Repeater {
                model: root.numberOfRows

                //One row => one week
                Item {
                    width: parent.width
                    height: root.dayHeight
                    clip: true
                    RowLayout {
                        width: parent.width
                        height: parent.height
                        spacing: root.spacing
                        Loader {
                            id: weekHeader
                            sourceComponent: root.weekHeaderDelegate
                            property date startDate: DateUtils.addDaysToDate(root.startDate, index * 7)
                            Layout.preferredWidth: weekHeaderWidth
                            Layout.fillHeight: true
                            active: Kalendar.Config.showWeekNumbers
                            visible: Kalendar.Config.showWeekNumbers

                        }
                        Item {
                            id: dayDelegate
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            property date startDate: DateUtils.addDaysToDate(root.startDate, index * 7)

                            //Grid
                            Row {
                                spacing: root.spacing
                                height: parent.height
                                Repeater {
                                    id: gridRepeater
                                    model: root.daysPerRow

                                    Item {
                                        id: gridItem
                                        height: root.dayHeight
                                        width: root.dayWidth
                                        property date gridSquareDate: date
                                        property date date: DateUtils.addDaysToDate(dayDelegate.startDate, modelData)
                                        property int day: date.getDate()
                                        property int month: date.getMonth()
                                        property int year: date.getFullYear()
                                        property bool isToday: day === root.currentDay && month === root.currentMonth && year === root.currentYear
                                        property bool isCurrentMonth: month === root.month

                                        Rectangle {
                                            anchors.fill: parent
                                            Kirigami.Theme.inherit: false
                                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                                            color: gridItem.isToday ? Kirigami.Theme.activeBackgroundColor :
                                                gridItem.isCurrentMonth ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                                            DayMouseArea {
                                                anchors.fill: parent
                                                addDate: gridItem.date
                                                onAddNewIncidence: addIncidence(type, addDate)
                                            }
                                        }

                                        // Day number
                                        RowLayout {
                                            visible: root.showDayIndicator
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.left: parent.left

                                            QQC2.Label {
                                                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                                                padding: Kirigami.Units.smallSpacing
                                                text: i18n("<b>Today</b>")
                                                color: Kirigami.Theme.highlightColor
                                                visible: gridItem.isToday && gridItem.width > Kirigami.Units.gridUnit * 5
                                            }
                                            QQC2.Label {
                                                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                                text: gridItem.date.toLocaleDateString(Qt.locale(), gridItem.day == 1 ?
                                                "d MMM" : "d")
                                                padding: Kirigami.Units.smallSpacing
                                                visible: root.showDayIndicator
                                                color: gridItem.isToday ? Kirigami.Theme.highlightColor : (!gridItem.isCurrentMonth ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor)
                                                font.bold: gridItem.isToday
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
            topMargin: root.bgLoader.dayLabels.height + root.spacing
            leftMargin: Kalendar.Config.showWeekNumbers ? weekHeaderWidth + root.spacing : 0
        }

        //Weeks
        Repeater {
            model: modelLoader.item
            //One row => one week
            Item {
                width: parent.width
                height: root.dayHeight
                clip: true
                RowLayout {
                    width: parent.width
                    height: parent.height
                    spacing: root.spacing
                    Item {
                        id: dayDelegate
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        property date startDate: periodStartDate

                        QQC2.ScrollView {
                            anchors {
                                fill: parent
                                // Offset for date
                                topMargin: root.showDayIndicator ? Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing : 0
                            }

                            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                            ListView {
                                id: linesRepeater
                                Layout.fillWidth: true
                                Layout.rightMargin: spacing

                                clip: true
                                spacing: root.dayWidth < (Kirigami.Units.gridUnit * 5 + Kirigami.Units.smallSpacing * 2) ?
                                    Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing

                                DayMouseArea {
                                    id: listViewMenu
                                    anchors.fill: parent
                                    z: -1

                                    function useGridSquareDate(type, root, globalPos) {
                                        for(var i in root.children) {
                                            var child = root.children[i];
                                            var localpos = child.mapFromGlobal(globalPos.x, globalPos.y);

                                            if(child.contains(localpos) && child.gridSquareDate) {
                                                addIncidence(type, child.gridSquareDate);
                                            } else {
                                                useGridSquareDate(type, child, globalPos);
                                            }
                                        }
                                    }

                                    onAddNewIncidence: useGridSquareDate(type, applicationWindow().contentItem, this.mapToGlobal(clickX, clickY))
                                }

                                model: incidences
                                onCountChanged: {
                                    root.numberOfLinesShown = count
                                }

                                delegate: Item {
                                    id: line
                                    height: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing

                                    //Incidences
                                    Repeater {
                                        id: incidencesRepeater
                                        model: modelData
                                        Rectangle {
                                            x: ((root.dayWidth + root.spacing) * modelData.starts) + horizontalSpacing
                                            y: 0
                                            width: ((root.dayWidth + root.spacing) * modelData.duration) - (horizontalSpacing * 2) - root.spacing // Account for spacing added to x and for spacing at end of line
                                            height: parent.height
                                            opacity: isOpenOccurrence ||
                                                modelData.endTime.getMonth() == root.month ||
                                                modelData.startTime.getMonth() == root.month ?
                                                1.0 : 0.5
                                            radius: rectRadius
                                            color: Qt.rgba(0,0,0,0)

                                            property int rectRadius: 5
                                            property int horizontalSpacing: linesRepeater.spacing

                                            property bool isOpenOccurrence: root.openOccurrence ?
                                                root.openOccurrence.incidenceId === modelData.incidenceId : false

                                            Rectangle {
                                                id: incidenceBackground
                                                anchors.fill: parent
                                                color: isOpenOccurrence ? modelData.color :
                                                    LabelUtils.getIncidenceBackgroundColor(modelData.color, root.isDark)
                                                visible: isOpenOccurrence ||
                                                    modelData.endTime.getMonth() === root.month ||
                                                    modelData.startTime.getMonth() === root.month
                                                radius: parent.rectRadius
                                            }

                                            RowLayout {
                                                id: incidenceContents
                                                clip: true
                                                property bool spaceRestricted: parent.width < Kirigami.Units.gridUnit * 5

                                                property color textColor: LabelUtils.getIncidenceLabelColor(modelData.color, root.isDark)

                                                function otherMonthTextColor(color) {
                                                    if(root.isDark) {
                                                        if(LabelUtils.getDarkness(color) >= 0.5) {
                                                            return Qt.lighter(color, 2);
                                                        }
                                                        return Qt.lighter(color, 1.5);
                                                    }
                                                    return Qt.darker(color, 3);
                                                }

                                                anchors {
                                                    fill: parent
                                                    leftMargin: spaceRestricted ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
                                                    rightMargin: spaceRestricted ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
                                                }

                                                Kirigami.Icon {
                                                    Layout.maximumHeight: parent.height
                                                    Layout.maximumWidth: height

                                                    source: modelData.incidenceTypeIcon
                                                    isMask: true
                                                    color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                        incidenceBackground.visible ? incidenceContents.textColor :
                                                        incidenceContents.otherMonthTextColor(modelData.color)
                                                    visible: !parent.spaceRestricted
                                                }

                                                QQC2.Label {
                                                    Layout.fillWidth: true
                                                    text: modelData.text
                                                    elide: parent.spaceRestricted ? Text.ElideNone : Text.ElideRight // Eliding takes up space
                                                    font.weight: Font.Medium
                                                    font.pointSize: parent.spaceRestricted ? Kirigami.Theme.smallFont.pointSize :
                                                        Kirigami.Theme.defaultFont.pointSize
                                                    color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                        incidenceBackground.visible ? incidenceContents.textColor :
                                                        incidenceContents.otherMonthTextColor(modelData.color)
                                                }
                                            }

                                            IncidenceMouseArea {
                                                incidenceData: modelData
                                                collectionId: modelData.collectionId

                                                onViewClicked: viewIncidence(modelData, collectionData)
                                                onEditClicked: editIncidence(incidencePtr, collectionId)
                                                onDeleteClicked: deleteIncidence(incidencePtr, deleteDate)
                                                onTodoCompletedClicked: completeTodo(incidencePtr)
                                                onAddSubTodoClicked: root.addSubTodo(parentWrapper)
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
}
