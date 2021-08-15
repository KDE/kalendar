// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar 1.0 as Kalendar
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Kirigami.ScrollablePage {
    id: root

    signal addIncidence(int type, date addDate)
    signal viewIncidence(var modelData, var collectionData)
    signal editIncidence(var incidencePtr, var collectionId)
    signal deleteIncidence(var incidencePtr, date deleteDate)
    signal completeTodo(var incidencePtr)

    property var openOccurrence
    property date selectedDate: new Date()
    property date startDate: DateUtils.getFirstDayOfMonth(selectedDate)
    property int month: startDate.getMonth()
    property int year: startDate.getFullYear()
    property int daysInMonth: new Date(selectedDate.getFullYear(), selectedDate.getMonth(), 0).getDate()
    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 30
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

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

    background: Rectangle {
        Kirigami.Theme.colorSet: root.isLarge ? Kirigami.Theme.Header : Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    actions {
        left: Kirigami.Action {
            icon.name: "go-previous"
            text: i18n("Previous month")
            onTriggered: setToDate(DateUtils.previousMonth(startDate))
            displayHint: Kirigami.DisplayHint.IconOnly
        }
        right: Kirigami.Action {
            icon.name: "go-next"
            text: i18n("Next month")
            onTriggered: setToDate(DateUtils.nextMonth(startDate))
            displayHint: Kirigami.DisplayHint.IconOnly
        }
        main: Kirigami.Action {
            icon.name: "go-jump-today"
            text: i18n("Today")
            onTriggered: setToDate(new Date())
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
         * 3. Delegate's Separator's spacing gives same space (minus some adjustment) between it and dayGrid
         */
        Layout.bottomMargin: Kirigami.Units.largeSpacing * 5
        highlightRangeMode: ListView.ApplyRange
        onCountChanged: root.moveToSelected()

        Component {
            id: monthHeaderComponent
            Kirigami.ItemViewHeader {
                //backgroundImage.source: "../banner.jpg"
                title: Qt.locale().monthName(root.month)
                visible: Kalendar.Config.showMonthHeader
            }
        }

        header: Kalendar.Config.showMonthHeader ? monthHeaderComponent : null

        model: Kalendar.MultiDayIncidenceModel {
            periodLength: 1

            model: Kalendar.IncidenceOccurrenceModel {
                id: occurrenceModel
                objectName: "incidenceOccurrenceModel"
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
            onAddNewIncidence: addIncidence(type, addDate)

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.left: parent.left
                height: Kirigami.Settings.isMobile ? // Mobile adds extra padding
                    parent.height + Kirigami.Units.largeSpacing * 2 : parent.height + Kirigami.Units.largeSpacing
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                color: Kirigami.Theme.activeBackgroundColor
                visible: dayGrid.isToday
                z: 0
            }

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
                    visible: Kalendar.Config.showWeekHeaders &&
                        periodStartDate !== undefined &&
                        (periodStartDate.getDay() === Qt.locale().firstDayOfWeek || index === 0)
                }

                Kirigami.Separator {
                    id: topSeparator
                    Layout.fillWidth: true
                    Layout.bottomMargin: scheduleListView.spacing - Kirigami.Units.smallSpacing
                    z: 1
                }

                // Day + incidences
                GridLayout {
                    id: dayGrid

                    columns: 2
                    rows: 2

                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    Layout.rightMargin: Kirigami.Units.largeSpacing

                    property real dayLabelWidth: Kirigami.Units.gridUnit * 4
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
                        text: periodStartDate.toLocaleDateString(Qt.locale(), "ddd<br><b>dd</b>")
                        visible: incidences.length || dayGrid.isToday
                    }

                    ColumnLayout {
                        id: cardsColumn

                        Layout.fillWidth: true
                        visible: incidences.length || dayGrid.isToday

                        Kirigami.AbstractCard {
                            id: suggestCard

                            Layout.fillWidth: true

                            showClickFeedback: true
                            visible: !incidences.length && dayGrid.isToday

                            contentItem: QQC2.Label {
                                property string selectMethod: Kirigami.Settings.isMobile ? i18n("Tap") : i18n("Click")
                                text: i18n("Nothing on the books today. %1 to add something.", selectMethod)
                                wrapMode: Text.Wrap
                            }

                            onClicked: root.addIncidence(Kalendar.IncidenceWrapper.TypeEvent, periodStartDate)
                        }

                        Repeater {
                            model: incidences
                            Repeater {
                                id: incidencesRepeater
                                model: modelData

                                Kirigami.AbstractCard {
                                    id: incidenceCard

                                    Layout.fillWidth: true

                                    Kirigami.Theme.inherit: false
                                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                                    Kirigami.Theme.backgroundColor: isOpenOccurrence ? modelData.color :
                                        LabelUtils.getIncidenceBackgroundColor(modelData.color, root.isDark)
                                    Kirigami.Theme.highlightColor: Qt.darker(Kirigami.Theme.backgroundColor, 3)

                                    property real paddingSize: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing

                                    topPadding: paddingSize
                                    bottomPadding: paddingSize

                                    showClickFeedback: true

                                    property bool isOpenOccurrence: root.openOccurrence ?
                                        root.openOccurrence.incidenceId === modelData.incidenceId : false
                                    property var incidenceWrapper: new IncidenceWrapper()
                                    property bool multiday: modelData.startTime.getDate() !== modelData.endTime.getDate()
                                    property int incidenceDays: DateUtils.fullDaysBetweenDates(modelData.startTime, modelData.endTime)
                                    property int dayOfMultidayIncidence: DateUtils.fullDaysBetweenDates(modelData.startTime, periodStartDate)

                                    Component.onCompleted: {
                                        incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', incidenceInfo, "incidence");
                                        incidenceWrapper.incidencePtr = modelData.incidencePtr
                                    }

                                    contentItem: GridLayout {
                                        id: cardContents

                                        columns: root.isLarge ? 3 : 2
                                        rows: root.isLarge ? 1 : 2

                                        property color textColor: LabelUtils.getIncidenceLabelColor(modelData.color, root.isDark)

                                        RowLayout {
                                            Kirigami.Icon {
                                                Layout.fillHeight: true
                                                source: incidenceCard.incidenceWrapper.incidenceIconName
                                                color: cardContents.textColor
                                            }

                                            QQC2.Label {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Layout.column: 0
                                                Layout.row: 0
                                                Layout.columnSpan: root.isLarge ? 2 : 1

                                                color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                    cardContents.textColor
                                                text: {
                                                    if(incidenceCard.multiday) {
                                                        return i18n("%1 (Day %2 of %3)", modelData.text, incidenceCard.dayOfMultidayIncidence, incidenceCard.incidenceDays);
                                                    } else {
                                                        return modelData.text;
                                                    }
                                                }
                                                elide: Text.ElideRight
                                                font.weight: Font.Medium
                                            }
                                        }

                                        RowLayout {
                                            id: additionalIcons

                                            Layout.column: 1
                                            Layout.row: 0

                                            visible: incidenceCard.incidenceWrapper.remindersModel.rowCount() > 0 || incidenceCard.incidenceWrapper.recurrenceData.type

                                            Kirigami.Icon {
                                                id: recurringIcon
                                                Layout.fillHeight: true
                                                source: "appointment-recurring"
                                                color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                    cardContents.textColor
                                                visible: incidenceCard.incidenceWrapper.recurrenceData.type
                                            }
                                            Kirigami.Icon {
                                                id: reminderIcon
                                                Layout.fillHeight: true
                                                source: "appointment-reminder"
                                                color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                    cardContents.textColor
                                                visible: incidenceCard.incidenceWrapper.remindersModel.rowCount() > 0
                                            }
                                        }


                                        QQC2.Label {
                                            Layout.fillHeight: true
                                            // This way all the icons are aligned
                                            Layout.maximumWidth: Kirigami.Units.gridUnit * 7
                                            Layout.minimumWidth: Kirigami.Units.gridUnit * 7
                                            Layout.column: root.isLarge ? 2 : 0
                                            Layout.row: root.isLarge ? 0 : 1

                                            horizontalAlignment: root.isLarge ? Text.AlignRight : Text.AlignLeft
                                            color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                cardContents.textColor
                                            text: {
                                                if (modelData.allDay) {
                                                    i18n("Runs all day")
                                                } else if (modelData.startTime.getTime() === modelData.endTime.getTime()) {
                                                    modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
                                                } else if (!incidenceCard.multiday) {
                                                    i18nc("Displays times between incidence start and end", "%1 - %2",
                                                    modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat), modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                } else if (incidenceCard.dayOfMultidayIncidence === 1) {
                                                    i18n("Starts at %1", modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                } else if (incidenceCard.dayOfMultidayIncidence === incidenceCard.incidenceDays) {
                                                    i18n("Ends at %1", modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                } else { // In between multiday start/finish
                                                    i18n("Runs all day")
                                                }
                                            }
                                        }
                                    }

                                    IncidenceMouseArea {
                                        id: incidenceMouseArea

                                        incidenceData: modelData
                                        collectionDetails: incidences.length && Kalendar.CalendarManager.getCollectionDetails(modelData.collectionId)

                                        onViewClicked: root.viewIncidence(modelData, collectionData)
                                        onEditClicked: root.editIncidence(incidencePtr, collectionId)
                                        onDeleteClicked: root.deleteIncidence(incidencePtr, deleteDate)
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
