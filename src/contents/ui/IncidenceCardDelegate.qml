// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar 1.0 as Kalendar
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Kirigami.AbstractCard {
    id: incidenceCard

    property real paddingSize: Kirigami.Settings.isMobile ?
        Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing
    property string openOccurrenceId: ""
    property bool isOpenOccurrence: openOccurrenceId ?
        openOccurrenceId === modelData.incidenceId : false
    property bool multiday: modelData.startTime.getDate() !== modelData.endTime.getDate()
    property int incidenceDays: DateUtils.fullDaysBetweenDates(modelData.startTime, modelData.endTime)
    property int dayOfMultidayIncidence: DateUtils.fullDaysBetweenDates(modelData.startTime, periodStartDate)

    property bool isDark: false
    property bool allowDrag: true
    property bool isLargeView: true
    property real implicitTimeLabelWidth: 0
    property real maxTimeLabelWidth: 0

    property alias mouseArea: incidenceMouseArea
    property var incidencePtr: modelData.incidencePtr
    property date occurrenceDate: modelData.startTime
    property date occurrenceEndDate: modelData.endTime
    property bool repositionAnimationEnabled: false
    property bool caught: false
    property real caughtX: 0
    property real caughtY: 0

    Drag.active: mouseArea.drag.active
    Drag.hotSpot.x: mouseArea.mouseX
    Drag.hotSpot.y: mouseArea.mouseY

    Layout.fillWidth: true
    topPadding: paddingSize
    bottomPadding: paddingSize

    showClickFeedback: true
    background: IncidenceBackground {
        id: incidenceBackground
        isOpenOccurrence: parent.isOpenOccurrence
        isDark: incidenceCard.isDark
    }

    Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }

    // Drag reposition animations -- when the incidence goes to the section of the view
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

    states: [
        State {
            when: incidenceCard.mouseArea.drag.active
            ParentChange { target: incidenceCard; parent: root }
            PropertyChanges { target: incidenceCard; isOpenOccurrence: true }
        },
        State {
            when: incidenceCard.caught
            ParentChange { target: incidenceCard; parent: root }
            PropertyChanges {
                target: incidenceCard
                repositionAnimationEnabled: true
                x: caughtX
                y: caughtY
                opacity: 0
            }
        }
    ]

    contentItem: GridLayout {
        id: cardContents

        columns: incidenceCard.isLargeView ? 3 : 2
        rows: incidenceCard.isLargeView ? 1 : 2

        property color textColor:  LabelUtils.getIncidenceLabelColor(modelData.color, incidenceCard.isDark)

        RowLayout {
            Kirigami.Icon {
                Layout.fillHeight: true
                source:  modelData.incidenceTypeIcon
                isMask: true
                color: incidenceCard.isOpenOccurrence ?
                    (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                    cardContents.textColor
                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
            }

            QQC2.Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.column: 0
                Layout.row: 0
                Layout.columnSpan: incidenceCard.isLargeView ? 2 : 1

                color: incidenceCard.isOpenOccurrence ?
                    (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                    cardContents.textColor
                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                text: {
                    if(incidenceCard.multiday) {
                        return i18nc("%1 is the name of the event", "%1 (Day %2 of %3)", modelData.text, incidenceCard.dayOfMultidayIncidence, incidenceCard.incidenceDays);
                    } else {
                        return modelData.text;
                    }
                }
                elide: Text.ElideRight
                font.weight: Font.Medium
                font.strikeout: modelData && modelData.todoCompleted
            }
        }

        RowLayout {
            id: additionalIcons

            Layout.column: 1
            Layout.row: 0

            visible: modelData && (modelData.hasReminders || modelData.recurs)

            Kirigami.Icon {
                id: recurringIcon
                Layout.fillHeight: true
                source: "appointment-recurring"
                isMask: true
                color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                    cardContents.textColor
                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                visible: modelData && modelData.recurs
            }
            Kirigami.Icon {
                id: reminderIcon
                Layout.fillHeight: true
                source: "appointment-reminder"
                isMask: true
                color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                    cardContents.textColor
                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                visible: modelData && modelData.hasReminders
            }
        }


        QQC2.Label {
            id: timeLabel

            Layout.fillHeight: true
            // This way all the icons are aligned
            Layout.maximumWidth: incidenceCard.maxTimeLabelWidth
            Layout.minimumWidth: incidenceCard.maxTimeLabelWidth
            Layout.column: incidenceCard.isLargeView ? 2 : 0
            Layout.row: incidenceCard.isLargeView ? 0 : 1

            horizontalAlignment: incidenceCard.isLargeView ? Text.AlignRight : Text.AlignLeft
            color: incidenceCard.isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                cardContents.textColor
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
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
                    i18n("Runs All Day")
                }
            }
            Component.onCompleted: incidenceCard.implicitTimeLabelWidth = implicitWidth
        }
    }

    IncidenceMouseArea {
        id: incidenceMouseArea

        preventStealing: !Kirigami.Settings.tabletMode && !Kirigami.Settings.isMobile
        incidenceData: modelData
        collectionId:  modelData.collectionId

        drag.target: !Kirigami.Settings.isMobile && !modelData.isReadOnly && incidenceCard.allowDrag ? incidenceCard : undefined
        onReleased: incidenceCard.Drag.drop()

        onViewClicked: viewIncidence(modelData) // These signals provided by parent views
        onEditClicked: editIncidence(incidencePtr)
        onDeleteClicked: deleteIncidence(incidencePtr, deleteDate)
        onTodoCompletedClicked: completeTodo(incidencePtr)
        onAddSubTodoClicked: addSubTodo(parentWrapper)
    }
}
