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
    x: ((dayWidth + parentViewSpacing) * modelData.starts) + horizontalSpacing
    y: 0
    width: ((dayWidth + parentViewSpacing) * modelData.duration) - (horizontalSpacing * 2) - parentViewSpacing // Account for spacing added to x and for spacing at end of line
    height: parent.height
    opacity: isOpenOccurrence || isInCurrentMonth ?
        1.0 : 0.5
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

    Kirigami.ShadowedRectangle {
        id: incidenceBackground
        anchors.fill: parent
        color: isOpenOccurrence ? modelData.color :
            LabelUtils.getIncidenceBackgroundColor(modelData.color, root.isDark)
        visible: isOpenOccurrence || isInCurrentMonth
        radius: parent.radius

        shadow.size: Kirigami.Units.largeSpacing
        shadow.color: Qt.rgba(0.0, 0.0, 0.0, 0.2)
        shadow.yOffset: 2

        border.width: 1
        border.color: Kirigami.ColorUtils.tintWithAlpha(color, Kirigami.Theme.textColor, 0.2)
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
            visible: !parent.spaceRestricted
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: modelData.text
            elide: parent.spaceRestricted ? Text.ElideNone : Text.ElideRight // Eliding takes up space
            font.weight: Font.Medium
            font.pointSize: parent.spaceRestricted ? Kirigami.Theme.smallFont.pointSize :
            Kirigami.Theme.defaultFont.pointSize
            color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                isInCurrentMonth ? incidenceContents.textColor :
                incidenceContents.otherMonthTextColor(modelData.color)
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
