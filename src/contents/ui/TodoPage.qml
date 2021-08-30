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

    signal addTodo(int collectionId)
    signal viewTodo(var todoData, var collectionData)
    signal editTodo(var todoPtr, int collectionId)
    signal deleteTodo(var todoPtr, date deleteDate)
    signal completeTodo(var todoPtr)
    signal addSubTodo(var parentWrapper)

    property int filterCollectionId
    property var filterCollectionDetails: filterCollectionId ? Kalendar.CalendarManager.getCollectionDetails(filterCollectionId) : null
    property int sortBy
    property bool ascendingOrder: false
    readonly property color standardTextColor: Kirigami.Theme.textColor
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    Component.onCompleted: sortBy = Kalendar.TodoSortFilterProxyModel.EndTimeColumn // Otherwise crashes...

    //padding: Kirigami.Units.largeSpacing

    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    actions {
        main: Kirigami.Action {
            text: i18n("Add todo")
            icon.name: "list-add"
            onTriggered: root.addTodo(filterCollectionId);
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
            onTriggered: completedSheet.open()
        }

    }

    Kirigami.OverlaySheet {
        id: completedSheet

        title: root.filterCollectionDetails && root.filterCollectionId > -1 ?
            i18n("Completed todos in %1", root.filterCollectionDetails.displayName) : i18n("Completed todos")
        showCloseButton: true

        property var retainedTodoData
        property var retainedCollectionData

        contentItem: Loader {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 30
            height: applicationWindow().height * 0.8
            active: completedSheet.sheetOpen
            sourceComponent: QQC2.ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                TodoTreeView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    filterCollectionId: root.filterCollectionId
                    showCompleted: Kalendar.TodoSortFilterProxyModel.ShowCompleteOnly
                    sortBy: root.sortBy
                    ascendingOrder: root.ascendingOrder
                    onViewTodo: {
                        completedSheet.retainedTodoData = {
                            incidencePtr: todoData.incidencePtr,
                            text: todoData.text,
                            color: todoData.color,
                            startTime: todoData.startTime,
                            endTime: todoData.endTime,
                            durationString: todoData.durationString
                        };
                        completedSheet.retainedCollectionData = Kalendar.CalendarManager.getCollectionDetails(collectionData.id);
                        root.viewTodo(completedSheet.retainedTodoData, completedSheet.retainedCollectionData);
                        completedSheet.close();
                    }
                    onEditTodo: {
                        root.editTodo(todoPtr, collectionId);
                        completedSheet.close();
                    }
                    onDeleteTodo: {
                        root.deleteTodo(todoPtr, deleteDate);
                        completedSheet.close();
                    }
                    onCompleteTodo: root.completeTodo(todoPtr);
                    onAddSubTodo: root.addSubTodo(parentWrapper)
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
                text: root.filterCollectionDetails && root.filterCollectionId > -1 ?
                    root.filterCollectionDetails.displayName : i18n("All todos")
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
            onAddSubTodo: root.addSubTodo(parentWrapper)
        }
    }

    Kirigami.OverlaySheet {
        id: collectionPickerSheet
        title: i18n("Choose a todo calendar")

        property var incidenceWrapper: new IncidenceWrapper()

        ListView {
            implicitWidth: Kirigami.Units.gridUnit * 30
            currentIndex: -1
            header: ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right

            }

            model: Kalendar.CalendarManager.todoCollections
            delegate: Kirigami.BasicListItem {
                leftPadding: ((Kirigami.Units.gridUnit * 2) * (kDescendantLevel - 1)) + Kirigami.Units.largeSpacing
                enabled: model.checkState != null
                trailing: Rectangle {
                    height: parent.height * 0.8
                    width: height
                    radius: 3
                    color: model.collectionColor
                    visible: model.checkState != null
                }

                label: display

                onClicked: {
                    collectionPickerSheet.incidenceWrapper.collectionId = collectionId;
                    Kalendar.CalendarManager.addIncidence(collectionPickerSheet.incidenceWrapper);
                    collectionPickerSheet.close();
                    addField.clear();
                }
            }
        }
    }

    footer: Kirigami.ActionTextField {
        id: addField
        Layout.fillWidth: true
        placeholderText: i18n("Create a new todo...")

        function addTodo() {
            if(addField.text) {
                let incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', this, "incidence");
                incidenceWrapper.setNewTodo();
                incidenceWrapper.summary = addField.text;

                if(root.filterCollectionId && root.filterCollectionId >= 0) {
                    incidenceWrapper.collectionId = root.filterCollectionId;
                    Kalendar.CalendarManager.addIncidence(incidenceWrapper);
                    addField.clear();
                } else {
                    collectionPickerSheet.incidenceWrapper = incidenceWrapper;
                    collectionPickerSheet.open();
                }
            }
        }

        rightActions: Kirigami.Action {
            icon.name: "list-add"
            tooltip: i18n("Quickly add a new todo.")
            onTriggered: addField.addTodo()
        }
        onAccepted: addField.addTodo()
    }
}
