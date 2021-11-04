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
    signal deselect()

    property var openOccurrence: {}
    property var model

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
    readonly property int minutesFromStartOfDay: (root.currentDate.getHours() * 60) + root.currentDate.getMinutes()
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    property real scrollbarWidth: 0
    readonly property real dayWidth: ((root.width - hourLabelWidth - leftPadding - scrollbarWidth) / daysToShow) - gridLineWidth
    readonly property real incidenceSpacing: Kirigami.Units.smallSpacing / 2
    readonly property real gridLineWidth: 1.0
    readonly property real hourLabelWidth: Kirigami.Units.gridUnit * 3.5
    readonly property real periodHeight: Kirigami.Units.gridUnit / 2

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
    readonly property Kirigami.Action todayAction: Kirigami.Action {
        icon.name: "go-jump-today"
        text: i18n("Today")
        onTriggered: setToDate(new Date())
    }

    actions {
        left: Qt.application.layoutDirection === Qt.RightToLeft ? nextAction : previousAction
        right: Qt.application.layoutDirection === Qt.RightToLeft ? previousAction : nextAction
        main: todayAction
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

        model: root.model

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

            readonly property date startDate: model.startDate
            readonly property int month: model.selectedMonth - 1 // Convert QDateTime month to JS month
            readonly property int year: model.selectedYear

            readonly property int index: model.index
            readonly property bool isCurrentItem: PathView.isCurrentItem
            readonly property bool isNextOrCurrentItem: index >= pathView.currentIndex -1 && index <= pathView.currentIndex + 1
            property int multiDayLinesShown: 0

            readonly property int daysFromWeekStart: DateUtils.fullDaysBetweenDates(startDate, root.currentDate) - 1
            // As long as the date is even slightly larger, it will return 1; since we start from the startDate at 00:00, adjust

            active: isNextOrCurrentItem
            asynchronous: !isCurrentItem
            visible: status === Loader.Ready
            sourceComponent: Column {
                id: viewColumn
                width: pathView.width
                height: pathView.height
                spacing: 0

                Row {
                    id: headingRow
                    width: pathView.width
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

                        model: weekViewModel.rowCount()
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
                    Rectangle { // Cover up the shadow of headerTopSeparator above the scrollbar
                        color: Kirigami.Theme.backgroundColor
                        height: parent.height
                        width: root.scrollbarWidth
                    }
                }

                Kirigami.Separator {
                    id: headerTopSeparator
                    width: pathView.width
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

                Item {
                    id: allDayHeader
                    width: pathView.width
                    height: actualHeight
                    visible: allDayViewLoader.active

                    readonly property int minHeight: Kirigami.Units.gridUnit *2
                    readonly property int maxHeight: pathView.height / 3
                    readonly property int lineHeight: viewLoader.multiDayLinesShown * (Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing + root.incidenceSpacing) + Kirigami.Units.smallSpacing
                    readonly property int defaultHeight: Math.min(lineHeight, maxHeight)
                    property int actualHeight: {
                        if (Kalendar.Config.weekViewAllDayHeaderHeight === -1) {
                            return defaultHeight;
                        } else {
                            return Kalendar.Config.weekViewAllDayHeaderHeight;
                        }
                    }

                    NumberAnimation {
                        id: resetAnimation
                        target: allDayHeader
                        property: "height"
                        to: allDayHeader.defaultHeight
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                        onFinished: {
                            Kalendar.Config.weekViewAllDayHeaderHeight = -1;
                            Kalendar.Config.save();
                            allDayHeader.actualHeight = allDayHeader.defaultHeight;
                        }
                    }

                    Rectangle {
                        id: headerBackground
                        anchors.fill: parent
                        color: Kirigami.Theme.backgroundColor
                    }

                    Kirigami.ShadowedRectangle {
                        anchors.left: parent.left
                        anchors.top: parent.bottom
                        width: root.hourLabelWidth
                        height: Kalendar.Config.weekViewAllDayHeaderHeight !== -1 ?
                            resetHeaderHeightButton.height :
                            0
                        z: -1
                        corners.bottomRightRadius: Kirigami.Units.smallSpacing
                        shadow.size: Kirigami.Units.largeSpacing
                        shadow.color: Qt.rgba(0.0, 0.0, 0.0, 0.2)
                        shadow.yOffset: 2
                        shadow.xOffset: 2
                        color: Kirigami.Theme.backgroundColor
                        border.width: root.gridLineWidth
                        border.color: headerBottomSeparator.color

                        Behavior on height { NumberAnimation {
                            duration: Kirigami.Units.shortDuration
                            easing.type: Easing.InOutQuad
                        } }

                        Item {
                            width: root.hourLabelWidth
                            height: parent.height
                            clip: true

                            QQC2.ToolButton {
                                id: resetHeaderHeightButton
                                width: root.hourLabelWidth
                                text: i18nc("@action:button", "Reset")
                                onClicked: resetAnimation.start()
                            }
                        }
                    }

                    QQC2.Label {
                        width: root.hourLabelWidth
                        height: parent.height
                        padding: Kirigami.Units.smallSpacing
                        leftPadding: Kirigami.Units.largeSpacing
                        verticalAlignment: Text.AlignTop
                        horizontalAlignment: Text.AlignRight
                        text: i18n("Multi / All day")
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        font: Kirigami.Theme.smallFont
                        color: Kirigami.Theme.disabledTextColor
                    }

                    Loader {
                        id: allDayViewLoader
                        anchors.fill: parent
                        anchors.leftMargin: root.hourLabelWidth
                        active: weekViewMultiDayViewModel.incidenceCount > 0
                        sourceComponent: Item {
                            id: allDayViewItem
                            implicitHeight: allDayHeader.actualHeight
                            clip: true

                            Repeater {
                                model: weekViewMultiDayViewModel // from root.model
                                Layout.topMargin: Kirigami.Units.largeSpacing
                                //One row => one week
                                Item {
                                    id: weekItem
                                    width: parent.width
                                    implicitHeight: allDayHeader.actualHeight
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
                                                                onDeselect: root.deselect()
                                                            }
                                                        }
                                                    }

                                                    model: incidences
                                                    onCountChanged: {
                                                        viewLoader.multiDayLinesShown = count
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

                    MouseArea {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        height: 5
                        z: Infinity
                        cursorShape: !Kirigami.Settings.isMobile ? Qt.SplitVCursor : undefined
                        preventStealing: true
                        enabled: true
                        visible: true
                        onPressed: {
                            _lastY = mapToGlobal(mouseX, mouseY).y;
                            if(Kalendar.Config.weekViewAllDayHeaderHeight === -1) {
                                // Stops shrink on first drag
                                Kalendar.Config.weekViewAllDayHeaderHeight = allDayHeader.defaultHeight;
                            }
                        }
                        onReleased: {
                            Kalendar.Config.weekViewAllDayHeaderHeight = allDayHeader.actualHeight;
                            Kalendar.Config.save();
                        }
                        property real _lastY: -1

                        onPositionChanged: {
                            if (_lastY === -1) {
                                return;
                            } else {
                                allDayHeader.actualHeight = Math.min(allDayHeader.maxHeight, Math.max(allDayHeader.minHeight, Kalendar.Config.weekViewAllDayHeaderHeight - _lastY + mapToGlobal(mouseX, mouseY).y))
                            }
                        }
                    }
                }

                Kirigami.Separator {
                    id: headerBottomSeparator
                    width: pathView.width
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
                    width: pathView.width
                    height: pathView.height - headerBottomSeparator.height - allDayHeader.height - headerTopSeparator.height - headingRow.height
                    contentWidth: availableWidth
                    z: -2
                    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                    readonly property real periodsPerHour: 60 / weekViewModel.periodLength
                    readonly property real daySections: (60 * 24) / weekViewModel.periodLength
                    readonly property real dayHeight: (daySections * root.periodHeight) + (root.gridLineWidth * 23)
                    readonly property real hourHeight: periodsPerHour * root.periodHeight
                    readonly property real minuteHeight: hourHeight / 60

                    Connections {
                        target: hourlyView.QQC2.ScrollBar.vertical
                        function onWidthChanged() {
                            if(!Kirigami.Settings.isMobile) root.scrollbarWidth = hourlyView.QQC2.ScrollBar.vertical.width;
                        }
                    }
                    Component.onCompleted: {
                        if(!Kirigami.Settings.isMobile) root.scrollbarWidth = hourlyView.QQC2.ScrollBar.vertical.width
                    }

                    Item {
                        id: hourlyViewContents
                        width: parent.width
                        implicitHeight: hourlyView.dayHeight

                        clip: true

                        Item {
                            id: hourLabelsColumn

                            property real currentTimeLabelTop: currentTimeLabelLoader.active ?
                                currentTimeLabelLoader.item.y
                                : 0
                            property real currentTimeLabelBottom: currentTimeLabelLoader.active ?
                                currentTimeLabelLoader.item.y + fontMetrics.height
                                : 0

                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: root.hourLabelWidth

                            FontMetrics {
                                id: fontMetrics
                            }

                            Loader {
                                id: currentTimeLabelLoader

                                active: root.currentDate >= viewLoader.startDate && viewLoader.daysFromWeekStart < root.daysToShow
                                sourceComponent: QQC2.Label {
                                    id: currentTimeLabel

                                    width: root.hourLabelWidth
                                    color: Kirigami.Theme.highlightColor
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignRight
                                    rightPadding: Kirigami.Units.smallSpacing
                                    y: Math.max(0, (root.currentDate.getHours() * root.gridLineWidth) + (hourlyView.minuteHeight * root.minutesFromStartOfDay) - (implicitHeight / 2)) - (root.gridLineWidth / 2)
                                    z: 100

                                    text: root.currentDate.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat)

                                }
                            }

                            Repeater {
                                model: pathView.model.weekViewLocalisedHourLabels // Not a model role but instead one of the model object's properties

                                delegate: QQC2.Label {
                                    property real textYTop: y
                                    property real textYBottom: y + fontMetrics.height
                                    property bool overlapWithCurrentTimeLabel: currentTimeLabelLoader.active &&
                                        ((hourLabelsColumn.currentTimeLabelTop <= textYTop && hourLabelsColumn.currentTimeLabelBottom >= textYTop) ||
                                        (hourLabelsColumn.currentTimeLabelTop < textYBottom && hourLabelsColumn.currentTimeLabelBottom > textYBottom) ||
                                        (hourLabelsColumn.currentTimeLabelTop >= textYTop && hourLabelsColumn.currentTimeLabelBottom <= textYBottom))

                                    y: ((root.periodHeight * hourlyView.periodsPerHour) * (index + 1)) + (root.gridLineWidth * (index + 1)) -
                                        (fontMetrics.height / 2) - (root.gridLineWidth / 2)
                                    width: root.hourLabelWidth
                                    rightPadding: Kirigami.Units.smallSpacing
                                    verticalAlignment: Text.AlignBottom
                                    horizontalAlignment: Text.AlignRight
                                    text: modelData
                                    color: Kirigami.Theme.disabledTextColor
                                    visible: !overlapWithCurrentTimeLabel
                                }
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

                            Kirigami.Separator {
                                anchors.fill: parent
                            }

                            ListView {
                                anchors.fill: parent
                                spacing: root.gridLineWidth
                                orientation: Qt.Horizontal
                                model: weekViewModel // From root.model

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
                                                onDeselect: root.deselect()
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
                                            y: (modelData.starts * root.periodHeight) + root.incidenceSpacing + gridLineYCompensation
                                            width: (root.dayWidth * modelData.widthShare) - (root.incidenceSpacing * 2)
                                            height: (modelData.duration * root.periodHeight) - (root.incidenceSpacing * 2) + gridLineHeightCompensation - root.gridLineWidth
                                            radius: Kirigami.Units.smallSpacing
                                            color: Qt.rgba(0,0,0,0)
                                            clip: true
                                            visible: !modelData.allDay

                                            IncidenceBackground {
                                                id: incidenceBackground
                                                isOpenOccurrence: parent.isOpenOccurrence
                                                isDark: root.isDark
                                            }

                                            ColumnLayout {
                                                id: incidenceContents

                                                readonly property color textColor: LabelUtils.getIncidenceLabelColor(modelData.color, root.isDark)
                                                readonly property bool isTinyHeight: parent.height <= Kirigami.Units.gridUnit

                                                anchors {
                                                    fill: parent
                                                    leftMargin: Kirigami.Units.smallSpacing
                                                    rightMargin: Kirigami.Units.smallSpacing
                                                    topMargin: !isTinyHeight ? Kirigami.Units.smallSpacing : 0
                                                    bottomMargin: !isTinyHeight ? Kirigami.Units.smallSpacing : 0
                                                }

                                                QQC2.Label {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    text: modelData.text
                                                    horizontalAlignment: Text.AlignLeft
                                                    verticalAlignment: Text.AlignTop
                                                    wrapMode: Text.Wrap
                                                    elide: Text.ElideRight
                                                    font.pointSize: parent.isTinyHeight ? Kirigami.Theme.smallFont.pointSize :
                                                        Kirigami.Theme.defaultFont.pointSize
                                                    font.weight: Font.Medium
                                                    renderType: Text.QtRendering
                                                    color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                        incidenceContents.textColor
                                                    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
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
                                                        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                                        visible: parent.width > Kirigami.Units.gridUnit * 4
                                                    }
                                                    QQC2.Label {
                                                        id: timeLabel
                                                        Layout.fillWidth: true
                                                        horizontalAlignment: Text.AlignRight
                                                        text: modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat) + " - " + modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat)
                                                        wrapMode: Text.Wrap
                                                        renderType: Text.QtRendering
                                                        color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                            incidenceContents.textColor
                                                        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
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

                            Loader {
                                id: currentTimeMarkerLoader

                                active: root.currentDate >= viewLoader.startDate && viewLoader.daysFromWeekStart < root.daysToShow
                                sourceComponent: Rectangle {
                                    id: currentTimeMarker

                                    width: root.dayWidth
                                    height: root.gridLineWidth * 2
                                    color: Kirigami.Theme.highlightColor
                                    x: (viewLoader.daysFromWeekStart * root.dayWidth) + (viewLoader.daysFromWeekStart * root.gridLineWidth)
                                    y: (root.currentDate.getHours() * root.gridLineWidth) + (hourlyView.minuteHeight * root.minutesFromStartOfDay) -
                                        (height / 2) - (root.gridLineWidth / 2)
                                    z: 100

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
}
