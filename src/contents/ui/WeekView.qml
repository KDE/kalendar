// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import QtGraphicalEffects 1.12

import org.kde.kalendar 1.0 as Kalendar
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Kirigami.Page {
    id: root

    signal addIncidence(int type, date addDate, bool includeTime)
    signal viewIncidence(var modelData, var collectionData)
    signal editIncidence(var incidencePtr, var collectionId)
    signal deleteIncidence(var incidencePtr, date deleteDate)
    signal completeTodo(var incidencePtr)
    signal addSubTodo(var parentWrapper)

    property var openOccurrence: {}
    property var filter: {
        "tags": []
    }
    property date selectedDate: new Date()
    property date startDate: DateUtils.getFirstDayOfMonth(selectedDate)
    property date currentDate: new Date() // Needs to get updated for marker to move, done from main.qml
    readonly property int currentDay: currentDate ? currentDate.getDate() : null
    readonly property int currentMonth: currentDate ? currentDate.getMonth() : null
    readonly property int currentYear: currentDate ? currentDate.getFullYear() : null
    property int day: selectedDate.getDate()
    property int month: selectedDate.getMonth()
    property int year: selectedDate.getFullYear()
    property bool initialWeek: true
    property int daysToShow: 7
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    property real scrollbarWidth: 0
    readonly property real dayWidth: ((root.width - hourLabelWidth - leftPadding - scrollbarWidth) / daysToShow) - gridLineWidth
    readonly property real incidenceSpacing: Kirigami.Units.smallSpacing / 2
    readonly property real gridLineWidth: 1.0
    readonly property real hourLabelWidth: Kirigami.Units.gridUnit * 3.5

    property var hourStrings: []
    Component.onCompleted: {
        const date = new Date(0, 0, 0, 0, 0, 0, 0);
        for(let i = 0; i < 23; i++) {
            date.setHours(i);
            hourStrings.push(date.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat));
            hourStringsChanged();
        }
    }

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
    }

    function setToDate(date, isInitialWeek = false) {
        root.initialWeek = isInitialWeek;
        date = DateUtils.getFirstDayOfWeek(date);
        const weekDiff = Math.round((date - pathView.currentItem.startDate) / (root.daysToShow * 24 * 60 * 60 * 1000));

        let newIndex = pathView.currentIndex + weekDiff;
        let firstItemDate = pathView.model.data(pathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
        let lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);

        while(firstItemDate >= date) {
            pathView.model.datesToAdd = 600;
            pathView.model.addDates(false)
            firstItemDate = pathView.model.data(pathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
            newIndex = 0;
        }
        if(firstItemDate < date && newIndex === 0) {
            newIndex = Math.round((date - firstItemDate) / (root.daysToShow * 24 * 60 * 60 * 1000)) + 1
        }

        while(lastItemDate <= date) {
            pathView.model.datesToAdd = 600;
            pathView.model.addDates(true)
            lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
        }
        pathView.currentIndex = newIndex;
        selectedDate = date;
    }
    readonly property Kirigami.Action previousAction: Kirigami.Action {
        icon.name: "go-previous"
        text: i18n("Previous Week")
        shortcut: "Left"
        onTriggered: setToDate(DateUtils.addDaysToDate(pathView.currentItem.startDate, -root.daysToShow))
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action nextAction: Kirigami.Action {
        icon.name: "go-next"
        text: i18n("Next Week")
        shortcut: "Right"
        onTriggered: setToDate(DateUtils.addDaysToDate(pathView.currentItem.startDate, root.daysToShow))
        displayHint: Kirigami.DisplayHint.IconOnly
    }

    actions {
        left: Qt.application.layoutDirection === Qt.RightToLeft ? nextAction : previousAction
        right: Qt.application.layoutDirection === Qt.RightToLeft ? previousAction : nextAction
        main: Kirigami.Action {
            icon.name: "go-jump-today"
            text: i18n("Today")
            onTriggered: setToDate(new Date())
        }
    }

    padding: 0

    PathView {
        id: pathView

        anchors.fill: parent
        flickDeceleration: Kirigami.Units.longDuration
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        snapMode: PathView.SnapToItem
        focus: true
        interactive: Kirigami.Settings.tabletMode

        path: Path {
            startX: - pathView.width * pathView.count / 2 + pathView.width / 2
            startY: pathView.height / 2
            PathLine {
                x: pathView.width * pathView.count / 2 + pathView.width / 2
                y: pathView.height / 2
            }
        }

        model: Kalendar.InfiniteCalendarViewModel {
            scale: Kalendar.InfiniteCalendarViewModel.WeekScale
        }

        property date dateToUse
        property int startIndex
        Component.onCompleted: {
            startIndex = count / 2;
            currentIndex = startIndex;
        }
        onCurrentIndexChanged: {
            root.startDate = currentItem.startDate;
            root.month = currentItem.month;
            root.year = currentItem.year;
            root.initialWeek = false;

            if(currentIndex >= count - 2) {
                model.addDates(true);
            } else if (currentIndex <= 1) {
                model.addDates(false);
                startIndex += model.weeksToAdd;
            }
        }

        delegate: Loader {
            id: viewLoader

            property date startDate: model.startDate
            property int month: model.selectedMonth - 1 // Convert QDateTime month to JS month
            property int year: model.selectedYear

            property int index: model.index
            property bool isCurrentItem: PathView.isCurrentItem
            property bool isNextOrCurrentItem: index >= pathView.currentIndex -1 && index <= pathView.currentIndex + 1

            Loader {
                id: modelLoader
                active: viewLoader.isNextOrCurrentItem
                asynchronous: true
                sourceComponent: Kalendar.HourlyIncidenceModel {
                    id: hourlyModel
                    filters: Kalendar.HourlyIncidenceModel.NoAllDay | Kalendar.HourlyIncidenceModel.NoMultiDay
                    model: Kalendar.IncidenceOccurrenceModel {
                        id: occurrenceModel
                        objectName: "incidenceOccurrenceModel"
                        start: viewLoader.startDate
                        length: root.daysToShow
                        filter: root.filter ? root.filter : {}
                        calendar: Kalendar.CalendarManager.calendar
                    }
                }
            }

            active: isNextOrCurrentItem
            //asynchronous: true
            sourceComponent: ColumnLayout {
                width: pathView.width
                height: pathView.height
                spacing: 0

                Row {
                    Layout.fillWidth: true
                    spacing: root.gridLineWidth

                    Kirigami.Heading {
                        id: weekNumberHeading

                        width: root.hourLabelWidth - root.gridLineWidth
                        horizontalAlignment: Text.AlignRight
                        padding: Kirigami.Units.smallSpacing
                        level: 2
                        text: DateUtils.getWeek(viewLoader.startDate, Qt.locale().firstDayOfWeek)
                        color: Kirigami.Theme.disabledTextColor
                        background: Rectangle {
                            color: Kirigami.Theme.backgroundColor
                        }
                    }

                    Repeater {
                        id: dayHeadings

                        model: modelLoader.item.rowCount()
                        delegate: Kirigami.Heading {
                            id: dayHeading

                            FontMetrics {
                                id: dayTitleMetrics
                            }

                            property date headingDate: DateUtils.addDaysToDate(viewLoader.startDate, index)
                            property bool isToday: headingDate.getDate() === root.currentDay &&
                                                   headingDate.getMonth() === root.currentMonth &&
                                                   headingDate.getFullYear() === root.currentYear
                            width: root.dayWidth
                            horizontalAlignment: Text.AlignRight
                            padding: Kirigami.Units.smallSpacing
                            level: 2
                            color: isToday ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                            text: {
                                const longText = headingDate.toLocaleDateString(Qt.locale(), "dddd <b>dd</b>");
                                const mediumText = headingDate.toLocaleDateString(Qt.locale(), "ddd <b>dd</b>");
                                const shortText = mediumText.slice(0,1) + " " + headingDate.toLocaleDateString(Qt.locale(), "<b>dd</b>");


                                if(dayTitleMetrics.boundingRect(longText).width < width) {
                                    return longText;
                                } else if(dayTitleMetrics.boundingRect(mediumText).width < width) {
                                    return mediumText;
                                } else {
                                    return shortText;
                                }
                            }
                            background: Rectangle {
                                color: dayHeading.isToday ? Kirigami.Theme.activeBackgroundColor : Kirigami.Theme.backgroundColor
                            }
                        }
                    }
                }

                Kirigami.Separator {
                    id: headerTopSeparator
                    Layout.fillWidth: true
                    height: root.gridLineWidth
                    z: -1

                    RectangularGlow {
                        anchors.fill: parent
                        z: -1
                        glowRadius: 5
                        spread: 0.3
                        color: Qt.rgba(0.0, 0.0, 0.0, 0.15)
                        visible: !allDayViewLoader.active
                    }
                }

                Loader {
                    id: allDayIncidenceModelLoader
                    asynchronous: true
                    sourceComponent: Kalendar.MultiDayIncidenceModel {
                        periodLength: root.daysToShow
                        filters: Kalendar.MultiDayIncidenceModel.AllDayOnly | Kalendar.MultiDayIncidenceModel.MultiDayOnly
                        model: Kalendar.IncidenceOccurrenceModel {
                            id: occurrenceModel
                            objectName: "incidenceOccurrenceModel"
                            start: viewLoader.startDate
                            length: root.daysToShow
                            filter: root.filter ? root.filter : {}
                            calendar: Kalendar.CalendarManager.calendar
                        }
                    }
                }

                Item {
                    id: allDayHeader
                    Layout.fillWidth: true
                    height: allDayViewLoader.implicitHeight
                    visible: allDayViewLoader.active
                    clip: true

                    Rectangle {
                        id: headerBackground
                        anchors.fill: parent
                        color: Kirigami.Theme.backgroundColor
                    }

                    QQC2.Label {
                        width: root.hourLabelWidth
                        padding: Kirigami.Units.smallSpacing
                        leftPadding: Kirigami.Units.largeSpacing
                        verticalAlignment: Text.AlignTop
                        horizontalAlignment: Text.AlignRight
                        text: i18n("Multi / All day")
                        wrapMode: Text.Wrap
                        color: Kirigami.Theme.disabledTextColor
                    }

                    Loader {
                        id: allDayViewLoader
                        anchors.fill: parent
                        anchors.leftMargin: root.hourLabelWidth
                        active: allDayIncidenceModelLoader.item.incidenceCount > 0
                        sourceComponent: Item {
                            implicitHeight: Kirigami.Units.gridUnit * 3
                            clip: true

                            Repeater {
                                model: allDayIncidenceModelLoader.item
                                Layout.topMargin: Kirigami.Units.largeSpacing
                                //One row => one week
                                Item {
                                    width: parent.width
                                    height: Kirigami.Units.gridUnit * 3
                                    clip: true
                                    RowLayout {
                                        width: parent.width
                                        height: parent.height
                                        spacing: root.gridLineWidth
                                        Item {
                                            id: dayDelegate
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            readonly property date startDate: periodStartDate

                                            QQC2.ScrollView {
                                                id: linesListViewScrollView
                                                anchors {
                                                    fill: parent
                                                }

                                                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                                                ListView {
                                                    id: linesRepeater
                                                    Layout.fillWidth: true
                                                    Layout.rightMargin: spacing

                                                    clip: true
                                                    spacing: root.incidenceSpacing

                                                    ListView {
                                                        id: allDayIncidencesBackgroundView
                                                        anchors.fill: parent
                                                        spacing: root.gridLineWidth
                                                        orientation: Qt.Horizontal
                                                        z: -1

                                                        Kirigami.Separator {
                                                            anchors.fill: parent
                                                            anchors.rightMargin: root.scrollbarWidth
                                                            z: -1
                                                        }

                                                        model: root.daysToShow
                                                        delegate: Rectangle {
                                                            id: multiDayViewBackground

                                                            readonly property date date: DateUtils.addDaysToDate(viewLoader.startDate, index)
                                                            readonly property bool isToday: date.getDate() === root.currentDay &&
                                                                date.getMonth() === root.currentMonth &&
                                                                date.getFullYear() === root.currentYear

                                                            width: root.dayWidth
                                                            height: linesListViewScrollView.height
                                                            color: isToday ? Kirigami.Theme.activeBackgroundColor : Kirigami.Theme.backgroundColor

                                                            DayMouseArea {
                                                                id: listViewMenu
                                                                anchors.fill: parent

                                                                addDate: parent.date
                                                                onAddNewIncidence: root.addIncidence(type, addDate, false)
                                                            }
                                                        }
                                                    }

                                                    model: incidences

                                                    delegate: Item {
                                                        id: line
                                                        height: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing

                                                        //Incidences
                                                        Repeater {
                                                            id: incidencesRepeater
                                                            model: modelData
                                                            MultiDayViewIncidenceDelegate {
                                                                dayWidth: root.dayWidth
                                                                parentViewSpacing: root.gridLineWidth
                                                                horizontalSpacing: linesRepeater.spacing
                                                                openOccurrenceId: root.openOccurrence ? root.openOccurrence.incidenceId : ""
                                                                isDark: root.isDark
                                                                reactToCurrentMonth: false
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

                Kirigami.Separator {
                    id: headerBottomSeparator
                    Layout.fillWidth: true
                    height: root.gridLineWidth
                    z: -1
                    visible: allDayViewLoader.active

                    RectangularGlow {
                        anchors.fill: parent
                        z: -1
                        glowRadius: 5
                        spread: 0.3
                        color: Qt.rgba(0.0, 0.0, 0.0, 0.15)
                    }
                }


                QQC2.ScrollView {
                    id: hourlyView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: availableWidth
                    z: -2
                    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                    readonly property real periodsPerHour: 60 / modelLoader.item.periodLength
                    readonly property real daySections: (60 * 24) / modelLoader.item.periodLength
                    readonly property real dayHeight: (daySections * Kirigami.Units.gridUnit) + (root.gridLineWidth * 23)
                    readonly property real hourHeight: periodsPerHour * Kirigami.Units.gridUnit
                    readonly property real minuteHeight: hourHeight / 60

                    Connections {
                        target: hourlyView.QQC2.ScrollBar.vertical
                        function onWidthChanged() {
                            if(!Kirigami.Settings.isMobile) root.scrollbarWidth = hourlyView.QQC2.ScrollBar.vertical.width;
                        }
                    }
                    Component.onCompleted: if(!Kirigami.Settings.isMobile) root.scrollbarWidth = hourlyView.QQC2.ScrollBar.vertical.width

                    Item {
                        id: hourlyViewContents
                        width: parent.width
                        implicitHeight: hourlyView.dayHeight

                        clip: true

                        ListView {
                            id: hourLabelsColumn
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.topMargin: (fontMetrics.height / 2) + (root.gridLineWidth / 2)
                            spacing: root.gridLineWidth
                            width: root.hourLabelWidth
                            boundsBehavior: Flickable.StopAtBounds

                            FontMetrics {
                                id: fontMetrics
                            }

                            model: root.hourStrings
                            delegate: QQC2.Label {
                                height: (Kirigami.Units.gridUnit * hourlyView.periodsPerHour)
                                width: root.hourLabelWidth
                                rightPadding: Kirigami.Units.smallSpacing
                                verticalAlignment: Text.AlignBottom
                                horizontalAlignment: Text.AlignRight
                                text: modelData
                                color: Kirigami.Theme.disabledTextColor
                            }
                        }

                        Item {
                            id: innerWeekView
                            anchors {
                                left: hourLabelsColumn.right
                                top: parent.top
                                bottom: parent.bottom
                                right: parent.right
                            }
                            clip: true
                            DragHandler { }

                            Kirigami.Separator {
                                anchors.fill: parent
                            }

                            ListView {
                                anchors.fill: parent
                                spacing: root.gridLineWidth
                                orientation: Qt.Horizontal
                                model: modelLoader.item

                                boundsBehavior: Flickable.StopAtBounds

                                delegate: Item {
                                    id: dayColumn

                                    readonly property int index: model.index
                                    readonly property date columnDate: DateUtils.addDaysToDate(viewLoader.startDate, index)
                                    readonly property bool isToday: columnDate.getDate() === root.currentDay &&
                                        columnDate.getMonth() === root.currentMonth &&
                                        columnDate.getFullYear() === root.currentYear

                                    width: root.dayWidth
                                    height: hourlyView.dayHeight
                                    clip: true

                                    ListView {
                                        anchors.fill: parent
                                        spacing: root.gridLineWidth
                                        boundsBehavior: Flickable.StopAtBounds

                                        model: 24
                                        delegate: Rectangle {
                                            width: parent.width
                                            height: hourlyView.hourHeight
                                            color: dayColumn.isToday ? Kirigami.Theme.activeBackgroundColor : Kirigami.Theme.backgroundColor

                                            DayMouseArea {
                                                anchors.fill: parent
                                                addDate: new Date(DateUtils.addDaysToDate(viewLoader.startDate, dayColumn.index).setHours(index))
                                                onAddNewIncidence: addIncidence(type, addDate, true)
                                            }
                                        }
                                    }

                                    Repeater {
                                        id: incidencesRepeater
                                        model: incidences
                                        delegate: Rectangle {
                                            readonly property real gridLineYCompensation: (modelData.starts / hourlyView.periodsPerHour) * root.gridLineWidth
                                            readonly property real gridLineHeightCompensation: (modelData.duration / hourlyView.periodsPerHour) * root.gridLineWidth
                                            readonly property bool isOpenOccurrence: root.openOccurrence ?
                                                root.openOccurrence.incidenceId === modelData.incidenceId : false

                                            x: root.incidenceSpacing + (modelData.priorTakenWidthShare * root.dayWidth)
                                            y: (modelData.starts * Kirigami.Units.gridUnit) + root.incidenceSpacing + gridLineYCompensation
                                            width: (root.dayWidth * modelData.widthShare) - (root.incidenceSpacing * 2)
                                            height: (modelData.duration * Kirigami.Units.gridUnit) - (root.incidenceSpacing * 2) + gridLineHeightCompensation - root.gridLineWidth
                                            radius: Kirigami.Units.smallSpacing
                                            color: Qt.rgba(0,0,0,0)
                                            visible: !modelData.allDay

                                            IncidenceBackground {
                                                id: incidenceBackground
                                                isOpenOccurrence: parent.isOpenOccurrence
                                                isDark: root.isDark
                                            }

                                            ColumnLayout {
                                                id: incidenceContents

                                                readonly property color textColor: LabelUtils.getIncidenceLabelColor(modelData.color, root.isDark)

                                                anchors {
                                                    fill: parent
                                                    leftMargin: Kirigami.Units.smallSpacing
                                                    rightMargin: Kirigami.Units.smallSpacing
                                                    topMargin: Kirigami.Units.smallSpacing
                                                    bottomMargin: Kirigami.Units.smallSpacing
                                                }

                                                QQC2.Label {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    text: modelData.text
                                                    horizontalAlignment: Text.AlignLeft
                                                    verticalAlignment: Text.AlignTop
                                                    wrapMode: Text.Wrap
                                                    elide: Text.ElideRight
                                                    font.weight: Font.Medium
                                                    color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                    incidenceContents.textColor
                                                }

                                                RowLayout {
                                                    width: parent.width
                                                    visible: parent.height > Kirigami.Units.gridUnit * 3
                                                    Kirigami.Icon {
                                                        id: incidenceIcon
                                                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                                        source: modelData.incidenceTypeIcon
                                                        isMask: true
                                                        color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                            incidenceContents.textColor
                                                        visible: parent.width > Kirigami.Units.gridUnit * 4
                                                    }
                                                    QQC2.Label {
                                                        id: timeLabel
                                                        Layout.fillWidth: true
                                                        horizontalAlignment: Text.AlignRight
                                                        text: modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat) + " - " + modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat)
                                                        wrapMode: Text.Wrap
                                                        color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                            incidenceContents.textColor
                                                        visible: parent.width > Kirigami.Units.gridUnit * 3
                                                    }
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

                            Rectangle {
                                id: currentTimeMarker
                                property date currentDateTime: root.currentDate
                                readonly property int minutesFromStart: (currentDateTime.getHours() * 60) + currentDateTime.getMinutes()
                                readonly property int daysFromWeekStart: DateUtils.fullDaysBetweenDates(viewLoader.startDate, currentDateTime) - 1

                                width: root.dayWidth
                                height: root.gridLineWidth * 2
                                color: Kirigami.Theme.highlightColor
                                x: (daysFromWeekStart * root.dayWidth) + (daysFromWeekStart * root.gridLineWidth)
                                y: (currentDateTime.getHours() * root.gridLineWidth) + (hourlyView.minuteHeight * minutesFromStart) - (height / 2)
                                z: 100
                                visible: currentDateTime >= viewLoader.startDate && daysFromWeekStart < root.daysToShow

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.topMargin: -(height / 2) + (parent.height / 2)
                                    width: height
                                    height: parent.height * 5
                                    radius: 100
                                    color: Kirigami.Theme.highlightColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
