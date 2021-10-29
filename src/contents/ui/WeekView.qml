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
    property date currentDate: new Date() // Needs to get updated for marker to move, done from main.qml
    readonly property int currentDay: currentDate ? currentDate.getDate() : null
    readonly property int currentMonth: currentDate ? currentDate.getMonth() : null
    readonly property int currentYear: currentDate ? currentDate.getFullYear() : null
    property int day: selectedDate.getDate()
    readonly property real dayWidth: ((root.width - hourLabelWidth - leftPadding - scrollbarWidth) / daysToShow) - gridLineWidth
    property int daysToShow: 7
    property var filter: {
        "tags": []
    }
    readonly property real gridLineWidth: 1.0
    readonly property real hourLabelWidth: Kirigami.Units.gridUnit * 3.5
    property var hourStrings: []
    readonly property real incidenceSpacing: Kirigami.Units.smallSpacing / 2
    property bool initialWeek: true
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)
    property int month: selectedDate.getMonth()
    readonly property Kirigami.Action nextAction: Kirigami.Action {
        displayHint: Kirigami.DisplayHint.IconOnly
        icon.name: "go-next"
        shortcut: "Right"
        text: i18n("Next Week")

        onTriggered: setToDate(DateUtils.addDaysToDate(pathView.currentItem.startDate, root.daysToShow))
    }
    property var openOccurrence: {
    }
    readonly property Kirigami.Action previousAction: Kirigami.Action {
        displayHint: Kirigami.DisplayHint.IconOnly
        icon.name: "go-previous"
        shortcut: "Left"
        text: i18n("Previous Week")

        onTriggered: setToDate(DateUtils.addDaysToDate(pathView.currentItem.startDate, -root.daysToShow))
    }
    property real scrollbarWidth: 0
    property date selectedDate: new Date()
    property date startDate: DateUtils.getFirstDayOfMonth(selectedDate)
    readonly property Kirigami.Action todayAction: Kirigami.Action {
        icon.name: "go-jump-today"
        text: i18n("Today")

        onTriggered: setToDate(new Date())
    }
    property int year: selectedDate.getFullYear()

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false
    padding: 0

    signal addIncidence(int type, date addDate, bool includeTime)
    signal addSubTodo(var parentWrapper)
    signal completeTodo(var incidencePtr)
    signal deleteIncidence(var incidencePtr, date deleteDate)
    signal deselect
    signal editIncidence(var incidencePtr, var collectionId)
    function setToDate(date, isInitialWeek = false) {
        root.initialWeek = isInitialWeek;
        date = DateUtils.getFirstDayOfWeek(date);
        const weekDiff = Math.round((date - pathView.currentItem.startDate) / (root.daysToShow * 24 * 60 * 60 * 1000));
        let newIndex = pathView.currentIndex + weekDiff;
        let firstItemDate = pathView.model.data(pathView.model.index(1, 0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
        let lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1, 0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
        while (firstItemDate >= date) {
            pathView.model.datesToAdd = 600;
            pathView.model.addDates(false);
            firstItemDate = pathView.model.data(pathView.model.index(1, 0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
            newIndex = 0;
        }
        if (firstItemDate < date && newIndex === 0) {
            newIndex = Math.round((date - firstItemDate) / (root.daysToShow * 24 * 60 * 60 * 1000)) + 1;
        }
        while (lastItemDate <= date) {
            pathView.model.datesToAdd = 600;
            pathView.model.addDates(true);
            lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1, 0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
        }
        pathView.currentIndex = newIndex;
        selectedDate = date;
    }
    signal viewIncidence(var modelData, var collectionData)

    Component.onCompleted: {
        // Start at 01:00 and add hours up to 23:00
        const date = new Date(1, 1, 1, 1, 0, 0, 0);
        let i = Number(date.toLocaleTimeString(Qt.locale(), "H")[0]);
        if (i > 1) {
            // Work around Javascript's absolutely stupid, insane and infuriating summertime hour handling
            i -= i;
        }
        for (i; i < 24; i++) {
            date.setHours(i);
            hourStrings.push(date.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat));
            hourStringsChanged();
        }
    }

    actions {
        left: Qt.application.layoutDirection === Qt.RightToLeft ? nextAction : previousAction
        main: todayAction
        right: Qt.application.layoutDirection === Qt.RightToLeft ? previousAction : nextAction
    }
    PathView {
        id: pathView
        property date dateToUse
        property int startIndex

        anchors.fill: parent
        flickDeceleration: Kirigami.Units.longDuration
        focus: true
        interactive: Kirigami.Settings.tabletMode
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        snapMode: PathView.SnapToItem

        Component.onCompleted: {
            startIndex = count / 2;
            currentIndex = startIndex;
        }
        onCurrentIndexChanged: {
            root.startDate = currentItem.startDate;
            root.month = currentItem.month;
            root.year = currentItem.year;
            root.initialWeek = false;
            if (currentIndex >= count - 2) {
                model.addDates(true);
            } else if (currentIndex <= 1) {
                model.addDates(false);
                startIndex += model.weeksToAdd;
            }
        }

        delegate: Loader {
            id: viewLoader
            property int index: model.index
            property bool isCurrentItem: PathView.isCurrentItem
            property bool isNextOrCurrentItem: index >= pathView.currentIndex - 1 && index <= pathView.currentIndex + 1
            property int month: model.selectedMonth - 1 // Convert QDateTime month to JS month
            property int multiDayLinesShown: 0
            property date startDate: model.startDate
            property int year: model.selectedYear

            active: isNextOrCurrentItem

            Loader {
                id: modelLoader
                active: viewLoader.isNextOrCurrentItem
                asynchronous: true

                sourceComponent: Kalendar.HourlyIncidenceModel {
                    id: hourlyModel
                    filters: Kalendar.HourlyIncidenceModel.NoAllDay | Kalendar.HourlyIncidenceModel.NoMultiDay

                    model: Kalendar.IncidenceOccurrenceModel {
                        id: occurrenceModel
                        calendar: Kalendar.CalendarManager.calendar
                        filter: root.filter ? root.filter : {}
                        length: root.daysToShow
                        objectName: "incidenceOccurrenceModel"
                        start: viewLoader.startDate
                    }
                }
            }

            //asynchronous: true
            sourceComponent: Column {
                id: viewColumn
                height: pathView.height
                spacing: 0
                width: pathView.width

                Row {
                    id: headingRow
                    spacing: root.gridLineWidth
                    width: pathView.width

                    Kirigami.Heading {
                        id: weekNumberHeading
                        color: Kirigami.Theme.disabledTextColor
                        horizontalAlignment: Text.AlignRight
                        level: 2
                        padding: Kirigami.Units.smallSpacing
                        text: DateUtils.getWeek(viewLoader.startDate, Qt.locale().firstDayOfWeek)
                        width: root.hourLabelWidth - root.gridLineWidth

                        background: Rectangle {
                            color: Kirigami.Theme.backgroundColor
                        }
                    }
                    Repeater {
                        id: dayHeadings
                        model: modelLoader.item.rowCount()

                        delegate: Kirigami.Heading {
                            id: dayHeading
                            property date headingDate: DateUtils.addDaysToDate(viewLoader.startDate, index)
                            property bool isToday: headingDate.getDate() === root.currentDay && headingDate.getMonth() === root.currentMonth && headingDate.getFullYear() === root.currentYear

                            color: isToday ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                            horizontalAlignment: Text.AlignRight
                            level: 2
                            padding: Kirigami.Units.smallSpacing
                            text: {
                                const longText = headingDate.toLocaleDateString(Qt.locale(), "dddd <b>dd</b>");
                                const mediumText = headingDate.toLocaleDateString(Qt.locale(), "ddd <b>dd</b>");
                                const shortText = mediumText.slice(0, 1) + " " + headingDate.toLocaleDateString(Qt.locale(), "<b>dd</b>");
                                if (dayTitleMetrics.boundingRect(longText).width < width) {
                                    return longText;
                                } else if (dayTitleMetrics.boundingRect(mediumText).width < width) {
                                    return mediumText;
                                } else {
                                    return shortText;
                                }
                            }
                            width: root.dayWidth

                            FontMetrics {
                                id: dayTitleMetrics
                            }

                            background: Rectangle {
                                color: dayHeading.isToday ? Kirigami.Theme.activeBackgroundColor : Kirigami.Theme.backgroundColor
                            }
                        }
                    }
                }
                Kirigami.Separator {
                    id: headerTopSeparator
                    height: root.gridLineWidth
                    width: pathView.width
                    z: -1

                    RectangularGlow {
                        anchors.fill: parent
                        color: Qt.rgba(0.0, 0.0, 0.0, 0.15)
                        glowRadius: 5
                        spread: 0.3
                        visible: !allDayViewLoader.active
                        z: -1
                    }
                }
                Loader {
                    id: allDayIncidenceModelLoader
                    asynchronous: true

                    sourceComponent: Kalendar.MultiDayIncidenceModel {
                        filters: Kalendar.MultiDayIncidenceModel.AllDayOnly | Kalendar.MultiDayIncidenceModel.MultiDayOnly
                        periodLength: root.daysToShow

                        model: Kalendar.IncidenceOccurrenceModel {
                            id: occurrenceModel
                            calendar: Kalendar.CalendarManager.calendar
                            filter: root.filter ? root.filter : {}
                            length: root.daysToShow
                            objectName: "incidenceOccurrenceModel"
                            start: viewLoader.startDate
                        }
                    }
                }
                Item {
                    id: allDayHeader
                    property int actualHeight: {
                        if (Kalendar.Config.weekViewAllDayHeaderHeight === -1) {
                            return defaultHeight;
                        } else {
                            return Kalendar.Config.weekViewAllDayHeaderHeight;
                        }
                    }
                    readonly property int defaultHeight: Math.min(lineHeight, maxHeight)
                    readonly property int lineHeight: viewLoader.multiDayLinesShown * (Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing + root.incidenceSpacing) + Kirigami.Units.smallSpacing
                    readonly property int maxHeight: pathView.height / 3
                    readonly property int minHeight: Kirigami.Units.gridUnit * 2

                    height: actualHeight
                    visible: allDayViewLoader.active
                    width: pathView.width

                    Rectangle {
                        id: headerBackground
                        anchors.fill: parent
                        color: Kirigami.Theme.backgroundColor
                    }
                    Kirigami.ShadowedRectangle {
                        anchors.left: parent.left
                        anchors.top: parent.bottom
                        border.color: headerBottomSeparator.color
                        border.width: root.gridLineWidth
                        color: Kirigami.Theme.backgroundColor
                        corners.bottomRightRadius: Kirigami.Units.smallSpacing
                        height: resetHeaderHeightButton.height
                        shadow.color: Qt.rgba(0.0, 0.0, 0.0, 0.2)
                        shadow.size: Kirigami.Units.largeSpacing
                        shadow.xOffset: 2
                        shadow.yOffset: 2
                        visible: allDayHeader.actualHeight !== allDayHeader.defaultHeight
                        width: root.hourLabelWidth
                        z: -1

                        QQC2.ToolButton {
                            id: resetHeaderHeightButton
                            text: i18nc("@action:button", "Reset")
                            width: root.hourLabelWidth

                            onClicked: {
                                Kalendar.Config.weekViewAllDayHeaderHeight = -1;
                                Kalendar.Config.save();
                                allDayHeader.actualHeight = allDayHeader.defaultHeight;
                            }
                        }
                    }
                    QQC2.Label {
                        color: Kirigami.Theme.disabledTextColor
                        elide: Text.ElideRight
                        font: Kirigami.Theme.smallFont
                        height: parent.height
                        horizontalAlignment: Text.AlignRight
                        leftPadding: Kirigami.Units.largeSpacing
                        padding: Kirigami.Units.smallSpacing
                        text: i18n("Multi / All day")
                        verticalAlignment: Text.AlignTop
                        width: root.hourLabelWidth
                        wrapMode: Text.Wrap
                    }
                    Loader {
                        id: allDayViewLoader
                        active: allDayIncidenceModelLoader.item.incidenceCount > 0
                        anchors.fill: parent
                        anchors.leftMargin: root.hourLabelWidth

                        sourceComponent: Item {
                            id: allDayViewItem
                            clip: true
                            implicitHeight: allDayHeader.actualHeight

                            Repeater {
                                Layout.topMargin: Kirigami.Units.largeSpacing
                                model: allDayIncidenceModelLoader.item

                                //One row => one week
                                Item {
                                    id: weekItem
                                    clip: true
                                    implicitHeight: allDayHeader.actualHeight
                                    width: parent.width

                                    RowLayout {
                                        height: parent.height
                                        spacing: root.gridLineWidth
                                        width: parent.width

                                        Item {
                                            id: dayDelegate
                                            readonly property date startDate: periodStartDate

                                            Layout.fillHeight: true
                                            Layout.fillWidth: true

                                            QQC2.ScrollView {
                                                id: linesListViewScrollView
                                                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                                                anchors {
                                                    fill: parent
                                                }
                                                ListView {
                                                    id: linesRepeater
                                                    Layout.fillWidth: true
                                                    Layout.rightMargin: spacing
                                                    clip: true
                                                    model: incidences
                                                    spacing: root.incidenceSpacing

                                                    onCountChanged: {
                                                        viewLoader.multiDayLinesShown = count;
                                                    }

                                                    ListView {
                                                        id: allDayIncidencesBackgroundView
                                                        anchors.fill: parent
                                                        model: root.daysToShow
                                                        orientation: Qt.Horizontal
                                                        spacing: root.gridLineWidth
                                                        z: -1

                                                        Kirigami.Separator {
                                                            anchors.fill: parent
                                                            anchors.rightMargin: root.scrollbarWidth
                                                            z: -1
                                                        }

                                                        delegate: Rectangle {
                                                            id: multiDayViewBackground
                                                            readonly property date date: DateUtils.addDaysToDate(viewLoader.startDate, index)
                                                            readonly property bool isToday: date.getDate() === root.currentDay && date.getMonth() === root.currentMonth && date.getFullYear() === root.currentYear

                                                            color: isToday ? Kirigami.Theme.activeBackgroundColor : Kirigami.Theme.backgroundColor
                                                            height: linesListViewScrollView.height
                                                            width: root.dayWidth

                                                            DayMouseArea {
                                                                id: listViewMenu
                                                                addDate: parent.date
                                                                anchors.fill: parent

                                                                onAddNewIncidence: root.addIncidence(type, addDate, false)
                                                                onDeselect: root.deselect()
                                                            }
                                                        }
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
                                                                parentViewSpacing: root.gridLineWidth
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
                    MouseArea {
                        property real _lastY: -1

                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        cursorShape: !Kirigami.Settings.isMobile ? Qt.SplitVCursor : undefined
                        enabled: true
                        height: 5
                        preventStealing: true
                        visible: true
                        z: Infinity

                        onPositionChanged: {
                            if (_lastY === -1) {
                                return;
                            } else {
                                allDayHeader.actualHeight = Math.min(allDayHeader.maxHeight, Math.max(allDayHeader.minHeight, Kalendar.Config.weekViewAllDayHeaderHeight - _lastY + mapToGlobal(mouseX, mouseY).y));
                            }
                        }
                        onPressed: {
                            _lastY = mapToGlobal(mouseX, mouseY).y;
                            if (Kalendar.Config.weekViewAllDayHeaderHeight === -1) {
                                // Stops shrink on first drag
                                Kalendar.Config.weekViewAllDayHeaderHeight = allDayHeader.defaultHeight;
                            }
                        }
                        onReleased: {
                            Kalendar.Config.weekViewAllDayHeaderHeight = allDayHeader.actualHeight;
                            Kalendar.Config.save();
                        }
                    }
                }
                Kirigami.Separator {
                    id: headerBottomSeparator
                    height: root.gridLineWidth
                    visible: allDayViewLoader.active
                    width: pathView.width
                    z: -1

                    RectangularGlow {
                        anchors.fill: parent
                        color: Qt.rgba(0.0, 0.0, 0.0, 0.15)
                        glowRadius: 5
                        spread: 0.3
                        z: -1
                    }
                }
                QQC2.ScrollView {
                    id: hourlyView
                    readonly property real dayHeight: (daySections * Kirigami.Units.gridUnit) + (root.gridLineWidth * 23)
                    readonly property real daySections: (60 * 24) / modelLoader.item.periodLength
                    readonly property real hourHeight: periodsPerHour * Kirigami.Units.gridUnit
                    readonly property real minuteHeight: hourHeight / 60
                    readonly property real periodsPerHour: 60 / modelLoader.item.periodLength

                    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
                    contentWidth: availableWidth
                    height: pathView.height - headerBottomSeparator.height - allDayHeader.height - headerTopSeparator.height - headingRow.height
                    width: pathView.width
                    z: -2

                    Component.onCompleted: if (!Kirigami.Settings.isMobile)
                        root.scrollbarWidth = hourlyView.QQC2.ScrollBar.vertical.width

                    Connections {
                        target: hourlyView.QQC2.ScrollBar.vertical

                        function onWidthChanged() {
                            if (!Kirigami.Settings.isMobile)
                                root.scrollbarWidth = hourlyView.QQC2.ScrollBar.vertical.width;
                        }
                    }
                    Item {
                        id: hourlyViewContents
                        clip: true
                        implicitHeight: hourlyView.dayHeight
                        width: parent.width

                        ListView {
                            id: hourLabelsColumn
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.topMargin: (fontMetrics.height / 2) + (root.gridLineWidth / 2)
                            boundsBehavior: Flickable.StopAtBounds
                            model: root.hourStrings
                            spacing: root.gridLineWidth
                            width: root.hourLabelWidth

                            FontMetrics {
                                id: fontMetrics
                            }

                            delegate: QQC2.Label {
                                color: Kirigami.Theme.disabledTextColor
                                height: (Kirigami.Units.gridUnit * hourlyView.periodsPerHour)
                                horizontalAlignment: Text.AlignRight
                                rightPadding: Kirigami.Units.smallSpacing
                                text: modelData
                                verticalAlignment: Text.AlignBottom
                                width: root.hourLabelWidth
                            }
                        }
                        Item {
                            id: innerWeekView
                            clip: true

                            anchors {
                                bottom: parent.bottom
                                left: hourLabelsColumn.right
                                right: parent.right
                                top: parent.top
                            }
                            Kirigami.Separator {
                                anchors.fill: parent
                            }
                            ListView {
                                anchors.fill: parent
                                boundsBehavior: Flickable.StopAtBounds
                                model: modelLoader.item
                                orientation: Qt.Horizontal
                                spacing: root.gridLineWidth

                                delegate: Item {
                                    id: dayColumn
                                    readonly property date columnDate: DateUtils.addDaysToDate(viewLoader.startDate, index)
                                    readonly property int index: model.index
                                    readonly property bool isToday: columnDate.getDate() === root.currentDay && columnDate.getMonth() === root.currentMonth && columnDate.getFullYear() === root.currentYear

                                    clip: true
                                    height: hourlyView.dayHeight
                                    width: root.dayWidth

                                    ListView {
                                        anchors.fill: parent
                                        boundsBehavior: Flickable.StopAtBounds
                                        model: 24
                                        spacing: root.gridLineWidth

                                        delegate: Rectangle {
                                            color: dayColumn.isToday ? Kirigami.Theme.activeBackgroundColor : Kirigami.Theme.backgroundColor
                                            height: hourlyView.hourHeight
                                            width: parent.width

                                            DayMouseArea {
                                                addDate: new Date(DateUtils.addDaysToDate(viewLoader.startDate, dayColumn.index).setHours(index))
                                                anchors.fill: parent

                                                onAddNewIncidence: addIncidence(type, addDate, true)
                                                onDeselect: root.deselect()
                                            }
                                        }
                                    }
                                    Repeater {
                                        id: incidencesRepeater
                                        model: incidences

                                        delegate: Rectangle {
                                            readonly property real gridLineHeightCompensation: (modelData.duration / hourlyView.periodsPerHour) * root.gridLineWidth
                                            readonly property real gridLineYCompensation: (modelData.starts / hourlyView.periodsPerHour) * root.gridLineWidth
                                            readonly property bool isOpenOccurrence: root.openOccurrence ? root.openOccurrence.incidenceId === modelData.incidenceId : false

                                            clip: true
                                            color: Qt.rgba(0, 0, 0, 0)
                                            height: (modelData.duration * Kirigami.Units.gridUnit) - (root.incidenceSpacing * 2) + gridLineHeightCompensation - root.gridLineWidth
                                            radius: Kirigami.Units.smallSpacing
                                            visible: !modelData.allDay
                                            width: (root.dayWidth * modelData.widthShare) - (root.incidenceSpacing * 2)
                                            x: root.incidenceSpacing + (modelData.priorTakenWidthShare * root.dayWidth)
                                            y: (modelData.starts * Kirigami.Units.gridUnit) + root.incidenceSpacing + gridLineYCompensation

                                            IncidenceBackground {
                                                id: incidenceBackground
                                                isDark: root.isDark
                                                isOpenOccurrence: parent.isOpenOccurrence
                                            }
                                            ColumnLayout {
                                                id: incidenceContents
                                                readonly property bool isTinyHeight: parent.height <= Kirigami.Units.gridUnit
                                                readonly property color textColor: LabelUtils.getIncidenceLabelColor(modelData.color, root.isDark)

                                                anchors {
                                                    bottomMargin: !isTinyHeight ? Kirigami.Units.smallSpacing : 0
                                                    fill: parent
                                                    leftMargin: Kirigami.Units.smallSpacing
                                                    rightMargin: Kirigami.Units.smallSpacing
                                                    topMargin: !isTinyHeight ? Kirigami.Units.smallSpacing : 0
                                                }
                                                QQC2.Label {
                                                    Layout.fillHeight: true
                                                    Layout.fillWidth: true
                                                    color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") : incidenceContents.textColor
                                                    elide: Text.ElideRight
                                                    font.pointSize: parent.isTinyHeight ? Kirigami.Theme.smallFont.pointSize : Kirigami.Theme.defaultFont.pointSize
                                                    font.weight: Font.Medium
                                                    horizontalAlignment: Text.AlignLeft
                                                    text: modelData.text
                                                    verticalAlignment: Text.AlignTop
                                                    wrapMode: Text.Wrap
                                                }
                                                RowLayout {
                                                    visible: parent.height > Kirigami.Units.gridUnit * 3
                                                    width: parent.width

                                                    Kirigami.Icon {
                                                        id: incidenceIcon
                                                        color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") : incidenceContents.textColor
                                                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                                        isMask: true
                                                        source: modelData.incidenceTypeIcon
                                                        visible: parent.width > Kirigami.Units.gridUnit * 4
                                                    }
                                                    QQC2.Label {
                                                        id: timeLabel
                                                        Layout.fillWidth: true
                                                        color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") : incidenceContents.textColor
                                                        horizontalAlignment: Text.AlignRight
                                                        text: modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat) + " - " + modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat)
                                                        visible: parent.width > Kirigami.Units.gridUnit * 3
                                                        wrapMode: Text.Wrap
                                                    }
                                                }
                                            }
                                            IncidenceMouseArea {
                                                collectionId: modelData.collectionId
                                                incidenceData: modelData

                                                onAddSubTodoClicked: root.addSubTodo(parentWrapper)
                                                onDeleteClicked: deleteIncidence(incidencePtr, deleteDate)
                                                onEditClicked: editIncidence(incidencePtr, collectionId)
                                                onTodoCompletedClicked: completeTodo(incidencePtr)
                                                onViewClicked: viewIncidence(modelData, collectionData)
                                            }
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                id: currentTimeMarker
                                property date currentDateTime: root.currentDate
                                readonly property int daysFromWeekStart: DateUtils.fullDaysBetweenDates(viewLoader.startDate, currentDateTime) - 1
                                readonly property int minutesFromStart: (currentDateTime.getHours() * 60) + currentDateTime.getMinutes()

                                color: Kirigami.Theme.highlightColor
                                height: root.gridLineWidth * 2
                                visible: currentDateTime >= viewLoader.startDate && daysFromWeekStart < root.daysToShow
                                width: root.dayWidth
                                x: (daysFromWeekStart * root.dayWidth) + (daysFromWeekStart * root.gridLineWidth)
                                y: (currentDateTime.getHours() * root.gridLineWidth) + (hourlyView.minuteHeight * minutesFromStart) - (height / 2)
                                z: 100

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.topMargin: -(height / 2) + (parent.height / 2)
                                    color: Kirigami.Theme.highlightColor
                                    height: parent.height * 5
                                    radius: 100
                                    width: height
                                }
                            }
                        }
                    }
                }
            }
        }
        model: Kalendar.InfiniteCalendarViewModel {
            scale: Kalendar.InfiniteCalendarViewModel.WeekScale
        }
        path: Path {
            startX: -pathView.width * pathView.count / 2 + pathView.width / 2
            startY: pathView.height / 2

            PathLine {
                x: pathView.width * pathView.count / 2 + pathView.width / 2
                y: pathView.height / 2
            }
        }
    }

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
    }
}
