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
    signal deselect()
    signal moveIncidence(int startOffset, date occurrenceDate, var incidenceWrapper, Item caughtDelegate)

    property var openOccurrence
    property var model

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
    property bool paintGrid: true
    property bool showDayIndicator: true
    property Component dayHeaderDelegate
    property Component weekHeaderDelegate
    property int month
    property alias bgLoader: backgroundLoader.item
    property bool isCurrentView: true

    //Internal
    property int numberOfLinesShown: 0
    property int numberOfRows: (daysToShow / daysPerRow)
    property var dayHeight: ((height - bgLoader.dayLabels.height) / numberOfRows) - spacing
    property real spacing: Kalendar.Config.monthGridBorderWidth // Between grid squares in background
    property real listViewSpacing: root.dayWidth < (Kirigami.Units.gridUnit * 5 + Kirigami.Units.smallSpacing * 2) ?
        Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing // Between lines of incidences ( ====== <- )
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    implicitHeight: (numberOfRows > 1 ? Kirigami.Units.gridUnit * 10 * numberOfRows : numberOfLinesShown * Kirigami.Units.gridUnit) + bgLoader.dayLabels.height
    height: implicitHeight

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
                                            id: backgroundRectangle
                                            anchors.fill: parent
                                            Kirigami.Theme.inherit: false
                                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                                            color: incidenceDropArea.containsDrag ?  Kirigami.Theme.positiveBackgroundColor :
                                                gridItem.isToday ? Kirigami.Theme.activeBackgroundColor :
                                                gridItem.isCurrentMonth ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                                            DayMouseArea {
                                                id: backgroundDayMouseArea
                                                anchors.fill: parent
                                                addDate: gridItem.date
                                                onAddNewIncidence: addIncidence(type, addDate)
                                                onDeselect: root.deselect()

                                                DropArea {
                                                    id: incidenceDropArea
                                                    anchors.fill: parent
                                                    z: 9999
                                                    onDropped: if(root.isCurrentView) {
                                                        const pos = mapToItem(root, backgroundRectangle.x, backgroundRectangle.y);
                                                        drop.source.caughtX = pos.x + root.listViewSpacing;
                                                        drop.source.caughtY = root.showDayIndicator ?
                                                            pos.y + Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 1.5 :
                                                            pos.y;
                                                        drop.source.caught = true;

                                                        const incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', incidenceDropArea, "incidence");
                                                        incidenceWrapper.incidencePtr = drop.source.incidencePtr;
                                                        incidenceWrapper.collectionId = drop.source.collectionId;

                                                        let sameTimeOnDate = new Date(backgroundDayMouseArea.addDate);
                                                        sameTimeOnDate = new Date(sameTimeOnDate.setHours(drop.source.occurrenceDate.getHours(), drop.source.occurrenceDate.getMinutes()));
                                                        const offset = sameTimeOnDate.getTime() - drop.source.occurrenceDate.getTime();
                                                        root.moveIncidence(offset, drop.source.occurrenceDate, incidenceWrapper, drop.source);
                                                    }
                                                }
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
                                                renderType: Text.QtRendering
                                                color: Kirigami.Theme.highlightColor
                                                visible: gridItem.isToday && gridItem.width > Kirigami.Units.gridUnit * 5
                                            }
                                            QQC2.Label {
                                                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                                text: gridItem.date.toLocaleDateString(Qt.locale(), gridItem.day == 1 ?
                                                "d MMM" : "d")
                                                renderType: Text.QtRendering
                                                padding: Kirigami.Units.smallSpacing
                                                visible: root.showDayIndicator
                                                color: gridItem.isToday ?
                                                    Kirigami.Theme.highlightColor :
                                                    (!gridItem.isCurrentMonth ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor)
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
            model: root.model
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

                        ListView {
                            id: linesRepeater

                            anchors {
                                fill: parent
                                // Offset for date
                                topMargin: root.showDayIndicator ? Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 1.5 : 0
                                rightMargin: spacing
                            }

                            // DO NOT use a ScrollView as a bug causes this to crash randomly.
                            // So we instead make the ListView act like a ScrollView on desktop. No crashing now!
                            flickableDirection: Flickable.VerticalFlick
                            boundsBehavior: Kirigami.Settings.isMobile ? Flickable.DragAndOvershootBounds : Flickable.StopAtBounds
                            QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

                            clip: true
                            spacing: root.listViewSpacing

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
                                onDeselect: root.deselect()
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

                                    MultiDayViewIncidenceDelegate {
                                        id: incidenceDelegate
                                        dayWidth: root.dayWidth
                                        height: line.height
                                        parentViewSpacing: root.spacing
                                        horizontalSpacing: linesRepeater.spacing
                                        openOccurrenceId: root.openOccurrence ? root.openOccurrence.incidenceId : ""
                                        isDark: root.isDark
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
