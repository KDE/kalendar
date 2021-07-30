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
        spacing: 1
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
                // daysPerRow: root.daysPerRow //Hardcoded to 7
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
                            spacing: 1
                            height: parent.height
                            Repeater {
                                id: gridRepeater
                                model: root.daysPerRow
                                QQC2.Control {
                                    id: gridItem
                                    height: parent.height
                                    width: root.dayWidth
                                    property var date: DateUtils.addDaysToDate(dayDelegate.startDate, modelData)
                                    property bool isInPast: DateUtils.roundToDay(date) < DateUtils.roundToDay(root.currentDate)
                                    property bool isToday: DateUtils.sameDay(root.currentDate, date)
                                    property bool isCurrentMonth: date.getMonth() == root.month

                                    background: Rectangle {
                                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                                        color: model.sameMonth ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                                        DayMouseArea {
                                            anchors.fill: parent
                                            addDate: DateUtils.addDaysToDate(periodStartDate, modelData)
                                            onAddNewIncidence: addIncidence(type, addDate)
                                        }
                                    }

                                    padding: 0
                                    topPadding: 0

                                    // Day number
                                    contentItem: Kirigami.Heading {
                                        level: 4
                                        text: gridItem.date.toLocaleDateString(Qt.locale(), gridItem.date.getDate() == 1 ? "d MMM" : "d")
                                        horizontalAlignment: Text.AlignRight
                                        verticalAlignment: Text.AlignTop
                                        padding: Kirigami.Units.smallSpacing
                                        visible: root.showDayIndicator
                                        color: gridItem.isToday ? Kirigami.Theme.highlightColor : (!gridItem.isCurrentMonth ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor)
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

                            ListView {
                                Layout.fillWidth: true
                                id: linesRepeater

                                model: incidences
                                onCountChanged: {
                                    root.numberOfLinesShown = count
                                }

                                delegate: Item {
                                    id: line
                                    height: Kirigami.Units.gridUnit
                                    width: parent.width

                                    //Incidences
                                    Repeater {
                                        id: incidencesRepeater
                                        model: modelData
                                        Rectangle {
                                            x: (root.dayWidth + 1) * modelData.starts // +1 because of the spacing
                                            y: 0
                                            width: root.dayWidth * modelData.duration
                                            height: parent.height

                                            radius: 2

                                            Rectangle {
                                                anchors.fill: parent
                                                color: modelData.color
                                                radius: 2
                                                border.width: 1
                                                border.color: Kirigami.Theme.alternateBackgroundColor
                                                opacity: 0.6
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
                                                }

                                                QQC2.Label {
                                                    Layout.fillWidth: true
                                                    text: modelData.text
                                                    elide: Text.ElideRight
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
