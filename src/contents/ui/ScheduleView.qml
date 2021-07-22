// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar 1.0 as Kalendar
import "dateutils.js" as DateUtils

Kirigami.ScrollablePage {
    id: root

    signal addEvent(date addDate)
    signal viewEvent(var modelData, var collectionData)
    signal editEvent(var eventPtr, var collectionId)
    signal deleteEvent(var eventPtr, date deleteDate)

    property date selectedDate: new Date()
    property date startDate: DateUtils.getFirstDayOfMonth(selectedDate)
    property int month: startDate.getMonth()
    property int year: startDate.getFullYear()
    property int daysInMonth: new Date(selectedDate.getFullYear(), selectedDate.getMonth(), 0).getDate()
    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 30

    onSelectedDateChanged: moveToSelected()

    function moveToSelected() {
        if (selectedDate.getDate() > 1) {
            scheduleListView.positionViewAtIndex(selectedDate.getDate() - 1, ListView.Beginning);
        } else {
            scheduleListView.positionViewAtBeginning()
        }
    }

    function setToDate(date) {
        selectedDate = date
        startDate = DateUtils.getFirstDayOfMonth(date);
        month = startDate.getMonth();
    }

    function isDarkColor(background) {
        var temp = Qt.darker(background, 1);
        var a = 1 - ( 0.299 * temp.r + 0.587 * temp.g + 0.114 * temp.b);
        return temp.a > 0 && a >= 0.5;
    }

    background: Rectangle {
        Kirigami.Theme.colorSet: root.isLarge ? Kirigami.Theme.Header : Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    actions {
        left: Kirigami.Action {
            icon.name: "go-previous"
            text: i18n("Previous month")
            onTriggered: setToDate(DateUtils.previousMonth(startDate))
        }
        right: Kirigami.Action {
            icon.name: "go-next"
            text: i18n("Next month")
            onTriggered: setToDate(DateUtils.nextMonth(startDate))
        }
    }

    padding: 0
    bottomPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

    ListView {
        id: scheduleListView

        spacing: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing
        /* Spacing in this view works thus:
         * 1. scheduleListView's spacing adds space between each day delegate component (including separators)
         * 2. Weekly listSectionHeader has spacing of the day delegate column removed from bottom margin
         * 3. Delegate's Separator's spacing gives same sapce (minus some adjustment) between it and dayGrid
         */
        Layout.bottomMargin: Kirigami.Units.largeSpacing * 5
        highlightRangeMode: ListView.ApplyRange
        onCountChanged: root.moveToSelected()

        header: Kirigami.ItemViewHeader {
            //backgroundImage.source: "../banner.jpg"
            title: Qt.locale().monthName(root.month)
        }

        model: Kalendar.MultiDayEventModel {
            periodLength: 1

            model: Kalendar.EventOccurrenceModel {
                id: occurrenceModel
                objectName: "eventOccurrenceModel"
                start: root.startDate
                length: root.daysInMonth
                filter: root.filter ? root.filter : {}
                calendar: Kalendar.CalendarManager.calendar
            }
        }

        delegate: DayMouseArea {
            id: dayMouseArea

            width: dayColumn.width
            height: dayColumn.height

            addDate: periodStartDate
            onAddNewEvent: addEvent(addDate)

            ColumnLayout {
                // Tip: do NOT hide an entire delegate.
                // This will very much screw up use of positionViewAtIndex.

                id: dayColumn

                width: scheduleListView.width

                Kirigami.ListSectionHeader {
                    id: weekHeading

                    Layout.fillWidth: true
                    Layout.bottomMargin: -dayColumn.spacing

                    text: {
                        let nextDay = DateUtils.getLastDayOfWeek( DateUtils.nextWeek(periodStartDate) );
                        if (nextDay.getMonth() !== periodStartDate.getMonth()) {
                            nextDay = new Date(nextDay.getFullYear(), nextDay.getMonth(), 0);
                        }

                        return periodStartDate.toLocaleDateString(Qt.locale(), "dddd <b>dd</b>") + " - " + nextDay.toLocaleDateString(Qt.locale(), "dddd <b>dd</b> MMMM");
                    }
                    visible: periodStartDate !== undefined &&
                    (periodStartDate.getDay() === Qt.locale().firstDayOfWeek || index === 0)
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.bottomMargin: scheduleListView.spacing - Kirigami.Units.smallSpacing
                }

                // Day + events
                GridLayout {
                    id: dayGrid

                    columns: 2
                    rows: 2

                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    Layout.rightMargin: Kirigami.Units.largeSpacing

                    property real dayLabelWidth: Kirigami.Units.gridUnit * 3
                    property bool isToday: new Date(periodStartDate).setHours(0,0,0,0) === new Date().setHours(0,0,0,0)

                    QQC2.Label {
                        id: smallDayLabel

                        Layout.alignment: Qt.AlignVCenter
                        Layout.maximumWidth: dayGrid.dayLabelWidth
                        Layout.minimumWidth: dayGrid.dayLabelWidth
                        padding: Kirigami.Units.smallSpacing
                        rightPadding: Kirigami.Units.largeSpacing
                        horizontalAlignment: Text.AlignRight

                        visible: !cardsColumn.visible
                        text: periodStartDate.toLocaleDateString(Qt.locale(), "ddd <b>dd</b>")
                        color: Kirigami.Theme.disabledTextColor
                    }

                    QQC2.Label {
                        id: emptyDayText

                        Layout.alignment: Qt.AlignVCenter
                        visible: !cardsColumn.visible
                        text: i18n("Clear day.")
                        color: Kirigami.Theme.disabledTextColor
                    }

                    Kirigami.Heading {
                        id: largeDayLabel

                        Layout.alignment: Qt.AlignTop
                        Layout.maximumWidth: dayGrid.dayLabelWidth
                        Layout.minimumWidth: dayGrid.dayLabelWidth
                        Layout.fillHeight: true
                        padding: Kirigami.Units.smallSpacing
                        rightPadding: Kirigami.Units.largeSpacing
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignTop

                        level: dayGrid.isToday ? 1 : 3
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        color: dayGrid.isToday ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                        text: periodStartDate.toLocaleDateString(Qt.locale(), "ddd\n<b>dd</b>")
                        visible: events.length || dayGrid.isToday
                    }

                    ColumnLayout {
                        id: cardsColumn

                        Layout.fillWidth: true
                        visible: events.length || dayGrid.isToday

                        Kirigami.AbstractCard {
                            id: suggestCard

                            Layout.fillWidth: true

                            showClickFeedback: true
                            visible: !events.length && dayGrid.isToday

                            contentItem: QQC2.Label {
                                property string selectMethod: Kirigami.Settings.isMobile ? i18n("Tap") : i18n("Click")
                                text: i18n("Nothing on the books today. %1 to add something.", selectMethod)
                                wrapMode: Text.Wrap
                            }

                            onClicked: root.addEvent()
                        }

                        Repeater {
                            model: events
                            Repeater {
                                id: eventsRepeater
                                model: modelData

                                Kirigami.AbstractCard {
                                    id: eventCard

                                    Layout.fillWidth: true

                                    Kirigami.Theme.inherit: false
                                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                                    Kirigami.Theme.backgroundColor: Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.8)
                                    Kirigami.Theme.highlightColor: Qt.darker(modelData.color, 2.5)

                                    property real paddingSize: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing

                                    topPadding: paddingSize
                                    bottomPadding: paddingSize

                                    showClickFeedback: true

                                    property var eventWrapper: new EventWrapper()
                                    property bool multiday: modelData.startTime.getDate() !== modelData.endTime.getDate()
                                    property int eventDays: DateUtils.fullDaysBetweenDates(modelData.startTime, modelData.endTime)
                                    property int dayOfMultidayEvent: DateUtils.fullDaysBetweenDates(modelData.startTime, periodStartDate)

                                    Component.onCompleted: {
                                        eventWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; EventWrapper {id: event}', eventInfo, "event");
                                        eventWrapper.eventPtr = modelData.eventPtr
                                    }

                                    contentItem: GridLayout {
                                        id: cardContents

                                        columns: root.isLarge ? 3 : 2
                                        rows: root.isLarge ? 1 : 2

                                        property color textColor: root.isDarkColor(Kirigami.Theme.backgroundColor) ? "white" : "black"

                                        RowLayout {
                                            Kirigami.Icon {
                                                Layout.fillHeight: true
                                                source: "tag-events"
                                                color: cardContents.textColor
                                                // TODO: This will need dynamic changing with implementation of to-dos/journals
                                            }

                                            QQC2.Label {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Layout.column: 0
                                                Layout.row: 0
                                                Layout.columnSpan: root.isLarge ? 2 : 1

                                                color: cardContents.textColor
                                                text: {
                                                    if(eventCard.multiday) {
                                                        return i18n("%1 (Day %2 of %3)", modelData.text, eventCard.dayOfMultidayEvent, eventCard.eventDays);
                                                    } else {
                                                        return modelData.text;
                                                    }
                                                }
                                                elide: Text.ElideRight
                                            }
                                        }

                                        RowLayout {
                                            id: additionalIcons

                                            Layout.column: 1
                                            Layout.row: 0

                                            visible: eventCard.eventWrapper.remindersModel.rowCount() > 0 //&& eventCard.eventWrapper.recurrenceData.type

                                            // TODO: Re-enable this when MR !8 is merged
                                            /*Kirigami.Icon {
                                                id: recurringIcon
                                                Layout.fillHeight: true
                                                source: "appointment-recurring"
                                                color: cardContents.textColor
                                                visible: eventCard.eventWrapper.recurrenceData.type
                                            }*/
                                            Kirigami.Icon {
                                                id: reminderIcon
                                                Layout.fillHeight: true
                                                source: "appointment-reminder"
                                                color: cardContents.textColor
                                                visible: eventCard.eventWrapper.remindersModel.rowCount() > 0
                                            }
                                        }


                                        QQC2.Label {
                                            Layout.fillHeight: true
                                            Layout.maximumWidth: Kirigami.Units.gridUnit * 6
                                            Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                                            Layout.column: root.isLarge ? 2 : 0
                                            Layout.row: root.isLarge ? 0 : 1

                                            horizontalAlignment: root.isLarge ? Text.AlignRight : Text.AlignLeft
                                            color: cardContents.textColor
                                            text: {
                                                if (modelData.allDay) {
                                                    i18n("Runs all day")
                                                } else if (modelData.startTime.getTime() === modelData.endTime.getTime()) {
                                                    modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
                                                } else if (!eventCard.multiday) {
                                                    i18nc("Displays times between incidence start and end", "%1 - %2",
                                                    modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat), modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                } else if (eventCard.dayOfMultidayEvent === 1) {
                                                    i18n("Starts at %1", modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                } else if (eventCard.dayOfMultidayEvent === eventCard.eventDays) {
                                                    i18n("Ends at %1", modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                } else { // In between multiday start/finish
                                                    i18n("Runs all day")
                                                }
                                            }
                                        }
                                    }

                                    IncidenceMouseArea {
                                        id: eventMouseArea

                                        eventData: modelData
                                        collectionDetails: events.length && Kalendar.CalendarManager.getCollectionDetails(modelData.collectionId)

                                        onViewClicked: root.viewEvent(modelData, collectionData)
                                        onEditClicked: root.editEvent(eventPtr, collectionId)
                                        onDeleteClicked: root.deleteEvent(eventPtr, deleteDate)
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
