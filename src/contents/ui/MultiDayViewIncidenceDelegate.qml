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
    property real dayWidth: 0
    property int horizontalSpacing: 0 // In between incidence spaces
    property bool isDark: false
    readonly property bool isInCurrentMonth: reactToCurrentMonth && currentMonth ? modelData.endTime.getMonth() == root.month || modelData.startTime.getMonth() == root.month : true
    property bool isOpenOccurrence: openOccurrenceId ? openOccurrenceId === modelData.incidenceId : false
    property string openOccurrenceId: ""
    property real parentViewSpacing: 0
    property bool reactToCurrentMonth: true

    color: Qt.rgba(0, 0, 0, 0)
    height: parent.height
    opacity: isOpenOccurrence || isInCurrentMonth ? 1.0 : 0.5
    radius: Kirigami.Units.smallSpacing
    width: ((dayWidth + parentViewSpacing) * modelData.duration) - (horizontalSpacing * 2) - parentViewSpacing // Account for spacing added to x and for spacing at end of line
    x: ((dayWidth + parentViewSpacing) * modelData.starts) + horizontalSpacing
    z: 10

    IncidenceBackground {
        id: incidenceBackground
        isDark: parent.isDark
        isInCurrentMonth: parent.isInCurrentMonth
        isOpenOccurrence: parent.isOpenOccurrence
        reactToCurrentMonth: parent.reactToCurrentMonth
    }
    RowLayout {
        id: incidenceContents
        property bool spaceRestricted: parent.width < Kirigami.Units.gridUnit * 5
        property color textColor: LabelUtils.getIncidenceLabelColor(modelData.color, root.isDark)

        clip: true

        function otherMonthTextColor(color) {
            if (isDark) {
                if (LabelUtils.getDarkness(color) >= 0.5) {
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
            color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") : isInCurrentMonth ? incidenceContents.textColor : incidenceContents.otherMonthTextColor(modelData.color)
            isMask: true
            source: modelData.incidenceTypeIcon
            visible: !parent.spaceRestricted
        }
        QQC2.Label {
            Layout.fillWidth: true
            color: isOpenOccurrence ? (LabelUtils.isDarkColor(modelData.color) ? "white" : "black") : isInCurrentMonth ? incidenceContents.textColor : incidenceContents.otherMonthTextColor(modelData.color)
            elide: parent.spaceRestricted ? Text.ElideNone : Text.ElideRight // Eliding takes up space
            font.pointSize: parent.spaceRestricted ? Kirigami.Theme.smallFont.pointSize : Kirigami.Theme.defaultFont.pointSize
            font.weight: Font.Medium
            text: modelData.text
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
