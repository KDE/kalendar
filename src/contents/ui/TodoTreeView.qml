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
    property bool ascendingOrder: false
    property date currentDate: new Date()
    property var filter
    property var filterCollectionDetails
    property alias model: todoModel
    property int showCompleted: Kalendar.TodoSortFilterProxyModel.ShowAll
    property int sortBy: Kalendar.TodoSortFilterProxyModel.SummaryColumn

    clip: true
    currentIndex: -1

    signal addSubTodo(var parentWrapper)
    signal addTodo(int collectionId)
    signal completeTodo(var todoPtr)
    signal deleteTodo(var todoPtr, date deleteDate)
    signal deselect
    signal editTodo(var todoPtr, var collectionId)
    signal viewTodo(var todoData, var collectionData)

    MouseArea {
        id: incidenceDeselectorMouseArea
        anchors.fill: parent
        enabled: !Kirigami.Settings.isMobile
        parent: background
        propagateComposedEvents: true

        onClicked: deselect()
    }
    Kirigami.PlaceholderMessage {
        anchors.centerIn: parent
        text: i18n("Calendar is not enabled")
        visible: root.filter && root.filter.collectionId >= 0 && root.filterCollectionDetails.isFiltered && parent.count === 0

        helpfulAction: Kirigami.Action {
            icon.name: "gtk-yes"
            text: i18n("Enable")

            onTriggered: Kalendar.CalendarManager.allCalendars.setData(Kalendar.CalendarManager.allCalendars.index(root.filterCollectionDetails.allCalendarsRow, 0), 2, 10)
            // HACK: Last two numbers are Qt.Checked and Qt.CheckStateRole
        }
    }
    Kirigami.PlaceholderMessage {
        anchors.centerIn: parent
        text: root.showCompleted === Kalendar.TodoSortFilterProxyModel.ShowCompleteOnly ? i18n("No tasks completed") : i18n("No tasks left to complete")
        visible: parent.count === 0 && root.filterCollectionDetails && !root.filterCollectionDetails.isFiltered

        helpfulAction: Kirigami.Action {
            icon.name: "list-add"
            text: i18n("Create")

            onTriggered: root.addTodo(filterCollectionId)
        }
    }

    delegate: BasicTreeItem {
        id: listItem
        Layout.fillWidth: true
        background.anchors.right: this.right
        separatorVisible: true

        onClicked: root.viewTodo(model, Kalendar.CalendarManager.getCollectionDetails(model.collectionId))

        Binding {
            property: "right"
            target: contentItem.anchors
            value: this.right
        }

        contentItem: IncidenceMouseArea {
            collectionId: model.collectionId
            implicitHeight: Kirigami.Settings.isMobile ? todoItemContents.implicitHeight + Kirigami.Units.largeSpacing : todoItemContents.implicitHeight + Kirigami.Units.smallSpacing
            implicitWidth: todoItemContents.implicitWidth
            incidenceData: model

            onAddSubTodoClicked: root.addSubTodo(parentWrapper)
            onDeleteClicked: root.deleteTodo(model.incidencePtr, model.endTime ? model.endTime : model.startTime ? model.startTime : null)
            onEditClicked: root.editTodo(model.incidencePtr, model.collectionId)
            onTodoCompletedClicked: model.checked = model.checked === 0 ? 2 : 0
            onViewClicked: root.viewTodo(model, collectionDetails)

            GridLayout {
                id: todoItemContents
                columnSpacing: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing
                columns: 4
                rows: 2

                anchors {
                    left: parent.left
                    leftMargin: Kirigami.Units.smallSpacing
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                ColoredCheckbox {
                    id: todoCheckbox
                    Layout.column: 0
                    Layout.row: 0
                    Layout.rowSpan: root.width < Kirigami.Units.gridUnit * 28 || recurIcon.visible || dateLabel.visible ? 1 : 2
                    checked: model.todoCompleted
                    color: model.color
                    radius: 100

                    onClicked: completeTodo(model.incidencePtr)
                }
                QQC2.Label {
                    id: nameLabel
                    Layout.alignment: Qt.AlignVCenter
                    Layout.column: 1
                    Layout.columnSpan: root.width < Kirigami.Units.gridUnit * 28 && (recurIcon.visible || dateLabel.visible) ? 2 : 1
                    Layout.fillWidth: true
                    Layout.row: 0
                    Layout.rowSpan: occurrenceLayout.visible ? 1 : 2
                    font.strikeout: model.todoCompleted
                    font.weight: Font.Medium
                    text: model.text
                    wrapMode: Text.Wrap
                }
                Flow {
                    id: tagFlow
                    Layout.column: 2
                    Layout.columnSpan: root.width < Kirigami.Units.gridUnit * 28 ? 2 : 1
                    Layout.fillWidth: true
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    Layout.row: root.width < Kirigami.Units.gridUnit * 28 && (recurIcon.visible || dateLabel.visible || priorityLayout.visible) ? 1 : 0
                    Layout.rowSpan: root.width < Kirigami.Units.gridUnit * 28 ? 1 : 2
                    layoutDirection: Qt.RightToLeft
                    spacing: Kirigami.Units.largeSpacing

                    Repeater {
                        id: tagsRepeater
                        model: todoModel.data(todoModel.index(index, 0), Kalendar.ExtraTodoModel.CategoriesRole) // Getting categories from the model is *very* faulty

                        Tag {
                            implicitWidth: itemLayout.implicitWidth > tagFlow.width ? tagFlow.width : itemLayout.implicitWidth
                            showAction: false
                            text: modelData
                        }
                    }
                }
                RowLayout {
                    id: priorityLayout
                    Layout.alignment: Qt.AlignRight
                    Layout.column: 3
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    Layout.row: 0
                    Layout.rowSpan: root.width < Kirigami.Units.gridUnit * 28 ? 1 : 2
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
                    Layout.column: 1
                    Layout.fillWidth: true
                    Layout.row: 1
                    visible: !isNaN(model.endTime.getTime()) || model.recurs

                    QQC2.Label {
                        id: dateLabel
                        color: model.isOverdue ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                        font: Kirigami.Theme.smallFont
                        text: LabelUtils.todoDateTimeLabel(model.endTime, model.allDay, model.checked)
                        visible: !isNaN(model.endTime.getTime())
                    }
                    Kirigami.Icon {
                        id: recurIcon
                        Layout.maximumHeight: parent.height
                        source: "task-recurring"
                        visible: model.recurs
                    }
                }
            }
        }
    }
    sourceModel: Kalendar.TodoSortFilterProxyModel {
        id: todoModel
        calendar: Kalendar.CalendarManager.calendar
        filter: root.filter
        incidenceChanger: Kalendar.CalendarManager.incidenceChanger
        showCompleted: root.showCompleted
        sortAscending: root.ascendingOrder
        sortBy: root.sortBy
    }
}
