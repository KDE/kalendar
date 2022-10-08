// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import QtGraphicalEffects 1.12

import org.kde.kalendar 1.0 as Kalendar
import org.kde.kalendar.utils 1.0
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

PathView {
    id: pathView

    property var openOccurrence: ({})

    property date currentDate: new Date() // Needs to get updated for marker to move, done from main.qml
    property date startDate: DateUtils.getFirstDayOfWeek(currentDate)

    readonly property int currentDay: currentDate.getDate()
    readonly property int currentMonth: currentDate.getMonth()
    readonly property int currentYear: currentDate.getFullYear()
    readonly property int day: startDate.getDate()
    readonly property int month: startDate.getMonth()
    readonly property int year: startDate.getFullYear()

    property int daysToShow: 7
    readonly property int minutesFromStartOfDay: (pathView.currentDate.getHours() * 60) + pathView.currentDate.getMinutes()
    readonly property bool isDark: KalendarUiUtils.darkMode
    property bool dragDropEnabled: true

    property int allDayViewDelegateHeight: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing

    property int periodLength: 15
    property real scrollbarWidth: 0
    readonly property real dayWidth: ((pathView.width - hourLabelWidth - leftPadding - scrollbarWidth) / daysToShow) - gridLineWidth
    readonly property real incidenceSpacing: Kirigami.Units.smallSpacing / 2
    readonly property real gridLineWidth: 1.0
    readonly property real hourLabelWidth: hourLabelMetrics.boundingRect(new Date(0,0,0,0,0,0,0).toLocaleTimeString(Qt.locale(), Locale.NarrowFormat)).width +
        Kirigami.Units.largeSpacing * 2.5
    readonly property real periodHeight: Kirigami.Units.gridUnit

    function setToDate(date, isInitialWeek = false, animate = false) {
        if(!pathView.currentItem) {
            return;
        }

        if(daysToShow % 7 === 0) {
            date = DateUtils.getFirstDayOfWeek(date);
        }

        startDate = date;

        const weekDiff = Math.round((date.getTime() - pathView.currentItem.startDate.getTime()) / (daysToShow * 24 * 60 * 60 * 1000));

        let position = pathView.currentItem.item.hourScrollView.getCurrentPosition();
        let newIndex = pathView.currentIndex + weekDiff;
        let firstItemDate = pathView.model.data(pathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
        let lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);

        while(firstItemDate >= date) {
            pathView.model.addDates(false)
            firstItemDate = pathView.model.data(pathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
            newIndex = 0;
        }
        if(firstItemDate < date && newIndex === 0) {
            newIndex = Math.round((date - firstItemDate) / (daysToShow * 24 * 60 * 60 * 1000)) + 1
        }

        while(lastItemDate <= date) {
            pathView.model.addDates(true)
            lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.StartDateRole);
        }
        pathView.currentIndex = newIndex;

        if(isInitialWeek) {
            pathView.currentItem.item.hourScrollView.setToCurrentTime(animate);
        } else {
            pathView.currentItem.item.hourScrollView.setPosition(position);
        }
    }

    flickDeceleration: Kirigami.Units.longDuration
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange
    snapMode: PathView.SnapToItem
    focus: true
    interactive: Kirigami.Settings.tabletMode

    pathItemCount: 3
    path: Path {
        startX: - pathView.width * pathView.pathItemCount / 2 + pathView.width / 2
        startY: pathView.height / 2
        PathLine {
            x: pathView.width * pathView.pathItemCount / 2 + pathView.width / 2
            y: pathView.height / 2
        }
    }

    FontMetrics {
        id: hourLabelMetrics
        font.bold: true
    }

    FontMetrics {
        id: fontMetrics
    }

    Component {
        id: weekModel
        Kalendar.InfiniteCalendarViewModel {
            scale: Kalendar.InfiniteCalendarViewModel.WeekScale
        }
    }

    Component {
        id: threeDayModel
        Kalendar.InfiniteCalendarViewModel {
            scale: Kalendar.InfiniteCalendarViewModel.ThreeDayScale
        }
    }

    Component {
        id: dayModel
        Kalendar.InfiniteCalendarViewModel {
            scale: Kalendar.InfiniteCalendarViewModel.DayScale
        }
    }

    Loader {
        id: modelLoader
        sourceComponent: switch(pathView.daysToShow) {
                         case 1:
                             return dayModel;
                         case 3:
                             return threeDayModel;
                         case 7:
                         default:
                             return weekModel;
                         }
    }

    model: modelLoader.item

    property real scrollPosition
    onMovementStarted: {
        scrollPosition = pathView.currentItem.item.hourScrollView.getCurrentPosition();
    }

    onMovementEnded: {
        pathView.currentItem.item.hourScrollView.setPosition(scrollPosition);
    }

    property date dateToUse
    property int startIndex: count / 2;
    currentIndex: startIndex
    onCurrentIndexChanged: if(currentItem) {
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
        readonly property date endDate: DateUtils.addDaysToDate(model.startDate, pathView.daysToShow)
        readonly property int month: model.selectedMonth - 1 // Convert QDateTime month to JS month
        readonly property int year: model.selectedYear

        readonly property int index: model.index
        readonly property bool isCurrentItem: PathView.isCurrentItem
        readonly property bool isNextOrCurrentItem: index >= pathView.currentIndex -1 && index <= pathView.currentIndex + 1
        property int multiDayLinesShown: 0

        readonly property int daysFromWeekStart: DateUtils.fullDaysBetweenDates(startDate, pathView.currentDate) - 1
        // As long as the date is even slightly larger, it will return 1; since we start from the startDate at 00:00, adjust

        active: isNextOrCurrentItem
        asynchronous: !isCurrentItem
        visible: status === Loader.Ready
        sourceComponent: Column {
            id: viewColumn
            width: pathView.width
            height: pathView.height
            spacing: 0

            readonly property alias hourScrollView: hourlyView

            Row {
                id: headingRow
                width: pathView.width
                spacing: pathView.gridLineWidth

                Kirigami.Heading {
                    id: weekNumberHeading

                    width: pathView.hourLabelWidth - pathView.gridLineWidth
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

                    model: pathView.daysToShow
                    delegate: Rectangle {
                        width: pathView.dayWidth
                        implicitHeight: dayHeading.implicitHeight
                        color: Kirigami.Theme.backgroundColor

                        Kirigami.Heading { // Heading is out of the button so the color isn't disabled when the button is
                            id: dayHeading

                            property date headingDate: DateUtils.addDaysToDate(viewLoader.startDate, index)
                            property bool isToday: headingDate.getDate() === pathView.currentDay &&
                                headingDate.getMonth() === pathView.currentMonth &&
                                headingDate.getFullYear() === pathView.currentYear
                            width: parent.width
                            horizontalAlignment: Text.AlignRight
                            padding: Kirigami.Units.smallSpacing
                            level: 2
                            color: isToday ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                            text: {
                                const longText = headingDate.toLocaleDateString(Qt.locale(), "dddd <b>d</b>");
                                const mediumText = headingDate.toLocaleDateString(Qt.locale(), "ddd <b>d</b>");
                                const shortText = mediumText.slice(0,1) + " " + headingDate.toLocaleDateString(Qt.locale(), "<b>d</b>");


                                if(fontMetrics.boundingRect(longText).width < width) {
                                    return longText;
                                } else if(fontMetrics.boundingRect(mediumText).width < width) {
                                    return mediumText;
                                } else {
                                    return shortText;
                                }
                            }
                        }

                        QQC2.Button {
                            implicitHeight: dayHeading.implicitHeight
                            width: parent.width

                            flat: true
                            enabled: pathView.daysToShow > 1
                            onClicked: KalendarUiUtils.openDayLayer(dayHeading.headingDate)
                        }
                    }
                }
                Rectangle { // Cover up the shadow of headerTopSeparator above the scrollbar
                    color: Kirigami.Theme.backgroundColor
                    height: parent.height
                    width: pathView.scrollbarWidth
                }
            }

            Kirigami.Separator {
                id: headerTopSeparator
                width: pathView.width
                height: pathView.gridLineWidth
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
                readonly property int lineHeight: viewLoader.multiDayLinesShown > 0 ?
                    viewLoader.multiDayLinesShown * (pathView.allDayViewDelegateHeight + pathView.incidenceSpacing) + Kirigami.Units.smallSpacing :
                    0
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
                    width: pathView.hourLabelWidth
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
                    border.width: pathView.gridLineWidth
                    border.color: headerBottomSeparator.color

                    Behavior on height { NumberAnimation {
                        duration: Kirigami.Units.shortDuration
                        easing.type: Easing.InOutQuad
                    } }

                    Item {
                        width: pathView.hourLabelWidth
                        height: parent.height
                        clip: true

                        QQC2.ToolButton {
                            id: resetHeaderHeightButton
                            width: pathView.hourLabelWidth
                            text: i18nc("@action:button", "Reset")
                            onClicked: resetAnimation.start()
                        }
                    }
                }

                QQC2.Label {
                    width: pathView.hourLabelWidth
                    height: parent.height
                    padding: Kirigami.Units.smallSpacing
                    leftPadding: Kirigami.Units.largeSpacing
                    verticalAlignment: Text.AlignTop
                    horizontalAlignment: Text.AlignRight
                    text: i18n("All day or Multi day")
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    font: Kirigami.Theme.smallFont
                    color: Kirigami.Theme.disabledTextColor
                }

                Loader {
                    id: allDayViewLoader
                    anchors.fill: parent
                    anchors.leftMargin: pathView.hourLabelWidth
                    asynchronous: !viewLoader.isCurrentItem

                    sourceComponent: Item {
                        id: allDayViewItem
                        implicitHeight: allDayHeader.actualHeight
                        clip: true

                        Repeater {
                            model: Kalendar.MultiDayIncidenceModel {
                                periodLength: pathView.daysToShow
                                filters: Kalendar.MultiDayIncidenceModel.AllDayOnly | Kalendar.MultiDayIncidenceModel.MultiDayOnly
                                model: Kalendar.IncidenceOccurrenceModel {
                                    start: viewLoader.startDate
                                    length: pathView.daysToShow
                                    calendar: Kalendar.CalendarManager.calendar
                                    filter: Kalendar.Filter
                                }
                            }

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
                                    spacing: pathView.gridLineWidth
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
                                                spacing: pathView.incidenceSpacing

                                                ListView {
                                                    id: allDayIncidencesBackgroundView
                                                    anchors.fill: parent
                                                    spacing: pathView.gridLineWidth
                                                    orientation: Qt.Horizontal
                                                    z: -1

                                                    Kirigami.Separator {
                                                        anchors.fill: parent
                                                        anchors.rightMargin: pathView.scrollbarWidth
                                                        z: -1
                                                    }

                                                    model: pathView.daysToShow
                                                    delegate: Rectangle {
                                                        id: multiDayViewBackground

                                                        readonly property date date: DateUtils.addDaysToDate(viewLoader.startDate, index)
                                                        readonly property bool isToday: date.getDate() === pathView.currentDay &&
                                                            date.getMonth() === pathView.currentMonth &&
                                                            date.getFullYear() === pathView.currentYear

                                                        width: pathView.dayWidth
                                                        height: linesListViewScrollView.height
                                                        color: multiDayViewIncidenceDropArea.containsDrag ?  Kirigami.Theme.positiveBackgroundColor :
                                                            isToday ? Kirigami.Theme.activeBackgroundColor : Kirigami.Theme.backgroundColor

                                                        DayMouseArea {
                                                            id: listViewMenu
                                                            anchors.fill: parent

                                                            addDate: parent.date
                                                            onAddNewIncidence: pathView.addIncidence(type, addDate, false)
                                                            onDeselect: KalendarUiUtils.appMain.incidenceInfoViewer.close()

                                                            DropArea {
                                                                id: multiDayViewIncidenceDropArea
                                                                anchors.fill: parent
                                                                z: 9999
                                                                onDropped: if(viewLoader.isCurrentItem) {
                                                                    const pos = mapToItem(pathView, x, y);
                                                                    drop.source.caughtX = pos.x + pathView.incidenceSpacing;
                                                                    drop.source.caughtY = pos.y;
                                                                    drop.source.caught = true;

                                                                    const incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', multiDayViewIncidenceDropArea, "incidence");
                                                                    incidenceWrapper.incidenceItem = Kalendar.CalendarManager.incidenceItem(drop.source.incidencePtr);

                                                                    let sameTimeOnDate = new Date(listViewMenu.addDate);
                                                                    sameTimeOnDate = new Date(sameTimeOnDate.setHours(drop.source.occurrenceDate.getHours(), drop.source.occurrenceDate.getMinutes()));
                                                                    const offset = sameTimeOnDate.getTime() - drop.source.occurrenceDate.getTime();
                                                                    /* There are 2 possibilities here: we move multiday incidence between days or we move hourly incidence
                                                                     * to convert it into multiday incidence
                                                                     */
                                                                    if (drop.source.objectName === 'hourlyIncidenceDelegateBackgroundBackground') {
                                                                        // This is conversion from non-multiday to multiday
                                                                        KalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, offset, offset, drop.source.occurrenceDate, drop.source, true)
                                                                    } else {
                                                                        KalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, offset, offset, drop.source.occurrenceDate, drop.source)
                                                                    }
                                                                }
                                                            }
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
                                                        id: allDayIncidencesRepeater
                                                        model: modelData
                                                        DayGridViewIncidenceDelegate {
                                                            id: dayGridViewIncidenceDelegate
                                                            objectName: "dayGridViewIncidenceDelegate"
                                                            dayWidth: pathView.dayWidth
                                                            height: pathView.allDayViewDelegateHeight
                                                            parentViewSpacing: pathView.gridLineWidth
                                                            horizontalSpacing: linesRepeater.spacing
                                                            openOccurrenceId: pathView.openOccurrence ? pathView.openOccurrence.incidenceId : ""
                                                            isDark: pathView.isDark
                                                            reactToCurrentMonth: false
                                                            dragDropEnabled: pathView.dragDropEnabled
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

            ResizerSeparator {
                id: headerBottomSeparator
                width: pathView.width
                height: pathView.gridLineWidth
                oversizeMouseAreaVertical: 5
                z: Infinity
                visible: allDayViewLoader.active

                function setPos() {
                    Kalendar.Config.weekViewAllDayHeaderHeight = allDayHeader.actualHeight;
                    Kalendar.Config.save();
                }

                onDragBegin:  setPos()
                onDragReleased: setPos()
                onDragPositionChanged: allDayHeader.actualHeight = Math.min(allDayHeader.maxHeight, Math.max(allDayHeader.minHeight, Kalendar.Config.weekViewAllDayHeaderHeight + changeY))
            }

            RectangularGlow {
                id: headerBottomShadow
                anchors.top: headerBottomSeparator.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                z: -1
                glowRadius: 5
                spread: 0.3
                color: Qt.rgba(0.0, 0.0, 0.0, 0.15)
            }

            QQC2.ScrollView {
                id: hourlyView
                width: viewColumn.width
                height: actualHeight
                contentWidth: availableWidth
                z: -2
                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                readonly property real periodsPerHour: 60 / pathView.periodLength
                readonly property real daySections: (60 * 24) / pathView.periodLength
                readonly property real dayHeight: (daySections * pathView.periodHeight) + (pathView.gridLineWidth * 23)
                readonly property real hourHeight: periodsPerHour * pathView.periodHeight
                readonly property real minuteHeight: hourHeight / 60
                readonly property Item vScrollBar: QQC2.ScrollBar.vertical

                property int actualHeight: {
                    let h = viewColumn.height - headerBottomSeparator.height - headerTopSeparator.height - headingRow.height;
                    if (allDayHeader.visible) {
                        h -= allDayHeader.height;
                    }
                    return h;
                }

                NumberAnimation on QQC2.ScrollBar.vertical.position {
                    id: scrollAnimation
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }

                function setToCurrentTime(animate = false) {
                    if(currentTimeMarkerLoader.active) {
                        const viewHeight = (applicationWindow().height - applicationWindow().pageStack.globalToolBar.height - headerBottomSeparator.height - allDayHeader.height - headerTopSeparator.height - headingRow.height - Kirigami.Units.gridUnit);
                        // Since we position with anchors, height is 0 -- must calc manually

                        const timeMarkerY = (pathView.currentDate.getHours() * pathView.gridLineWidth) + (hourlyView.minuteHeight * pathView.minutesFromStartOfDay) - (height / 2) - (pathView.gridLineWidth / 2)
                        const yPos = Math.max(0.0, (timeMarkerY / dayHeight))
                        setPosition(yPos, animate);
                    }
                }

                function getCurrentPosition() {
                    return vScrollBar.position;
                }

                function setPosition(position, animate = false) {
                    let offset = vScrollBar.visualSize + position - 1;
                    // Initially let's assume that we are still somewhere before bottom of the hourlyView
                    // so lets simply set vScrollBar position to what was given
                    let yPos = position;
                    if (offset > 0) {
                        // Ups, it seems that we are going lower than bottom of the hourlyView
                        // Lets set position to the bottom of the vScrollBar then
                        yPos = 1 - vScrollBar.visualSize;
                    }
                    if (animate) {
                        scrollAnimation.to = yPos;
                        if (scrollAnimation.running) {
                            scrollAnimation.stop();
                        }
                        scrollAnimation.start();
                    } else {
                        vScrollBar.position = yPos;
                    }
                }

                Connections {
                    target: hourlyView.QQC2.ScrollBar.vertical
                    function onWidthChanged() {
                        if(!Kirigami.Settings.isMobile) pathView.scrollbarWidth = hourlyView.QQC2.ScrollBar.vertical.width;
                    }
                }
                Component.onCompleted: {
                    if(!Kirigami.Settings.isMobile) pathView.scrollbarWidth = hourlyView.QQC2.ScrollBar.vertical.width;
                    if(currentTimeMarkerLoader.active && pathView.initialWeek) {
                        setToCurrentTime();
                    }
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
                        width: pathView.hourLabelWidth

                        Loader {
                            id: currentTimeLabelLoader

                            active: currentTimeMarkerLoader.active
                            sourceComponent: QQC2.Label {
                                id: currentTimeLabel

                                width: pathView.hourLabelWidth
                                color: Kirigami.Theme.highlightColor
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignRight
                                rightPadding: Kirigami.Units.smallSpacing
                                y: Math.max(0, (pathView.currentDate.getHours() * pathView.gridLineWidth) + (hourlyView.minuteHeight * pathView.minutesFromStartOfDay) - (implicitHeight / 2)) - (pathView.gridLineWidth / 2)
                                z: 100

                                text: pathView.currentDate.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat)

                            }
                        }

                        Repeater {
                            model: pathView.model.hourlyViewLocalisedHourLabels // Not a model role but instead one of the model object's properties

                            delegate: QQC2.Label {
                                property real textYTop: y
                                property real textYBottom: y + fontMetrics.height
                                property bool overlapWithCurrentTimeLabel: currentTimeLabelLoader.active &&
                                    ((hourLabelsColumn.currentTimeLabelTop <= textYTop && hourLabelsColumn.currentTimeLabelBottom >= textYTop) ||
                                    (hourLabelsColumn.currentTimeLabelTop < textYBottom && hourLabelsColumn.currentTimeLabelBottom > textYBottom) ||
                                    (hourLabelsColumn.currentTimeLabelTop >= textYTop && hourLabelsColumn.currentTimeLabelBottom <= textYBottom))

                                y: ((pathView.periodHeight * hourlyView.periodsPerHour) * (index + 1)) + (pathView.gridLineWidth * (index + 1)) -
                                    (fontMetrics.height / 2) - (pathView.gridLineWidth / 2)
                                width: pathView.hourLabelWidth
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

                        Row {
                            id: dayColumnRow
                            anchors.fill: parent
                            spacing: pathView.gridLineWidth

                            Repeater {
                                id: dayColumnRepeater
                                model: Kalendar.HourlyIncidenceModel {
                                   periodLength: pathView.periodLength
                                   filters: Kalendar.MultiDayIncidenceModel.AllDayOnly | Kalendar.MultiDayIncidenceModel.MultiDayOnly
                                   model: Kalendar.IncidenceOccurrenceModel {
                                       start: viewLoader.startDate
                                       length: pathView.daysToShow
                                       calendar: Kalendar.CalendarManager.calendar
                                       filter: Kalendar.Filter
                                   }
                               }

                                delegate: Item {
                                    id: dayColumn

                                    readonly property int index: model.index
                                    readonly property date columnDate: DateUtils.addDaysToDate(viewLoader.startDate, index)
                                    readonly property bool isToday: columnDate.getDate() === pathView.currentDay &&
                                        columnDate.getMonth() === pathView.currentMonth &&
                                        columnDate.getFullYear() === pathView.currentYear

                                    width: pathView.dayWidth
                                    height: hourlyView.dayHeight
                                    clip: true

                                    Loader {
                                        anchors.fill: parent
                                        asynchronous: !viewLoader.isCurrentView
                                        ListView {
                                            anchors.fill: parent
                                            spacing: pathView.gridLineWidth
                                            boundsBehavior: Flickable.StopAtBounds
                                            interactive: false

                                            model: 24
                                            delegate: Rectangle {
                                                id: backgroundRectangle
                                                width: parent.width
                                                height: hourlyView.hourHeight
                                                color: dayColumn.isToday ? Kirigami.Theme.activeBackgroundColor : Kirigami.Theme.backgroundColor

                                                property int index: model.index

                                                ColumnLayout {
                                                    anchors.fill: parent
                                                    spacing: 0
                                                    z: 9999
                                                    Repeater {
                                                        id: dropAreaRepeater
                                                        model: 4

                                                        readonly property int minutes: 60 / model

                                                        DropArea {
                                                            id: hourlyViewIncidenceDropArea
                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true
                                                            z: 9999
                                                            onDropped: if(viewLoader.isCurrentItem) {
                                                                let incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', hourlyViewIncidenceDropArea, "incidence");
                                                                /* So when we drop the entire incidence card somewhere, we are dropping the delegate with object name "hourlyIncidenceDelegateBackgroundBackground" or "multiDayIncidenceDelegateBackgroundBackground" in case when all day event is converted to the hour incidence.
                                                                 * However, when we are simply resizing, we are actually dropping the specific mouseArea within the delegate that handles
                                                                 * the dragging for the incidence's bottom edge which has name "endDtResizeMouseArea". Hence why we check the object names
                                                                 */
                                                                if(drop.source.objectName === "hourlyIncidenceDelegateBackgroundBackground") {
                                                                    incidenceWrapper.incidenceItem = Kalendar.CalendarManager.incidenceItem(drop.source.incidencePtr);

                                                                    const pos = mapToItem(pathView, dropAreaHighlightRectangle.x, dropAreaHighlightRectangle.y);
                                                                    drop.source.caughtX = pos.x + incidenceSpacing;
                                                                    drop.source.caughtY = pos.y + incidenceSpacing;
                                                                    drop.source.caught = true;

                                                                    // We want the date as if it were "from the top" of the droparea
                                                                    const posDate = new Date(backgroundDayMouseArea.addDate.getFullYear(), backgroundDayMouseArea.addDate.getMonth(), backgroundDayMouseArea.addDate.getDate(), backgroundRectangle.index, dropAreaRepeater.minutes * index);

                                                                    const startOffset = posDate.getTime() - drop.source.occurrenceDate.getTime();

                                                                    KalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, startOffset, startOffset, drop.source.occurrenceDate, drop.source);

                                                                } else if(drop.source.objectName === "multiDayIncidenceDelegateBackgroundBackground") {
                                                                    incidenceWrapper.incidenceItem = Kalendar.CalendarManager.incidenceItem(drop.source.incidencePtr);

                                                                    const pos = mapToItem(pathView, dropAreaHighlightRectangle.x, dropAreaHighlightRectangle.y);
                                                                    drop.source.caughtX = pos.x + incidenceSpacing;
                                                                    drop.source.caughtY = pos.y + incidenceSpacing;
                                                                    drop.source.caught = true;

                                                                    // We want the date as if it were "from the top" of the droparea
                                                                    const startPosDate = new Date(backgroundDayMouseArea.addDate.getFullYear(), backgroundDayMouseArea.addDate.getMonth(), backgroundDayMouseArea.addDate.getDate(), backgroundRectangle.index, dropAreaRepeater.minutes * index);
                                                                    // In case when incidence is converted to not be all day anymore, lets set it as 1h long
                                                                    const endPosDate = new Date(backgroundDayMouseArea.addDate.getFullYear(), backgroundDayMouseArea.addDate.getMonth(), backgroundDayMouseArea.addDate.getDate(), backgroundRectangle.index + 1, dropAreaRepeater.minutes * index);

                                                                    const startOffset = startPosDate.getTime() - drop.source.occurrenceDate.getTime();
                                                                    const endOffset = endPosDate.getTime() - drop.source.occurrenceEndDate.getTime();

                                                                    KalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, startOffset, endOffset, drop.source.occurrenceDate, drop.source);

                                                                } else { // The resize affects the end time
                                                                    incidenceWrapper.incidenceItem = Kalendar.CalendarManager.incidenceItem(drop.source.resizerSeparator.parent.incidencePtr);

                                                                    const pos = mapToItem(drop.source.resizerSeparator.parent, dropAreaHighlightRectangle.x, dropAreaHighlightRectangle.y);
                                                                    drop.source.resizerSeparator.parent.caughtHeight = (pos.y + dropAreaHighlightRectangle.height - incidenceSpacing)
                                                                    drop.source.resizerSeparator.parent.caught = true;

                                                                    // We want the date as if it were "from the bottom" of the droparea
                                                                    const minute = (dropAreaRepeater.minutes * (index + 1)) % 60;
                                                                    const isNextHour = minute === 0 && index !== 0;
                                                                    const hour = isNextHour ? backgroundRectangle.index + 1 : backgroundRectangle.index;

                                                                    const posDate = new Date(backgroundDayMouseArea.addDate.getFullYear(), backgroundDayMouseArea.addDate.getMonth(), backgroundDayMouseArea.addDate.getDate(), hour, minute);

                                                                    const endOffset = posDate.getTime() - drop.source.resizerSeparator.parent.occurrenceEndDate.getTime();

                                                                    KalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, 0, endOffset, drop.source.resizerSeparator.parent.occurrenceDate, drop.source.resizerSeparator.parent);
                                                                }
                                                            }

                                                            Rectangle {
                                                                id: dropAreaHighlightRectangle
                                                                anchors.fill: parent
                                                                color: Kirigami.Theme.positiveBackgroundColor
                                                                visible: hourlyViewIncidenceDropArea.containsDrag
                                                            }
                                                        }
                                                    }
                                                }

                                                DayMouseArea {
                                                    id: backgroundDayMouseArea
                                                    anchors.fill: parent
                                                    addDate: new Date(DateUtils.addDaysToDate(viewLoader.startDate, dayColumn.index).setHours(index))
                                                    onAddNewIncidence: KalendarUiUtils.setUpAdd(type, addDate, null, true)
                                                    onDeselect: KalendarUiUtils.appMain.incidenceInfoViewer.close()
                                                }
                                            }
                                        }
                                    }

                                    Loader {
                                        anchors.fill: parent
                                        asynchronous: !viewLoader.isCurrentView
                                        Repeater {
                                            id: hourlyIncidencesRepeater
                                            model: incidences

                                            delegate: Rectangle {
                                                id: hourlyIncidenceDelegateBackgroundBackground
                                                objectName: "hourlyIncidenceDelegateBackgroundBackground"

                                                readonly property int initialIncidenceHeight: (modelData.duration * pathView.periodHeight) - (pathView.incidenceSpacing * 2) + gridLineHeightCompensation - pathView.gridLineWidth
                                                readonly property real gridLineYCompensation: (modelData.starts / hourlyView.periodsPerHour) * pathView.gridLineWidth
                                                readonly property real gridLineHeightCompensation: (modelData.duration / hourlyView.periodsPerHour) * pathView.gridLineWidth
                                                property bool isOpenOccurrence: pathView.openOccurrence ?
                                                    pathView.openOccurrence.incidenceId === modelData.incidenceId : false

                                                x: pathView.incidenceSpacing + (modelData.priorTakenWidthShare * pathView.dayWidth)
                                                y: (modelData.starts * pathView.periodHeight) + pathView.incidenceSpacing + gridLineYCompensation
                                                width: (pathView.dayWidth * modelData.widthShare) - (pathView.incidenceSpacing * 2)
                                                height: initialIncidenceHeight
                                                radius: Kirigami.Units.smallSpacing
                                                color: Qt.rgba(0,0,0,0)
                                                visible: !modelData.allDay

                                                property alias mouseArea: mouseArea
                                                property var incidencePtr: modelData.incidencePtr
                                                property date occurrenceDate: modelData.startTime
                                                property date occurrenceEndDate: modelData.endTime
                                                property bool repositionAnimationEnabled: false
                                                property bool caught: false
                                                property real caughtX: x
                                                property real caughtY: y
                                                property real caughtHeight: height
                                                property real resizeHeight: height

                                                Drag.active: mouseArea.drag.active
                                                Drag.hotSpot.x: mouseArea.mouseX

                                                // Drag reposition animations -- when the incidence goes to the correct cell of the hourly grid
                                                Behavior on x {
                                                    enabled: repositionAnimationEnabled
                                                    NumberAnimation {
                                                        duration: Kirigami.Units.shortDuration
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }

                                                Behavior on y {
                                                    enabled: repositionAnimationEnabled
                                                    NumberAnimation {
                                                        duration: Kirigami.Units.shortDuration
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }

                                                Behavior on height {
                                                    enabled: repositionAnimationEnabled
                                                    NumberAnimation {
                                                        duration: Kirigami.Units.shortDuration
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }

                                                states: [
                                                    State {
                                                        when: hourlyIncidenceDelegateBackgroundBackground.mouseArea.drag.active
                                                        ParentChange { target: hourlyIncidenceDelegateBackgroundBackground; parent: pathView }
                                                        PropertyChanges { target: hourlyIncidenceDelegateBackgroundBackground; isOpenOccurrence: true }
                                                    },
                                                    State {
                                                        when: hourlyIncidenceResizer.mouseArea.drag.active
                                                        PropertyChanges { target: hourlyIncidenceDelegateBackgroundBackground; height: resizeHeight }
                                                    },
                                                    State {
                                                        when: hourlyIncidenceDelegateBackgroundBackground.caught
                                                        ParentChange { target: hourlyIncidenceDelegateBackgroundBackground; parent: pathView }
                                                        PropertyChanges {
                                                            target: hourlyIncidenceDelegateBackgroundBackground
                                                            repositionAnimationEnabled: true
                                                            x: caughtX
                                                            y: caughtY
                                                            height: caughtHeight
                                                        }
                                                    }
                                                ]

                                                IncidenceDelegateBackground {
                                                    id: incidenceDelegateBackground
                                                    isOpenOccurrence: parent.isOpenOccurrence
                                                    isDark: pathView.isDark
                                                }

                                                ColumnLayout {
                                                    id: incidenceContents

                                                    readonly property color textColor: isOpenOccurrence ?
                                                        (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                        LabelUtils.getIncidenceLabelColor(modelData.color, pathView.isDark)
                                                    readonly property bool isTinyHeight: parent.height <= Kirigami.Units.gridUnit

                                                    clip: true

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
                                                        font.strikeout: modelData.todoCompleted
                                                        renderType: Text.QtRendering
                                                        color: incidenceContents.textColor
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
                                                            color: incidenceContents.textColor
                                                            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                                            visible: parent.width > Kirigami.Units.gridUnit * 4
                                                        }
                                                        QQC2.Label {
                                                            id: timeLabel
                                                            Layout.fillWidth: true
                                                            horizontalAlignment: Text.AlignRight
                                                            text: modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat) + "–" + modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat)
                                                            wrapMode: Text.Wrap
                                                            renderType: Text.QtRendering
                                                            color: incidenceContents.textColor
                                                            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                                            visible: parent.width > Kirigami.Units.gridUnit * 3
                                                        }
                                                    }
                                                }

                                                IncidenceMouseArea {
                                                    id: mouseArea
                                                    preventStealing: !Kirigami.Settings.tabletMode && !Kirigami.Settings.isMobile
                                                    incidenceData: modelData
                                                    collectionId: modelData.collectionId

                                                    drag.target: !Kirigami.Settings.isMobile && !modelData.isReadOnly && pathView.dragDropEnabled ? parent : undefined
                                                    onReleased: parent.Drag.drop()

                                                    onViewClicked: KalendarUiUtils.setUpView(modelData, hourlyIncidenceDelegateBackgroundBackground)
                                                    onEditClicked: KalendarUiUtils.setUpEdit(incidencePtr)
                                                    onDeleteClicked: KalendarUiUtils.setUpDelete(incidencePtr, deleteDate)
                                                    onTodoCompletedClicked: KalendarUiUtils.completeTodo(incidencePtr)
                                                    onAddSubTodoClicked: KalendarUiUtils.setUpAddSubTodo(parentWrapper)
                                                }

                                                ResizerSeparator {
                                                    id: hourlyIncidenceResizer
                                                    objectName: "endDtResizeMouseArea"
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: hourlyIncidenceDelegateBackgroundBackground.radius
                                                    anchors.bottom: parent.bottom
                                                    anchors.right: parent.right
                                                    anchors.rightMargin: hourlyIncidenceDelegateBackgroundBackground.radius
                                                    height: 1
                                                    oversizeMouseAreaVertical: 2
                                                    z: Infinity
                                                    enabled: !Kirigami.Settings.isMobile && !modelData.isReadOnly
                                                    unhoveredColor: "transparent"

                                                    onDragPositionChanged: parent.resizeHeight = Math.max(pathView.periodHeight, hourlyIncidenceDelegateBackgroundBackground.initialIncidenceHeight + changeY)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Loader {
                            id: currentTimeMarkerLoader

                            active: pathView.currentDate >= viewLoader.startDate && pathView.currentDate < viewLoader.endDate

                            sourceComponent: Rectangle {
                                id: currentTimeMarker

                                width: pathView.dayWidth
                                height: pathView.gridLineWidth * 2
                                color: Kirigami.Theme.highlightColor
                                x: (viewLoader.daysFromWeekStart * pathView.dayWidth) + (viewLoader.daysFromWeekStart * pathView.gridLineWidth)
                                y: (pathView.currentDate.getHours() * pathView.gridLineWidth) + (hourlyView.minuteHeight * pathView.minutesFromStartOfDay) -
                                    (height / 2) - (pathView.gridLineWidth / 2)
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
