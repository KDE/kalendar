// Copyright (C) 2018 Michael Bohlender, <bohlender@kolabsys.com>
// Copyright (C) 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
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
    property date startDate
    property var calendarFilter
    property bool paintGrid: true
    property bool showDayIndicator: true
    property var filter
    property alias dayHeaderDelegate: dayLabels.delegate
    property Component weekHeaderDelegate
    property int month

    //Internal
    property int numberOfLinesShown: 0
    property int numberOfRows: (daysToShow / daysPerRow)
    property var dayHeight: ((height - dayLabels.height) / numberOfRows) - spacing
    property real spacing: Kalendar.Config.monthGridBorderWidth
    required property bool loadModel
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    implicitHeight: (numberOfRows > 1 ? Kirigami.Units.gridUnit * 10 * numberOfRows : numberOfLinesShown * Kirigami.Units.gridUnit) + dayLabels.height
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
            topMargin: dayLabels.height
        }
    }

    Column {
        id: rootBackgroundColumn
        spacing: root.spacing
        anchors.fill: parent

        DayLabels {
            id: dayLabels
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
                                QQC2.Control {
                                    id: gridItem
                                    height: parent.height
                                    width: root.dayWidth
                                    property date gridSquareDate: date
                                    property date date: DateUtils.addDaysToDate(dayDelegate.startDate, modelData)
                                    property bool isInPast: DateUtils.roundToDay(date) < DateUtils.roundToDay(root.currentDate)
                                    property bool isToday: DateUtils.sameDay(root.currentDate, date)
                                    property bool isCurrentMonth: date.getMonth() == root.month

                                    background: Rectangle {
                                        Kirigami.Theme.inherit: false
                                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                                        color: gridItem.isToday ? Kirigami.Theme.activeBackgroundColor :
                                            gridItem.isCurrentMonth ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                                        DayMouseArea {
                                            anchors.fill: parent
                                            addDate: DateUtils.addDaysToDate(dayDelegate.startDate, modelData)
                                            onAddNewIncidence: addIncidence(type, addDate)
                                        }
                                    }

                                    padding: 0
                                    topPadding: 0

                                    // Day number
                                    contentItem: RowLayout {
                                        visible: root.showDayIndicator

                                        Kirigami.Heading {
                                            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                                            padding: Kirigami.Units.smallSpacing
                                            level: 4
                                            text: i18n("<b>Today</b>")
                                            color: Kirigami.Theme.highlightColor
                                            visible: gridItem.isToday && gridItem.width > Kirigami.Units.gridUnit * 5
                                        }
                                        Kirigami.Heading {
                                            Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                            level: 4
                                            text: gridItem.date.toLocaleDateString(Qt.locale(), gridItem.isToday && gridItem.date.getDate() == 1 ?
                                                "<b>d MMM</b>" : (gridItem.isToday ? "<b>d</b>" : (gridItem.date.getDate() == 1 ? "d MMM" : "d")))
                                            padding: Kirigami.Units.smallSpacing
                                            visible: root.showDayIndicator
                                            color: gridItem.isToday ? Kirigami.Theme.highlightColor : (!gridItem.isCurrentMonth ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor)
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
            topMargin: dayLabels.height + root.spacing
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
                                Layout.rightMargin: parent.contentHeight > parent.availableHeight ?
                                    spacing : spacing

                                clip: true
                                spacing: Kirigami.Units.smallSpacing

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
                                                    modelData.endTime.getMonth() == root.month ||
                                                    modelData.startTime.getMonth() == root.month
                                                radius: parent.rectRadius
                                            }

                                            RowLayout {
                                                id: incidenceContents

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
                                                    leftMargin: Kirigami.Units.smallSpacing
                                                    rightMargin: Kirigami.Units.smallSpacing
                                                }

                                                Kirigami.Icon {
                                                    Layout.maximumHeight: parent.height
                                                    Layout.maximumWidth: height

                                                    source: modelData.incidenceTypeIcon
                                                    color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                        incidenceBackground.visible ? incidenceContents.textColor :
                                                        incidenceContents.otherMonthTextColor(modelData.color)
                                                }

                                                QQC2.Label {
                                                    Layout.fillWidth: true
                                                    text: modelData.text
                                                    elide: Text.ElideRight
                                                    font.weight: Font.Medium
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
