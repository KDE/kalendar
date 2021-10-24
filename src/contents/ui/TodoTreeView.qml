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
    signal viewTodo(var todoData, var collectionData)
    signal editTodo(var todoPtr, var collectionId)
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

    property alias model: todoModel

    currentIndex: -1
    clip: true

    MouseArea {
        id: incidenceDeselectorMouseArea
        anchors.fill: parent
        enabled: !Kirigami.Settings.isMobile
        parent: background
        onClicked: deselect()
        propagateComposedEvents: true
    }

    Kirigami.PlaceholderMessage {
        anchors.centerIn: parent
        visible: root.filter && root.filter.collectionId >= 0 && root.filterCollectionDetails.isFiltered && parent.count === 0
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
        visible: parent.count === 0 && root.filterCollectionDetails && !root.filterCollectionDetails.isFiltered
        text: root.showCompleted === Kalendar.TodoSortFilterProxyModel.ShowCompleteOnly ?
            i18n("No tasks completed") : i18n("No tasks left to complete")
        helpfulAction: Kirigami.Action {
            text: i18n("Create")
            icon.name: "list-add"
            onTriggered: root.addTodo(filterCollectionId);
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
        Layout.fillWidth: true

        Binding {
            target: contentItem.anchors
            property: "right"
            value: this.right
        }

        background.anchors.right: this.right
        separatorVisible: true

        contentItem: IncidenceMouseArea {
            implicitWidth: todoItemContents.implicitWidth
            implicitHeight: Kirigami.Settings.isMobile ?
                todoItemContents.implicitHeight + Kirigami.Units.largeSpacing : todoItemContents.implicitHeight + Kirigami.Units.smallSpacing
            incidenceData: model
            collectionId: model.collectionId

            onViewClicked: root.viewTodo(model, collectionDetails)
            onEditClicked: root.editTodo(model.incidencePtr, model.collectionId)
            onDeleteClicked: root.deleteTodo(model.incidencePtr, model.endTime ? model.endTime : model.startTime ? model.startTime : null)
            onTodoCompletedClicked: model.checked = model.checked === 0 ? 2 : 0
            onAddSubTodoClicked: root.addSubTodo(parentWrapper)

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
                        model: todoModel.data(todoModel.index(index, 0), Kalendar.ExtraTodoModel.CategoriesRole) // Getting categories from the model is *very* faulty

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

        onClicked: root.viewTodo(model, Kalendar.CalendarManager.getCollectionDetails(model.collectionId))
    }
}
