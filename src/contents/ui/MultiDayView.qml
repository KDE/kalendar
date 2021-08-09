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

    property int daysToShow
    property int daysPerRow: daysToShow
    property double weekHeaderWidth: Kirigami.Units.gridUnit * 1.5
    property double dayWidth: (width - weekHeaderWidth - daysPerRow) / daysPerRow
    property date currentDate
    property date startDate
    property var calendarFilter
    property bool paintGrid: false
    property bool showDayIndicator: false
    property var filter
    property alias dayHeaderDelegate: dayLabels.delegate
    property Component weekHeaderDelegate
    property int month

    //Internal
    property int numberOfLinesShown: 0
    property int numberOfRows: (daysToShow / daysPerRow)
    property var dayHeight: (height - dayLabels.height) / numberOfRows

    implicitHeight: (numberOfRows > 1 ? Kirigami.Units.gridUnit * 10 * numberOfRows: numberOfLinesShown * Kirigami.Units.gridUnit) + dayLabels.height

    height: implicitHeight

    Column {
        spacing: 0
        anchors {
            fill: parent
        }

        DayLabels {
            id: dayLabels
            startDate: root.startDate
            dayWidth: root.dayWidth
            daysToShow: root.daysPerRow
            anchors.leftMargin: weekHeaderWidth
            anchors.left: parent.left
            anchors.right: parent.right
        }

        //Weeks
        Repeater {
            model: Kalendar.MultiDayIncidenceModel {
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
            //One row => one week
            Item {
                width: parent.width
                height: root.dayHeight
                clip: true
                RowLayout {
                    width: parent.width
                    height: parent.height
                    spacing: 0
                    Loader {
                        id: weekHeader
                        sourceComponent: root.weekHeaderDelegate
                        property var startDate: periodStartDate
                        Layout.preferredWidth: weekHeaderWidth
                        Layout.fillHeight: true
                    }
                    Item {
                        id: dayDelegate
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        property var startDate: periodStartDate

                        //Grid
                        Row {
                            spacing: 0
                            height: parent.height
                            Repeater {
                                id: gridRepeater
                                model: root.daysPerRow
                                QQC2.Control {
                                    id: gridItem
                                    height: parent.height
                                    width: root.dayWidth
                                    property date gridSquareDate: date
                                    property var date: DateUtils.addDaysToDate(dayDelegate.startDate, modelData)
                                    property bool isInPast: DateUtils.roundToDay(date) < DateUtils.roundToDay(root.currentDate)
                                    property bool isToday: DateUtils.sameDay(root.currentDate, date)
                                    property bool isCurrentMonth: date.getMonth() == root.month

                                    background: Rectangle {
                                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                                        color: gridItem.isToday ? Kirigami.Theme.activeBackgroundColor :
                                            gridItem.isCurrentMonth ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                                        // Matches Kirigami Separator color
                                        border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.15)
                                        border.width: 1

                                        DayMouseArea {
                                            anchors.fill: parent
                                            addDate: DateUtils.addDaysToDate(periodStartDate, modelData)
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
                                            visible: gridItem.isToday
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

                        QQC2.ScrollView {

                            anchors {
                                fill: parent
                                // Offset for date
                                topMargin: root.showDayIndicator ? Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing : 0
                            }

                            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                            ListView {
                                Layout.fillWidth: true
                                id: linesRepeater

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
                                    width: parent.width

                                    //Incidences
                                    Repeater {
                                        id: incidencesRepeater
                                        model: modelData
                                        Rectangle {
                                            x: (root.dayWidth /*+ 1*/) * modelData.starts // +1 because of the spacing
                                            y: 0
                                            width: root.dayWidth * modelData.duration
                                            height: parent.height
                                            opacity: modelData.endTime.getMonth() == root.month || modelData.startTime.getMonth() == root.month ?
                                                    1.0 : 0.5
                                            radius: rectRadius

                                            property int rectRadius: 5

                                            Rectangle {
                                                anchors.fill: parent
                                                color: modelData.color
                                                radius: parent.rectRadius
                                                border.width: 1
                                                border.color: Kirigami.Theme.alternateBackgroundColor
                                            }

                                            RowLayout {
                                                anchors {
                                                    fill: parent
                                                    leftMargin: Kirigami.Units.smallSpacing
                                                    rightMargin: Kirigami.Units.smallSpacing
                                                }

                                                Kirigami.Icon {
                                                    Layout.maximumHeight: parent.height
                                                    Layout.maximumWidth: height

                                                    source: modelData.incidenceTypeIcon
                                                    color: LabelUtils.isDarkColor(modelData.color) ? "white" : "black"
                                                }

                                                QQC2.Label {
                                                    Layout.fillWidth: true
                                                    text: modelData.text
                                                    elide: Text.ElideRight
                                                    color: LabelUtils.isDarkColor(modelData.color) ? "white" : "black"
                                                }
                                            }

                                            IncidenceMouseArea {
                                                incidenceData: modelData
                                                collectionDetails: Kalendar.CalendarManager.getCollectionDetails(modelData.collectionId)

                                                onViewClicked: viewIncidence(modelData, collectionData)
                                                onEditClicked: editIncidence(incidencePtr, collectionId)
                                                onDeleteClicked: deleteIncidence(incidencePtr, deleteDate)
                                                onTodoCompletedClicked: completeTodo(incidencePtr)
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
