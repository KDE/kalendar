// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kirigamiaddons.treeview 1.0 as KirigamiAddonsTreeView

import org.kde.kalendar 1.0 as Kalendar
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

KirigamiAddonsTreeView.TreeListView {
    id: root

    signal viewTodo(var todoData, var collectionData)
    signal editTodo(var todoPtr, var collectionId)
    signal deleteTodo(var todoPtr, date deleteDate)
    signal completeTodo(var todoPtr)
    signal addSubTodo(var parentWrapper)

    property date currentDate: new Date()
    property int filterCollectionId
    property int showCompleted: Kalendar.TodoSortFilterProxyModel.ShowAll
    property int sortBy: Kalendar.TodoSortFilterProxyModel.EndTimeColumn
    onSortByChanged: todoModel.sortTodoModel(sortBy, ascendingOrder)
    property bool ascendingOrder: false
    onAscendingOrderChanged: todoModel.sortTodoModel(sortBy, ascendingOrder)

    property alias model: todoModel

    currentIndex: -1
    clip: true

    sourceModel: Kalendar.TodoSortFilterProxyModel {
        id: todoModel
        calendar: Kalendar.CalendarManager.calendar
        incidenceChanger: Kalendar.CalendarManager.incidenceChanger
        filterCollectionId: root.filterCollectionId ? root.filterCollectionId : -1
        showCompleted: root.showCompleted
    }
    delegate: KirigamiAddonsTreeView.BasicTreeItem {
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
            implicitHeight: todoItemContents.implicitHeight
            incidenceData: model
            collectionDetails: Kalendar.CalendarManager.getCollectionDetails(model.collectionId)

            onViewClicked: root.viewTodo(model, collectionDetails)
            onEditClicked: root.editTodo(model.incidencePtr, model.collectionId)
            onDeleteClicked: root.deleteTodo(model.incidencePtr, model.endTime ? model.endTime : model.startTime ? model.startTime : null)
            onTodoCompletedClicked: model.checked = model.checked === 0 ? 2 : 0
            onAddSubTodoClicked: root.addSubTodo(parentWrapper)

            GridLayout {
                id: todoItemContents

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width

                columns: 3
                rows: 2
                columnSpacing: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                ColoredCheckbox {
                    id: todoCheckbox

                    Layout.row: 0
                    Layout.column: 0

                    color: model.color
                    radius: 100
                    checked: model.todoCompleted
                    onClicked: completeTodo(model.incidencePtr)
                }

                QQC2.Label {
                    Layout.row: 0
                    Layout.column: 1
                    Layout.fillWidth: true
                    text: model.text
                    font.strikeout: model.todoCompleted
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.row: 0
                    Layout.column: 2
                    Layout.rowSpan: 2
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
                    Layout.row: 1
                    Layout.column: 1
                    Layout.fillWidth: true

                    QQC2.Label {
                        id: dateLabel
                        text: LabelUtils.todoDateTimeLabel(model.endTime, model.allDay, model.checked)
                        color: model.isOverdue ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                        font: Kirigami.Theme.smallFont
                        visible: !isNaN(model.endTime.getTime())
                    }
                    Kirigami.Icon {
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
