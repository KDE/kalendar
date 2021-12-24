// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
//import org.kde.kirigamiaddons.treeview 1.0 as KirigamiAddonsTreeView

import org.kde.kalendar 1.0 as Kalendar
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

TreeListView {
    id: root

    signal addTodo(int collectionId)
    signal viewTodo(var todoData)
    signal editTodo(var todoPtr)
    signal deleteTodo(var todoPtr, date deleteDate)
    signal completeTodo(var todoPtr)
    signal addSubTodo(var parentWrapper)
    signal deselect()

    property date currentDate: new Date()
    property var filter
    property var filterCollectionDetails

    property int showCompleted: Kalendar.TodoSortFilterProxyModel.ShowAll
    property int sortBy: Kalendar.TodoSortFilterProxyModel.SummaryColumn
    property bool ascendingOrder: false
    property bool dragDropEnabled: true

    property alias model: todoModel
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    currentIndex: -1
    clip: true

    section.criteria: sortBy === Kalendar.TodoSortFilterProxyModel.SummaryColumn ?
        ViewSection.FirstCharacter : ViewSection.FullString
    section.property: switch(sortBy) {
        case Kalendar.TodoSortFilterProxyModel.PriorityColumn:
            return "topMostParentPriority";
        case Kalendar.TodoSortFilterProxyModel.DueDateColumn:
            return "topMostParentDueDate";
        case Kalendar.TodoSortFilterProxyModel.SummaryColumn:
        default:
            return "topMostParentSummary";
    }
    section.delegate: Kirigami.AbstractListItem {
        separatorVisible: false
        sectionDelegate: true
        hoverEnabled: false

        activeFocusOnTab: false

        contentItem: Kirigami.Heading {
            text: {
                switch(sortBy) {
                    case Kalendar.TodoSortFilterProxyModel.PriorityColumn:
                        return section !== "--" ? i18n("Priority %1", section) : i18n("No set priority");
                    case Kalendar.TodoSortFilterProxyModel.DueDateColumn:
                        let sectionDate = new Date(section);
                        return !isNaN(sectionDate.getTime()) ? LabelUtils.todoDateTimeLabel(new Date(section), true, false) : section;
                    case Kalendar.TodoSortFilterProxyModel.SummaryColumn:
                    default:
                        return section;
                }

            }
            readonly property bool isOverdue: section === i18n("Overdue")
            readonly property bool isToday: DateUtils.sameDay(new Date(section), new Date())

            level: 3
            font.weight: Font.Bold
            color: isOverdue ? Kirigami.Theme.negativeTextColor : isToday ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
        }
    }

    MouseArea {
        id: incidenceDeselectorMouseArea
        anchors.fill: parent
        enabled: !Kirigami.Settings.isMobile
        parent: background
        onClicked: deselect()
        propagateComposedEvents: true
    }

    Kirigami.PlaceholderMessage {
        id: allTasksPlaceholderMessage
        anchors.centerIn: parent
        visible: (!root.filter || !root.filter.collectionId || root.filter.collectionId < 0) && Kalendar.CalendarManager.enabledTodoCollections.length === 0 && parent.count === 0
        text: i18n("No task calendars enabled.")
    }

    Kirigami.PlaceholderMessage {
        id: collectionPlaceholderMessage
        anchors.centerIn: parent
        visible: root.filter && root.filter.collectionId >= 0 && !Kalendar.CalendarManager.enabledTodoCollections.includes(root.filter.collectionId) && parent.count === 0
        text: i18n("Calendar is not enabled")
        helpfulAction: Kirigami.Action {
            icon.name: "gtk-yes"
            text: i18n("Enable")
            onTriggered: Kalendar.CalendarManager.allCalendars.setData(Kalendar.CalendarManager.allCalendars.index(root.filterCollectionDetails.allCalendarsRow, 0), 2, 10)
            // HACK: Last two numbers are Qt.Checked and Qt.CheckStateRole
        }
    }

    Kirigami.PlaceholderMessage {
        anchors.centerIn: parent
        visible: parent.count === 0 && !allTasksPlaceholderMessage.visible && !collectionPlaceholderMessage.visible
        text: root.showCompleted === Kalendar.TodoSortFilterProxyModel.ShowCompleteOnly ?
            i18n("No tasks completed") : i18n("No tasks left to complete")
        helpfulAction: Kirigami.Action {
            text: i18n("Create")
            icon.name: "list-add"
            onTriggered: root.addTodo(filter.collectionId);
        }
    }

    sourceModel: Kalendar.TodoSortFilterProxyModel {
        id: todoModel
        calendar: Kalendar.CalendarManager.calendar
        incidenceChanger: Kalendar.CalendarManager.incidenceChanger
        filter: root.filter
        showCompleted: root.showCompleted
        sortBy: root.sortBy
        sortAscending: root.ascendingOrder
    }
    delegate: BasicTreeItem {
        id: listItem
        objectName: "taskDelegate"
        Layout.fillWidth: true

        Binding {
            target: contentItem.anchors
            property: "right"
            value: this.right
        }

        background.anchors.right: this.right
        separatorVisible: true
        decoration.decorationHighlightColor: model.color
        activeBackgroundColor: LabelUtils.getIncidenceBackgroundColor(model.color, root.isDark)
        onActiveBackgroundColorChanged: activeBackgroundColor.a = 0.15

        property alias mouseArea: mouseArea
        property var incidencePtr: model.incidencePtr
        property date occurrenceDate: model.startTime
        property date occurrenceEndDate: model.endTime
        property bool repositionAnimationEnabled: false
        property bool caught: false
        property real caughtX: x
        property real caughtY: y

        Drag.active: mouseArea.drag.active
        Drag.hotSpot.x: mouseArea.mouseX
        Drag.hotSpot.y: mouseArea.mouseY

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
                when: listItem.mouseArea.drag.active
                ParentChange { target: listItem; parent: applicationWindow().contentItem }
                PropertyChanges { target: listItem; highlighted: true; z: 9999 }
                PropertyChanges { target: applicationWindow().contentItem; clip: false }
                PropertyChanges { target: applicationWindow().globalDrawer; z: -1 }
            },
            State {
                when: listItem.caught
                ParentChange { target: listItem; parent: root }
                PropertyChanges {
                    target: listItem
                    repositionAnimationEnabled: true
                    x: caughtX
                    y: caughtY
                }
            }
        ]

        contentItem: IncidenceMouseArea {
            id: mouseArea

            implicitWidth: todoItemContents.implicitWidth
            implicitHeight: Kirigami.Settings.isMobile ?
                todoItemContents.implicitHeight + Kirigami.Units.largeSpacing : todoItemContents.implicitHeight + Kirigami.Units.smallSpacing
            incidenceData: model
            collectionId: model.collectionId
            propagateComposedEvents: true
            preventStealing: !Kirigami.Settings.tabletMode && !Kirigami.Settings.isMobile

            drag.target: !Kirigami.Settings.isMobile && !model.isReadOnly && root.dragDropEnabled ? listItem : undefined
            onReleased: listItem.Drag.drop()

            onViewClicked: root.viewTodo(model), listItem.clicked()
            onEditClicked: root.editTodo(model.incidencePtr)
            onDeleteClicked: root.deleteTodo(model.incidencePtr, model.endTime ? model.endTime : model.startTime ? model.startTime : null)
            onTodoCompletedClicked: model.checked = model.checked === 0 ? 2 : 0
            onAddSubTodoClicked: root.addSubTodo(parentWrapper)

            onClicked: root.viewTodo(model)

            GridLayout {
                id: todoItemContents

                anchors {
                    left: parent.left
                    leftMargin: Kirigami.Units.smallSpacing
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                columns: 4
                rows: 2
                columnSpacing: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                ColoredCheckbox {
                    id: todoCheckbox

                    Layout.row: 0
                    Layout.column: 0
                    Layout.rowSpan: root.width < Kirigami.Units.gridUnit * 28 || recurIcon.visible || dateLabel.visible ? 1 : 2

                    color: model.color
                    radius: 100
                    checked: model.todoCompleted
                    onClicked: completeTodo(model.incidencePtr)
                }

                QQC2.Label {
                    id: nameLabel
                    Layout.row: 0
                    Layout.column: 1
                    Layout.columnSpan: root.width < Kirigami.Units.gridUnit * 28 && (recurIcon.visible || dateLabel.visible) ? 2 : 1
                    Layout.rowSpan: occurrenceLayout.visible ? 1 : 2
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: model.text
                    font.strikeout: model.todoCompleted
                    font.weight: Font.Medium
                    wrapMode: Text.Wrap
                }

                Flow {
                    id: tagFlow
                    Layout.fillWidth: true
                    Layout.row: root.width < Kirigami.Units.gridUnit * 28 && (recurIcon.visible || dateLabel.visible || priorityLayout.visible) ? 1 : 0
                    Layout.column: 2
                    Layout.rowSpan: root.width < Kirigami.Units.gridUnit * 28 ? 1 : 2
                    Layout.columnSpan: root.width < Kirigami.Units.gridUnit * 28 ? 2 : 1
                    Layout.rightMargin: Kirigami.Units.largeSpacing

                    layoutDirection: Qt.RightToLeft
                    spacing: Kirigami.Units.largeSpacing

                    Repeater {
                        id: tagsRepeater
                        model: todoCategories // From todoModel

                        Tag {
                            implicitWidth: itemLayout.implicitWidth > tagFlow.width ? tagFlow.width : itemLayout.implicitWidth
                            text: modelData
                            showAction: false
                        }
                    }
                }

                RowLayout {
                    id: priorityLayout
                    Layout.row: 0
                    Layout.column: 3
                    Layout.rowSpan: root.width < Kirigami.Units.gridUnit * 28 ? 1 : 2
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    spacing: 0
                    visible: model.priority > 0

                    Kirigami.Icon {
                        Layout.maximumHeight: priorityLabel.height
                        source: "emblem-important-symbolic"
                    }
                    QQC2.Label {
                        id: priorityLabel
                        text: model.priority
                    }
                }

                RowLayout {
                    id: occurrenceLayout
                    Layout.row: 1
                    Layout.column: 1
                    Layout.fillWidth: true
                    visible: !isNaN(model.endTime.getTime()) || model.recurs

                    QQC2.Label {
                        id: dateLabel
                        text: LabelUtils.todoDateTimeLabel(model.endTime, model.allDay, model.checked)
                        color: model.isOverdue ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                        font: Kirigami.Theme.smallFont
                        visible: !isNaN(model.endTime.getTime())
                    }
                    Kirigami.Icon {
                        id: recurIcon
                        source: "task-recurring"
                        visible: model.recurs
                        Layout.maximumHeight: parent.height
                    }
                }
            }
        }
    }
}
