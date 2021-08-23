// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.4 as QQC1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar 1.0 as Kalendar
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Kirigami.Page {
    id: root
    title: i18n("Todos")

    signal addTodo()
    signal viewTodo(var todoData, var collectionData)
    signal editTodo(var todoPtr, var collectionId)
    signal deleteTodo(var todoPtr, date deleteDate)
    signal completeTodo(var todoPtr)

    property int filterCollectionId
    property var filterCollectionDetails: filterCollectionId ? Kalendar.CalendarManager.getCollectionDetails(filterCollectionId) : null
    property int sortBy
    property bool ascendingOrder: false
    readonly property color standardTextColor: Kirigami.Theme.textColor
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    Component.onCompleted: sortBy = Kalendar.TodoSortFilterProxyModel.EndTimeColumn // Otherwise crashes...

    //padding: Kirigami.Units.largeSpacing

    actions {
        main: Kirigami.Action {
            text: i18n("Add todo")
            icon.name: "list-add"
            onTriggered: root.addTodo();
        }
        left: Kirigami.Action {
            text: i18n("Sort...")
            icon.name: "view-sort"

            Kirigami.Action {
                text: i18n("By due date")
                onTriggered: root.sortBy = Kalendar.TodoSortFilterProxyModel.EndTimeColumn
            }
            Kirigami.Action {
                text: i18n("By priority")
                onTriggered: root.sortBy = Kalendar.TodoSortFilterProxyModel.PriorityIntColumn
            }
            Kirigami.Action {
                text: i18n("Alphabetically")
                onTriggered: root.sortBy = Kalendar.TodoSortFilterProxyModel.SummaryColumn
            }
        }
        right: Kirigami.Action {
            text: i18n("Show completed")
            icon.name: "task-complete"
            onTriggered: completedDrawer.open()
        }

    }

    Kirigami.OverlayDrawer {
        id: completedDrawer
        edge: Qt.BottomEdge

        height: applicationWindow().height * 0.75

        ColumnLayout {
            anchors.fill: parent
            RowLayout {
                Kirigami.Heading {
                    Layout.fillWidth: true
                    text: root.filterCollectionDetails ?
                        i18n("Completed todos in %1", root.filterCollectionDetails.displayName) : i18n("Completed todos")
                    color: root.filterCollectionDetails ?
                        LabelUtils.getIncidenceLabelColor(root.filterCollectionDetails.color, root.isDark) : Kirigami.Theme.textColor
                }
                QQC2.ToolButton {
                    icon.name: "dialog-close"
                    onClicked: completedDrawer.close()
                }
            }
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: completedDrawer.visible
                asynchronous: true
                sourceComponent: TodoTreeView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    filterCollectionId: root.filterCollectionId
                    showCompleted: Kalendar.TodoSortFilterProxyModel.ShowCompleteOnly
                    sortBy: root.sortBy
                    ascendingOrder: root.ascendingOrder
                    onViewTodo: {
                        root.viewTodo(todoData, collectionData);
                        completedDrawer.close();
                    }
                    onEditTodo: {
                        root.editTodo(todoPtr, collectionId);
                        completedDrawer.close();
                    }
                    onDeleteTodo: {
                        root.deleteTodo(todoPtr, deleteDate);
                        completedDrawer.close();
                    }
                    onCompleteTodo: root.completeTodo(todoPtr);
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            id: headerLayout

            Kirigami.Heading {
                Layout.fillWidth: true
                text: root.filterCollectionDetails ? root.filterCollectionDetails.displayName : i18n("All todos")
                font.weight: Font.Bold
                color: root.filterCollectionDetails ?
                    LabelUtils.getIncidenceLabelColor(root.filterCollectionDetails.color, root.isDark) : Kirigami.Theme.textColor
            }
            QQC2.ToolButton {
                property string sortTypeString: {
                    let directionString = root.ascendingOrder ? i18n("(ascending)") : i18n("(descending)");
                    switch(root.sortBy) {
                        case Kalendar.TodoSortFilterProxyModel.EndTimeColumn:
                            return i18n("by due date %1", directionString);
                        case Kalendar.TodoSortFilterProxyModel.PriorityIntColumn:
                            return i18n("by priority %1", directionString);
                        case Kalendar.TodoSortFilterProxyModel.SummaryColumn:
                            return i18n("alphabetically %1", directionString);
                    }
                }
                icon.name: root.ascendingOrder ? "view-sort-ascending" : "view-sort-descending"
                text: i18n("Sorted %1", sortTypeString)
                onClicked: root.ascendingOrder = !root.ascendingOrder
            }
        }

        Kirigami.SearchField {
            id: searchField
            Layout.fillWidth: true
            onTextChanged: incompleteView.model.filterTodoName(text);
        }

        TodoTreeView {
            id: incompleteView
            Layout.fillWidth: true
            Layout.fillHeight: true

            filterCollectionId: root.filterCollectionId
            showCompleted: Kalendar.TodoSortFilterProxyModel.ShowIncompleteOnly
            sortBy: root.sortBy
            ascendingOrder: root.ascendingOrder
            onViewTodo: root.viewTodo(todoData, collectionData)
            onEditTodo: root.editTodo(todoPtr, collectionId)
            onDeleteTodo: root.deleteTodo(todoPtr, deleteDate)
            onCompleteTodo: root.completeTodo(todoPtr);
        }
    }
}
