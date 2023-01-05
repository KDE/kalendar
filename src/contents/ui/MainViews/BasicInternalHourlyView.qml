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

Column {
    id: viewColumn
    spacing: 0

    property var openOccurrence: ({})

    property int daysToShow: 7

    property date currentDate: new Date() // Needs to get updated for marker to move, done from main.qml
    property date startDate: DateUtils.getFirstDayOfWeek(currentDate)
    property date endDate: DateUtils.addDaysToDate(startDate, viewColumn.daysToShow)

    readonly property int day: startDate.getDate()
    readonly property int month: startDate.getMonth()
    readonly property int year: startDate.getFullYear()
    readonly property int daysFromWeekStart: DateUtils.fullDaysBetweenDates(startDate, currentDate) - 1

    readonly property int currentDay: currentDate.getDate()
    readonly property int currentMonth: currentDate.getMonth()
    readonly property int currentYear: currentDate.getFullYear()

    readonly property int minutesFromStartOfDay: (currentDate.getHours() * 60) + currentDate.getMinutes()
    readonly property bool isDark: KalendarUiUtils.darkMode
    property bool dragDropEnabled: true

    property int allDayViewDelegateHeight: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing

    property int periodLength: 15
    property real scrollbarWidth: 0
    readonly property real dayWidth: ((width - hourLabelWidth - leftPadding - scrollbarWidth) / daysToShow) - gridLineWidth
    readonly property real incidenceSpacing: Kirigami.Units.smallSpacing / 2
    readonly property real gridLineWidth: 1.0
    readonly property real hourLabelWidth: hourLabelMetrics.boundingRect(new Date(0,0,0,0,0,0,0).toLocaleTimeString(Qt.locale(), Locale.NarrowFormat)).width +
        Kirigami.Units.largeSpacing * 2.5

    property real zoom: 1.0
    readonly property real periodHeight: Kirigami.Units.gridUnit * zoom

    Connections {
        target: pointergestureswayland
        function onPinchGestureStarted() {
            pointergestureswayland.startZoom = viewColumn.zoom;
        }

        function onPinchZoomChanged(zoom) {
            console.error(viewColumn.zoom)
            if (zoom > 2.0) {
                zoom = 2.0;
            }
            if (zoom < 0.75) {
                zoom = 0.75;
            }
            viewColumn.zoom = zoom;
        }
    }

    property int multiDayLinesShown: 0
    property bool isCurrentItem: true

    property real scrollPosition: 0

    readonly property alias hourScrollView: hourlyView

    property var hourLabels: []

    function setToDate(date, isInitialWeek = false, animate = false) {
        if(daysToShow % 7 === 0) {
            date = DateUtils.getFirstDayOfWeek(date);
        }

        startDate = date;

        if(isInitialWeek) {
            hourScrollView.setToCurrentTime(animate);
        }
    }

    Component.onCompleted: {
        if (!hourLabels || hourLabels.length === 0) {
            const infiniteCalendarModel = Qt.createQmlObject('import org.kde.kalendar 1.0; InfiniteCalendarViewModel {}',
                viewColumn, "infiniteCalendarModel");
            hourLabels = infiniteCalendarModel.hourlyViewLocalisedHourLabels;
        }
    }

    FontMetrics {
        id: hourLabelMetrics
        font.bold: true
    }

    FontMetrics {
        id: fontMetrics
    }

    Row {
        id: headingRow
        width: viewColumn.width
        spacing: viewColumn.gridLineWidth

        Kirigami.Heading {
            id: weekNumberHeading

            width: viewColumn.hourLabelWidth - viewColumn.gridLineWidth
            horizontalAlignment: Text.AlignRight
            padding: Kirigami.Units.smallSpacing
            level: 2
            text: DateUtils.getWeek(viewColumn.startDate, Qt.locale().firstDayOfWeek)
            color: Kirigami.Theme.disabledTextColor
            background: Rectangle {
                color: Kirigami.Theme.backgroundColor
            }
        }

        Repeater {
            id: dayHeadings

            model: viewColumn.daysToShow
            delegate: Rectangle {
                width: viewColumn.dayWidth
                implicitHeight: dayHeading.implicitHeight
                color: Kirigami.Theme.backgroundColor

                Kirigami.Heading { // Heading is out of the button so the color isn't disabled when the button is
                    id: dayHeading

                    property date headingDate: DateUtils.addDaysToDate(viewColumn.startDate, index)
                    property bool isToday: headingDate.getDate() === viewColumn.currentDay &&
                        headingDate.getMonth() === viewColumn.currentMonth &&
                        headingDate.getFullYear() === viewColumn.currentYear
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
                    enabled: viewColumn.daysToShow > 1
                    onClicked: KalendarUiUtils.openDayLayer(dayHeading.headingDate)
                }
            }
        }
        Rectangle { // Cover up the shadow of headerTopSeparator above the scrollbar
            color: Kirigami.Theme.backgroundColor
            height: parent.height
            width: viewColumn.scrollbarWidth
        }
    }

    Kirigami.Separator {
        id: headerTopSeparator
        width: viewColumn.width
        height: viewColumn.gridLineWidth
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
        width: viewColumn.width
        height: actualHeight
        visible: allDayViewLoader.active

        readonly property int minHeight: Kirigami.Units.gridUnit *2
        readonly property int maxHeight: viewColumn.height / 3
        readonly property int lineHeight: viewColumn.multiDayLinesShown > 0 ?
            viewColumn.multiDayLinesShown * (viewColumn.allDayViewDelegateHeight + viewColumn.incidenceSpacing) + Kirigami.Units.smallSpacing :
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
            width: viewColumn.hourLabelWidth
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
            border.width: viewColumn.gridLineWidth
            border.color: headerBottomSeparator.color

            Behavior on height { NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.InOutQuad
            } }

            Item {
                width: viewColumn.hourLabelWidth
                height: parent.height
                clip: true

                QQC2.ToolButton {
                    id: resetHeaderHeightButton
                    width: viewColumn.hourLabelWidth
                    text: i18nc("@action:button", "Reset")
                    onClicked: resetAnimation.start()
                }
            }
        }

        QQC2.Label {
            width: viewColumn.hourLabelWidth
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
            anchors.leftMargin: viewColumn.hourLabelWidth
            asynchronous: !viewColumn.isCurrentItem

            sourceComponent: Item {
                id: allDayViewItem
                implicitHeight: allDayHeader.actualHeight
                clip: true

                Repeater {
                    model: Kalendar.MultiDayIncidenceModel {
                        periodLength: viewColumn.daysToShow
                        filters: Kalendar.MultiDayIncidenceModel.AllDayOnly | Kalendar.MultiDayIncidenceModel.MultiDayOnly
                        showTodos: Kalendar.Config.showTodosInCalendarViews
                        showSubTodos: Kalendar.Config.showSubtodosInCalendarViews
                        model: Kalendar.IncidenceOccurrenceModel {
                            start: viewColumn.startDate
                            length: viewColumn.daysToShow
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
                            spacing: viewColumn.gridLineWidth
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
                                        spacing: viewColumn.incidenceSpacing

                                        ListView {
                                            id: allDayIncidencesBackgroundView
                                            anchors.fill: parent
                                            spacing: viewColumn.gridLineWidth
                                            orientation: Qt.Horizontal
                                            z: -1

                                            Kirigami.Separator {
                                                anchors.fill: parent
                                                anchors.rightMargin: viewColumn.scrollbarWidth
                                                z: -1
                                            }

                                            model: viewColumn.daysToShow
                                            delegate: Rectangle {
                                                id: multiDayViewBackground

                                                readonly property date date: DateUtils.addDaysToDate(viewColumn.startDate, index)
                                                readonly property bool isToday: date.getDate() === viewColumn.currentDay &&
                                                    date.getMonth() === viewColumn.currentMonth &&
                                                    date.getFullYear() === viewColumn.currentYear

                                                width: viewColumn.dayWidth
                                                height: linesListViewScrollView.height
                                                color: multiDayViewIncidenceDropArea.containsDrag ?  Kirigami.Theme.positiveBackgroundColor :
                                                    isToday ? Kirigami.Theme.activeBackgroundColor : Kirigami.Theme.backgroundColor

                                                DayMouseArea {
                                                    id: listViewMenu
                                                    anchors.fill: parent

                                                    addDate: parent.date
                                                    onAddNewIncidence: KalendarUiUtils.setUpAdd(type, addDate)
                                                    onDeselect: KalendarUiUtils.appMain.incidenceInfoViewer.close()

                                                    DropArea {
                                                        id: multiDayViewIncidenceDropArea
                                                        anchors.fill: parent
                                                        z: 9999
                                                        onDropped: if(viewColumn.isCurrentItem) {
                                                            const pos = mapToItem(viewColumn, x, y);
                                                            drop.source.caughtX = pos.x + viewColumn.incidenceSpacing;
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
                                            viewColumn.multiDayLinesShown = count
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
                                                    dayWidth: viewColumn.dayWidth
                                                    height: viewColumn.allDayViewDelegateHeight
                                                    parentViewSpacing: viewColumn.gridLineWidth
                                                    horizontalSpacing: linesRepeater.spacing
                                                    openOccurrenceId: viewColumn.openOccurrence ? viewColumn.openOccurrence.incidenceId : ""
                                                    isDark: viewColumn.isDark
                                                    reactToCurrentMonth: false
                                                    dragDropEnabled: viewColumn.dragDropEnabled
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
        width: viewColumn.width
        height: viewColumn.gridLineWidth
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

        readonly property real periodsPerHour: 60 / viewColumn.periodLength
        readonly property real daySections: (60 * 24) / viewColumn.periodLength
        readonly property real dayHeight: (daySections * viewColumn.periodHeight) + (viewColumn.gridLineWidth * 23)
        readonly property real hourHeight: periodsPerHour * viewColumn.periodHeight
        readonly property real minuteHeight: hourHeight / 60
        readonly property Item vScrollBar: QQC2.ScrollBar.vertical

        property int actualHeight: {
            let h = viewColumn.height - headerBottomSeparator.height - headerTopSeparator.height - headingRow.height;
            if (allDayHeader.visible) {
                h -= allDayHeader.height;
            }
            return h;
        }

        function setToCurrentTime(animate = false) {
            if(currentTimeMarkerLoader.active) {
                const viewHeight = (applicationWindow().height - applicationWindow().pageStack.globalToolBar.height - headerBottomSeparator.height - allDayHeader.height - headerTopSeparator.height - headingRow.height - Kirigami.Units.gridUnit);
                // Since we position with anchors, height is 0 -- must calc manually

                const timeMarkerY = (viewColumn.currentDate.getHours() * viewColumn.gridLineWidth) + (hourlyView.minuteHeight * viewColumn.minutesFromStartOfDay) - (height / 2) - (viewColumn.gridLineWidth / 2)
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

        Component.onCompleted: {
            if(!Kirigami.Settings.isMobile) viewColumn.scrollbarWidth = hourlyView.QQC2.ScrollBar.vertical.width;
            if(currentTimeMarkerLoader.active && viewColumn.initialWeek) {
                setToCurrentTime();
            }
        }

        NumberAnimation on QQC2.ScrollBar.vertical.position {
            id: scrollAnimation
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }

        Connections {
            target: hourlyView.QQC2.ScrollBar.vertical
            function onWidthChanged() {
                if(!Kirigami.Settings.isMobile) viewColumn.scrollbarWidth = hourlyView.QQC2.ScrollBar.vertical.width;
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
                width: viewColumn.hourLabelWidth

                Loader {
                    id: currentTimeLabelLoader

                    active: currentTimeMarkerLoader.active
                    sourceComponent: QQC2.Label {
                        id: currentTimeLabel

                        width: viewColumn.hourLabelWidth
                        color: Kirigami.Theme.highlightColor
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight
                        rightPadding: Kirigami.Units.smallSpacing
                        y: Math.max(0, (viewColumn.currentDate.getHours() * viewColumn.gridLineWidth) + (hourlyView.minuteHeight * viewColumn.minutesFromStartOfDay) - (implicitHeight / 2)) - (viewColumn.gridLineWidth / 2)
                        z: 100

                        text: viewColumn.currentDate.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat)

                    }
                }

                Repeater {
                    model: viewColumn.hourLabels

                    delegate: QQC2.Label {
                        property real textYTop: y
                        property real textYBottom: y + fontMetrics.height
                        property bool overlapWithCurrentTimeLabel: currentTimeLabelLoader.active &&
                            ((hourLabelsColumn.currentTimeLabelTop <= textYTop && hourLabelsColumn.currentTimeLabelBottom >= textYTop) ||
                            (hourLabelsColumn.currentTimeLabelTop < textYBottom && hourLabelsColumn.currentTimeLabelBottom > textYBottom) ||
                            (hourLabelsColumn.currentTimeLabelTop >= textYTop && hourLabelsColumn.currentTimeLabelBottom <= textYBottom))

                        y: ((viewColumn.periodHeight * hourlyView.periodsPerHour) * (index + 1)) + (viewColumn.gridLineWidth * (index + 1)) -
                            (fontMetrics.height / 2) - (viewColumn.gridLineWidth / 2)
                        width: viewColumn.hourLabelWidth
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
                    spacing: viewColumn.gridLineWidth

                    Repeater {
                        id: dayColumnRepeater
                        model: Kalendar.HourlyIncidenceModel {
                           periodLength: viewColumn.periodLength
                           filters: Kalendar.MultiDayIncidenceModel.AllDayOnly | Kalendar.MultiDayIncidenceModel.MultiDayOnly
                           showTodos: Kalendar.Config.showTodosInCalendarViews
                           showSubTodos: Kalendar.Config.showSubtodosInCalendarViews
                           model: Kalendar.IncidenceOccurrenceModel {
                               start: viewColumn.startDate
                               length: viewColumn.daysToShow
                               calendar: Kalendar.CalendarManager.calendar
                               filter: Kalendar.Filter
                           }
                       }

                        delegate: Item {
                            id: dayColumn

                            readonly property int index: model.index
                            readonly property date columnDate: DateUtils.addDaysToDate(viewColumn.startDate, index)
                            readonly property bool isToday: columnDate.getDate() === viewColumn.currentDay &&
                                columnDate.getMonth() === viewColumn.currentMonth &&
                                columnDate.getFullYear() === viewColumn.currentYear

                            width: viewColumn.dayWidth
                            height: hourlyView.dayHeight
                            clip: true

                            Loader {
                                anchors.fill: parent
                                asynchronous: !viewColumn.isCurrentView
                                ListView {
                                    anchors.fill: parent
                                    spacing: viewColumn.gridLineWidth
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
                                                    onDropped: if(viewColumn.isCurrentItem) {
                                                        let incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', hourlyViewIncidenceDropArea, "incidence");
                                                        /* So when we drop the entire incidence card somewhere, we are dropping the delegate with object name "hourlyIncidenceDelegateBackgroundBackground" or "multiDayIncidenceDelegateBackgroundBackground" in case when all day event is converted to the hour incidence.
                                                         * However, when we are simply resizing, we are actually dropping the specific mouseArea within the delegate that handles
                                                         * the dragging for the incidence's bottom edge which has name "endDtResizeMouseArea". Hence why we check the object names
                                                         */
                                                        if(drop.source.objectName === "hourlyIncidenceDelegateBackgroundBackground") {
                                                            incidenceWrapper.incidenceItem = Kalendar.CalendarManager.incidenceItem(drop.source.incidencePtr);

                                                            const pos = mapToItem(viewColumn, dropAreaHighlightRectangle.x, dropAreaHighlightRectangle.y);
                                                            drop.source.caughtX = pos.x + incidenceSpacing;
                                                            drop.source.caughtY = pos.y + incidenceSpacing;
                                                            drop.source.caught = true;

                                                            // We want the date as if it were "from the top" of the droparea
                                                            const posDate = new Date(backgroundDayMouseArea.addDate.getFullYear(), backgroundDayMouseArea.addDate.getMonth(), backgroundDayMouseArea.addDate.getDate(), backgroundRectangle.index, dropAreaRepeater.minutes * index);

                                                            const startOffset = posDate.getTime() - drop.source.occurrenceDate.getTime();

                                                            KalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, startOffset, startOffset, drop.source.occurrenceDate, drop.source);

                                                        } else if(drop.source.objectName === "multiDayIncidenceDelegateBackgroundBackground") {
                                                            incidenceWrapper.incidenceItem = Kalendar.CalendarManager.incidenceItem(drop.source.incidencePtr);

                                                            const pos = mapToItem(viewColumn, dropAreaHighlightRectangle.x, dropAreaHighlightRectangle.y);
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
                                            addDate: new Date(DateUtils.addDaysToDate(viewColumn.startDate, dayColumn.index).setHours(index))
                                            onAddNewIncidence: KalendarUiUtils.setUpAdd(type, addDate, null, true)
                                            onDeselect: KalendarUiUtils.appMain.incidenceInfoViewer.close()
                                        }
                                    }
                                }
                            }

                            Loader {
                                anchors.fill: parent
                                asynchronous: !viewColumn.isCurrentView
                                Repeater {
                                    id: hourlyIncidencesRepeater
                                    model: incidences

                                    delegate: Rectangle {
                                        id: hourlyIncidenceDelegateBackgroundBackground
                                        objectName: "hourlyIncidenceDelegateBackgroundBackground"

                                        readonly property int initialIncidenceHeight: (modelData.duration * viewColumn.periodHeight) - (viewColumn.incidenceSpacing * 2) + gridLineHeightCompensation - viewColumn.gridLineWidth
                                        readonly property real gridLineYCompensation: (modelData.starts / hourlyView.periodsPerHour) * viewColumn.gridLineWidth
                                        readonly property real gridLineHeightCompensation: (modelData.duration / hourlyView.periodsPerHour) * viewColumn.gridLineWidth
                                        property bool isOpenOccurrence: viewColumn.openOccurrence ?
                                            viewColumn.openOccurrence.incidenceId === modelData.incidenceId : false

                                        x: viewColumn.incidenceSpacing + (modelData.priorTakenWidthShare * viewColumn.dayWidth)
                                        y: (modelData.starts * viewColumn.periodHeight) + viewColumn.incidenceSpacing + gridLineYCompensation
                                        width: (viewColumn.dayWidth * modelData.widthShare) - (viewColumn.incidenceSpacing * 2)
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
                                                ParentChange { target: hourlyIncidenceDelegateBackgroundBackground; parent: viewColumn }
                                                PropertyChanges { target: hourlyIncidenceDelegateBackgroundBackground; isOpenOccurrence: true }
                                            },
                                            State {
                                                when: hourlyIncidenceResizer.mouseArea.drag.active
                                                PropertyChanges { target: hourlyIncidenceDelegateBackgroundBackground; height: resizeHeight }
                                            },
                                            State {
                                                when: hourlyIncidenceDelegateBackgroundBackground.caught
                                                ParentChange { target: hourlyIncidenceDelegateBackgroundBackground; parent: viewColumn }
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
                                            isDark: viewColumn.isDark
                                        }

                                        ColumnLayout {
                                            id: incidenceContents

                                            readonly property color textColor: isOpenOccurrence ?
                                                (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                LabelUtils.getIncidenceLabelColor(modelData.color, viewColumn.isDark)
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

                                            drag.target: !Kirigami.Settings.isMobile && !modelData.isReadOnly && viewColumn.dragDropEnabled ? parent : undefined
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

                                            onDragPositionChanged: parent.resizeHeight = Math.max(viewColumn.periodHeight, hourlyIncidenceDelegateBackgroundBackground.initialIncidenceHeight + changeY)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Loader {
                    id: currentTimeMarkerLoader

                    active: viewColumn.currentDate >= viewColumn.startDate && viewColumn.currentDate < viewColumn.endDate

                    sourceComponent: Rectangle {
                        id: currentTimeMarker

                        width: viewColumn.dayWidth
                        height: viewColumn.gridLineWidth * 2
                        color: Kirigami.Theme.highlightColor
                        x: (viewColumn.daysFromWeekStart * viewColumn.dayWidth) + (viewColumn.daysFromWeekStart * viewColumn.gridLineWidth)
                        y: (viewColumn.currentDate.getHours() * viewColumn.gridLineWidth) + (hourlyView.minuteHeight * viewColumn.minutesFromStartOfDay) -
                            (height / 2) - (viewColumn.gridLineWidth / 2)
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
