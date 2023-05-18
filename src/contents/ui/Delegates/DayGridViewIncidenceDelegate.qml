// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar 1.0 as Kalendar
import org.kde.kalendar.utils 1.0
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Item {
    id: incidenceDelegate

    required property int starts
    required property int duration
    required property var incidenceId
    required property var incidencePtr
    required property date occurrenceDate
    required property date occurrenceEndDate
    required property bool allDay
    required property bool isDark

    property real dayWidth: 0
    property real parentViewSpacing: 0
    property int horizontalSpacing: 0 // In between incidence spaces
    property real radius: Kirigami.Units.smallSpacing
    property string openOccurrenceId: ""
    property bool isOpenOccurrence: openOccurrenceId.length > 0 ?
        openOccurrenceId === incidenceDelegate.incidenceId : false
    property bool reactToCurrentMonth: true
    readonly property bool isInCurrentMonth: reactToCurrentMonth ?
        incidenceDelegate.occurrenceEndDate.getMonth() === root.month || incidenceDelegate.occurrenceDate.getMonth() === root.month :
        true

    property alias mouseArea: mouseArea
    property bool repositionAnimationEnabled: false
    property bool caught: false
    property real caughtX: 0
    property real caughtY: 0
    property bool dragDropEnabled: true

    x: ((dayWidth + parentViewSpacing) * incidenceDelegate.starts) + horizontalSpacing
    y: 0
    z: 10
    width: ((dayWidth + parentViewSpacing) * incidenceDelegate.duration) - (horizontalSpacing * 2) - parentViewSpacing // Account for spacing added to x and for spacing at end of line
    height: parent.height
    opacity: isOpenOccurrence || isInCurrentMonth ? 1.0 : 0.5

    Behavior on opacity {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutCubic
        }
    }

    // Drag reposition animations -- when the incidence goes to the correct cell of the monthgrid
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

    Drag.active: mouseArea.drag.active
    Drag.hotSpot.x: mouseArea.mouseX
    Drag.hotSpot.y: mouseArea.mouseY

    states: [
        State {
            when: !incidenceDelegate.mouseArea.drag.active && !incidenceDelegate.caught
        },
        State {
            when: incidenceDelegate.mouseArea.drag.active
            ParentChange { target: incidenceDelegate; parent: root }
            PropertyChanges {
                target: incidenceDelegate
                isOpenOccurrence: true
                y: 0
            }
        },
        State {
            when: incidenceDelegate.caught
            ParentChange { target: incidenceDelegate; parent: root }
            PropertyChanges {
                target: incidenceDelegate
                repositionAnimationEnabled: true
                x: caughtX
                y: caughtY
                opacity: 0
            }
        }
    ]

    IncidenceDelegateBackground {
        id: incidenceDelegateBackground
        isInDayGridView: true
        isOpenOccurrence: incidenceDelegate.isOpenOccurrence
        reactToCurrentMonth: incidenceDelegate.reactToCurrentMonth
        isInCurrentMonth: incidenceDelegate.isInCurrentMonth
        isDark: incidenceDelegate.isDark
        allDay: incidenceDelegate.allDay
    }

    RowLayout {
        id: incidenceContents
        clip: true

        readonly property bool spaceRestricted: parent.width < Kirigami.Units.gridUnit * 5

        readonly property color textColor: incidenceDelegateBackground.opacity > 0 ?
            LabelUtils.getIncidenceLabelColor(modelData.color, incidenceDelegate.isDark) : Kirigami.Theme.textColor
        readonly property color otherMonthTextColor: {
            if(incidenceDelegateBackground.visible && incidenceDelegateBackground.opacity > 0) {
                if (incidenceDelegate.isDark) {
                    return LabelUtils.getDarkness(modelData.color) >= 0.5 ?
                        Qt.lighter(modelData.color, 2) : Qt.lighter(modelData.color, 1.5);
                }

                return Qt.darker(modelData.color, 3);
            }

            return Kirigami.Theme.textColor;
        }
        readonly property color selectedContentColor: LabelUtils.isDarkColor(modelData.color) ? "white" : "black"
        readonly property color contentColor: incidenceDelegate.isOpenOccurrence ?
            selectedContentColor : incidenceDelegate.isInCurrentMonth ?
            textColor : otherMonthTextColor

        readonly property int leadingIconSize: Kirigami.Units.gridUnit / 2

        anchors {
            fill: parent
            leftMargin: spaceRestricted ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
            rightMargin: spaceRestricted ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
        }

        Rectangle {
            id: dotRectangle
            width: incidenceContents.leadingIconSize
            height: width
            radius: width / 2

            // We want equal alignment for items that both have a dot, don't have a dot because they are all-day, and
            // items that don't have a dot because they represent todos. Hidden items are compressed to a size of 0 so
            // instead we set the color to transparent.
            color: incidenceDelegate.allDay ? "transparent" :
            incidenceDelegate.isOpenOccurrence ? incidenceContents.selectedContentColor : modelData.color
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: modelData.text
            clip: true
            elide: parent.spaceRestricted ? Text.ElideNone : Text.ElideRight // Eliding takes up space
            font.weight: Font.Medium
            font.pointSize: parent.spaceRestricted ? Kirigami.Theme.smallFont.pointSize :
                Kirigami.Theme.defaultFont.pointSize
            font.strikeout: modelData.todoCompleted
            renderType: Text.QtRendering
            color: incidenceContents.contentColor
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
        }

        QQC2.Label {
            text: modelData.incidenceType === Kalendar.IncidenceWrapper.TypeTodo ?
                incidenceDelegate.occurrenceEndDate.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat) :
                incidenceDelegate.occurrenceDate.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat)
            font.pointSize: parent.spaceRestricted ? Kirigami.Theme.smallFont.pointSize :
                Kirigami.Theme.defaultFont.pointSize
            renderType: Text.QtRendering
            color: incidenceContents.contentColor
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
            visible: !incidenceDelegate.allDay
        }
    }

    IncidenceMouseArea {
        id: mouseArea
        incidenceData: modelData
        collectionId: modelData.collectionId

        preventStealing: !Kirigami.Settings.tabletMode && !Kirigami.Settings.isMobile
        drag.target: !Kirigami.Settings.isMobile && !modelData.isReadOnly && incidenceDelegate.dragDropEnabled ? parent : undefined
        onReleased: parent.Drag.drop()

        onViewClicked: KalendarUiUtils.setUpView(modelData, incidenceDelegate)
        onEditClicked: KalendarUiUtils.setUpEdit(modelData.incidencePtr)
        onDeleteClicked: KalendarUiUtils.setUpDelete(modelData.incidencePtr, deleteDate)
        onTodoCompletedClicked: KalendarUiUtils.completeTodo(incidencePtr)
        onAddSubTodoClicked: KalendarUiUtils.setUpAddSubTodo(parentWrapper)
    }
}
