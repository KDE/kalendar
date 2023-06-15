// Copyright (C) 2018 Michael Bohlender, <bohlender@kolabsys.com>
// Copyright (C) 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar.calendar 1.0 as Kalendar
import org.kde.kalendar.utils 1.0
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Item {
    id: root

    property var openOccurrence

    property int daysToShow: daysPerRow * 6
    property int daysPerRow: 7
    property double weekHeaderWidth: Kalendar.Config.showWeekNumbers ? Kirigami.Units.gridUnit * 1.5 : 0

    readonly property date currentDate: Kalendar.DateTimeState.currentDate
    // Getting the components once makes this faster when we need them repeatedly
    readonly property int currentDay: currentDate.getDate()
    readonly property int currentMonth: currentDate.getMonth()
    readonly property int currentYear:currentDate.getFullYear()

    property date firstDayOfMonth: DateUtils.getFirstDayOfMonth(currentDate)
    property date startDate: DateUtils.getFirstDayOfWeek(firstDayOfMonth)
    readonly property int month: firstDayOfMonth.getMonth()

    property bool paintGrid: true
    property bool showDayIndicator: true
    property Component dayHeaderDelegate
    property Component weekHeaderDelegate
    property alias bgLoader: backgroundLoader.item
    property bool isCurrentView: true
    property bool dragDropEnabled: true

    readonly property alias foregroundLoader: foregroundLoader

    //Internal
    property int numberOfLinesShown: 0
    property int numberOfRows: (daysToShow / daysPerRow)
    property int dayWidth: Kalendar.Config.showWeekNumbers ?
        ((width - weekHeaderWidth) / daysPerRow) - spacing : // No spacing on right, spacing in between weekheader and monthgrid
        (width - weekHeaderWidth - (spacing * (daysPerRow - 1))) / daysPerRow // No spacing on left or right of month grid when no week header
    property int dayHeight: ((height - bgLoader.dayLabelsBar.height) / numberOfRows) - spacing
    property int spacing: Kalendar.Config.monthGridBorderWidth // Between grid squares in background
    property int listViewSpacing: root.dayWidth < (Kirigami.Units.gridUnit * 5 + Kirigami.Units.smallSpacing * 2) ?
        Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing // Between lines of incidences ( ====== <- )
    readonly property bool isDark: KalendarUiUtils.darkMode
    readonly property int mode: Kalendar.CalendarApplication.Event

    implicitHeight: (numberOfRows > 1 ? Kirigami.Units.gridUnit * 10 * numberOfRows : numberOfLinesShown * Kirigami.Units.gridUnit) + bgLoader.dayLabelsBar.height
    height: implicitHeight

    Kirigami.Separator {
        id: gridBackground
        anchors {
            fill: parent
            topMargin: root.bgLoader.dayLabelsBar.height
        }
        visible: backgroundLoader.status === Loader.Ready
    }

    // Background
    Loader {
        id: backgroundLoader
        anchors.fill: parent
        asynchronous: !root.isCurrentView
        sourceComponent: Column {
            id: rootBackgroundColumn

            property alias dayLabelsBar: dayLabelsBarComponent

            spacing: root.spacing
            anchors.fill: parent

            DayLabelsBar {
                id: dayLabelsBarComponent

                delegate: root.dayHeaderDelegate
                startDate: root.startDate
                dayWidth: root.dayWidth
                daysToShow: root.daysPerRow
                spacing: root.spacing

                anchors {
                    leftMargin: Kalendar.Config.showWeekNumbers ? weekHeaderWidth + root.spacing : 0
                    left: parent.left
                    right: parent.right
                }
            }

            Repeater {
                model: root.numberOfRows

                //One row => one week
                Item {
                    id: weekRow

                    required property int index

                    width: parent.width
                    height: root.dayHeight
                    clip: true

                    RowLayout {
                        width: weekRow.width
                        height: weekRow.height
                        spacing: root.spacing

                        Loader {
                            id: weekHeader

                            property date startDate: DateUtils.addDaysToDate(root.startDate, weekRow.index * 7)

                            sourceComponent: root.weekHeaderDelegate
                            active: Kalendar.Config.showWeekNumbers
                            visible: Kalendar.Config.showWeekNumbers

                            Layout.preferredWidth: weekHeaderWidth
                            Layout.fillHeight: true
                        }

                        Item {
                            id: dayDelegate

                            property date startDate: DateUtils.addDaysToDate(root.startDate, index * 7)

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Row {
                                id: grid

                                spacing: root.spacing
                                height: parent.height

                                Repeater {
                                    id: gridRepeater
                                    model: root.daysPerRow

                                    Item {
                                        id: gridItem

                                        required property var modelData

                                        readonly property date gridSquareDate: date
                                        readonly property date date: DateUtils.addDaysToDate(dayDelegate.startDate, modelData)
                                        readonly property int day: date.getDate()
                                        readonly property int month: date.getMonth()
                                        readonly property int year: date.getFullYear()
                                        readonly property bool isToday: day === root.currentDay && month === root.currentMonth && year === root.currentYear
                                        readonly property bool isCurrentMonth: month === root.month

                                        height: root.dayHeight
                                        width: root.dayWidth

                                        Rectangle {
                                            id: backgroundRectangle
                                            anchors.fill: parent
                                            color: incidenceDropArea.containsDrag ?  Kirigami.Theme.positiveBackgroundColor :
                                                gridItem.isToday ? Kirigami.Theme.activeBackgroundColor :
                                                gridItem.isCurrentMonth ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                                            Kirigami.Theme.inherit: false
                                            Kirigami.Theme.colorSet: Kirigami.Theme.View

                                            DayMouseArea {
                                                id: backgroundDayMouseArea
                                                anchors.fill: parent
                                                addDate: gridItem.date
                                                onAddNewIncidence: KalendarUiUtils.setUpAdd(type, addDate)
                                                onDeselect: KalendarUiUtils.appMain.incidenceInfoViewer.close()

                                                DropArea {
                                                    id: incidenceDropArea
                                                    anchors.fill: parent
                                                    z: 9999
                                                    onDropped: if(root.isCurrentView) {
                                                        if (DateUtils.sameDay(backgroundDayMouseArea.addDate, drop.source.occurrenceDate)) {
                                                            return;
                                                        }
                                                        const pos = mapToItem(root, backgroundRectangle.x, backgroundRectangle.y);
                                                        drop.source.caughtX = pos.x + root.listViewSpacing;
                                                        drop.source.caughtY = root.showDayIndicator ?
                                                            pos.y + Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 1.5 :
                                                            pos.y;
                                                        drop.source.caught = true;

                                                        const incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar.calendar 1.0; IncidenceWrapper {id: incidence}', incidenceDropArea, "incidence");
                                                        incidenceWrapper.incidenceItem = Kalendar.CalendarManager.incidenceItem(drop.source.incidencePtr);

                                                        let sameTimeOnDate = new Date(backgroundDayMouseArea.addDate);
                                                        sameTimeOnDate = new Date(sameTimeOnDate.setHours(drop.source.occurrenceDate.getHours(), drop.source.occurrenceDate.getMinutes()));
                                                        const offset = sameTimeOnDate.getTime() - drop.source.occurrenceDate.getTime();
                                                        KalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, offset, offset, drop.source.occurrenceDate, drop.source)
                                                    }
                                                }
                                            }
                                        }

                                        // Day number
                                        QQC2.Button {
                                            implicitHeight: dayNumberLayout.implicitHeight

                                            flat: true
                                            visible: root.showDayIndicator
                                            enabled: root.daysToShow > 1
                                            onClicked: KalendarUiUtils.openDayLayer(gridItem.date)

                                            anchors {
                                                top: parent.top
                                                right: parent.right
                                                left: parent.left
                                            }

                                            contentItem: RowLayout {
                                                id: dayNumberLayout
                                                visible: root.showDayIndicator

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
    }

    Loader {
        id: foregroundLoader
        anchors.fill: parent
        asynchronous: !root.isCurrentView

        sourceComponent: Column {
            id: rootForegroundColumn

            spacing: root.spacing

            anchors {
                fill: parent
                topMargin: root.bgLoader.dayLabelsBar.height + root.spacing
                leftMargin: Kalendar.Config.showWeekNumbers ? weekHeaderWidth + root.spacing : 0
            }

            // Weeks
            Repeater {
                model: Kalendar.MultiDayIncidenceModel {
                    periodLength: 7
                    showTodos: Kalendar.Config.showTodosInCalendarViews
                    showSubTodos: Kalendar.Config.showSubtodosInCalendarViews
                    active: root.isCurrentView
                    model: Kalendar.IncidenceOccurrenceModel {
                        start: root.startDate
                        length: root.daysToShow
                        calendar: Kalendar.CalendarManager.calendar
                        filter: Kalendar.Filter
                    }
                }

                // One row => one week
                Item {
                    id: weekDelegate

                    required property int index
                    required property var incidences
                    required property var periodStartDate

                    width: parent.width
                    height: root.dayHeight
                    clip: true

                    RowLayout {
                        width: parent.width
                        height: parent.height
                        spacing: root.spacing
                        Item {
                            id: dayDelegate

                            readonly property date startDate: weekDelegate.periodStartDate

                            Layout.fillWidth: true
                            Layout.fillHeight: true

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

                                clip: true
                                spacing: root.listViewSpacing

                                QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

                                onCountChanged: {
                                    root.numberOfLinesShown = count
                                }

                                model: weekDelegate.incidences
                                delegate: Item {
                                    id: line

                                    required property var modelData

                                    height: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing
                                    width: ListView.view.width

                                    // Incidences
                                    Repeater {
                                        id: incidencesRepeater

                                        model: line.modelData
                                        delegate: DayGridViewIncidenceDelegate {
                                            id: incidenceDelegate

                                            required property var modelData

                                            starts: incidenceDelegate.modelData.starts
                                            duration: incidenceDelegate.modelData.duration
                                            incidenceId: incidenceDelegate.modelData.incidenceId
                                            occurrenceDate: incidenceDelegate.modelData.startTime
                                            occurrenceEndDate: incidenceDelegate.modelData.endTime
                                            incidencePtr: incidenceDelegate.modelData.incidencePtr
                                            allDay: incidenceDelegate.modelData.allDay
                                            isDark: root.isDark

                                            dayWidth: root.dayWidth
                                            height: line.height
                                            parentViewSpacing: root.spacing
                                            horizontalSpacing: linesRepeater.spacing
                                            openOccurrenceId: root.openOccurrence ? root.openOccurrence.incidenceId : ""
                                            dragDropEnabled: root.dragDropEnabled
                                        }
                                    }
                                }

                                DayMouseArea {
                                    id: listViewMenu
                                    anchors.fill: parent
                                    z: -1

                                    function useGridSquareDate(type, root, globalPosition) {
                                        for (const i in root.children) {
                                            const child = root.children[i];
                                            const localPosition = child.mapFromGlobal(globalPosition.x, globalPosition.y);

                                            if(child.contains(localPosition) && child.gridSquareDate) {
                                                KalendarUiUtils.setUpAdd(type, child.gridSquareDate);
                                            } else {
                                                useGridSquareDate(type, child, globalPosition);
                                            }
                                        }
                                    }

                                    onAddNewIncidence: useGridSquareDate(type, applicationWindow().contentItem, this.mapToGlobal(clickX, clickY))
                                    onDeselect: KalendarUiUtils.appMain.incidenceInfoViewer.close()
                                }

                            }
                        }
                    }
                }
            }
        }
    }
}
