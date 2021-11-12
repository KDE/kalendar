// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar 1.0 as Kalendar
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Rectangle {
    id: incidenceDelegate

    x: ((dayWidth + parentViewSpacing) * modelData.starts) + horizontalSpacing
    z: 10
    width: ((dayWidth + parentViewSpacing) * modelData.duration) - (horizontalSpacing * 2) - parentViewSpacing // Account for spacing added to x and for spacing at end of line
    //Behavior on width { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
    height: parent.height
    opacity: isOpenOccurrence || isInCurrentMonth ?
        1.0 : 0.5
    Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }

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

    radius: Kirigami.Units.smallSpacing
    color: Qt.rgba(0,0,0,0)

    property real dayWidth: 0
    property real parentViewSpacing: 0
    property int horizontalSpacing: 0 // In between incidence spaces
    property string openOccurrenceId: ""
    property bool isOpenOccurrence: openOccurrenceId ?
        openOccurrenceId === modelData.incidenceId : false
    property bool reactToCurrentMonth: true
    readonly property bool isInCurrentMonth: reactToCurrentMonth && currentMonth ?
        modelData.endTime.getMonth() == root.month || modelData.startTime.getMonth() == root.month :
        true
    property bool isDark: false
    property alias mouseArea: mouseArea
    property var incidencePtr: modelData.incidencePtr
    property var collectionId: modelData.collectionId
    property bool repositionAnimationEnabled: false

    IncidenceBackground {
        id: incidenceBackground
        isOpenOccurrence: parent.isOpenOccurrence
        reactToCurrentMonth: parent.reactToCurrentMonth
        isInCurrentMonth: parent.isInCurrentMonth
        isDark: parent.isDark
    }

    RowLayout {
        id: incidenceContents
        clip: true
        property bool spaceRestricted: parent.width < Kirigami.Units.gridUnit * 5

        property color textColor: LabelUtils.getIncidenceLabelColor(modelData.color, root.isDark)

        function otherMonthTextColor(color) {
            if(isDark) {
                if(LabelUtils.getDarkness(color) >= 0.5) {
                    return Qt.lighter(color, 2);
                }
                return Qt.lighter(color, 1.5);
            }
            return Qt.darker(color, 3);
        }

        anchors {
            fill: parent
            leftMargin: spaceRestricted ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
            rightMargin: spaceRestricted ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
        }

        Kirigami.Icon {
            Layout.maximumHeight: parent.height
            Layout.maximumWidth: height

            source: modelData.incidenceTypeIcon
            isMask: true
            color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                isInCurrentMonth ? incidenceContents.textColor :
                incidenceContents.otherMonthTextColor(modelData.color)
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
            visible: !parent.spaceRestricted
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: modelData.text
            elide: parent.spaceRestricted ? Text.ElideNone : Text.ElideRight // Eliding takes up space
            font.weight: Font.Medium
            font.pointSize: parent.spaceRestricted ? Kirigami.Theme.smallFont.pointSize :
                Kirigami.Theme.defaultFont.pointSize
            font.strikeout: modelData.todoCompleted
            renderType: Text.QtRendering
            color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                isInCurrentMonth ? incidenceContents.textColor :
                incidenceContents.otherMonthTextColor(modelData.color)
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
        }
    }

    IncidenceMouseArea {
        id: mouseArea
        incidenceData: modelData
        collectionId: modelData.collectionId

        drag.target: !Kirigami.Settings.isMobile && !modelData.isReadOnly ? parent : undefined
        onReleased: parent.Drag.drop()

        onViewClicked: viewIncidence(modelData, collectionData)
        onEditClicked: editIncidence(incidencePtr, collectionId)
        onDeleteClicked: deleteIncidence(incidencePtr, deleteDate)
        onTodoCompletedClicked: completeTodo(incidencePtr)
        onAddSubTodoClicked: root.addSubTodo(parentWrapper)
    }
}
