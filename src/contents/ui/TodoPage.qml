// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0

import org.kde.kalendar 1.0 as Kalendar
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Kirigami.ScrollablePage {
    id: root

    signal addTodo(int collectionId)
    signal viewTodo(var todoData, var collectionData)
    signal editTodo(var todoPtr, int collectionId)
    signal deleteTodo(var todoPtr, date deleteDate)
    signal completeTodo(var todoPtr)
    signal addSubTodo(var parentWrapper)
    signal deselect

    // We need to store a copy of opened incidence data or we will lose it as we scroll the listviews.
    function retainTodoData(todoData, collectionData) {
        retainedTodoData = {
            incidencePtr: todoData.incidencePtr,
            incidenceId: todoData.incidenceId,
            collectionId: collectionData.id,
            text: todoData.text,
            color: todoData.color,
            startTime: todoData.startTime,
            endTime: todoData.endTime,
            durationString: todoData.durationString
        };
        retainedCollectionData = Kalendar.CalendarManager.getCollectionDetails(collectionData.id);
        viewTodo(retainedTodoData, retainedCollectionData);
    }

    property var retainedTodoData: {}
    property var retainedCollectionData: {}

    property var filter: {
        "collectionId": -1,
        "tags": [],
        "name": ""
    }
    property var filterCollectionDetails: root.filter && root.filter.collectionId >= 0 ?
        Kalendar.CalendarManager.getCollectionDetails(root.filter.collectionId) : null

    property int sortBy: switch (Kalendar.Config.sort) {
        case Kalendar.Config.DueTime:
            return Kalendar.TodoSortFilterProxyModel.EndTimeColumn;
        case Kalendar.Config.Priority:
            return Kalendar.TodoSortFilterProxyModel.PriorityIntColumn;
        case Kalendar.Config.Alphabetically:
            return Kalendar.TodoSortFilterProxyModel.SummaryColumn;
    }

    property bool ascendingOrder: Kalendar.Config.ascendingOrder

    readonly property color standardTextColor: Kirigami.Theme.textColor
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    padding: 0
    leftPadding: Kirigami.Units.largeSpacing

    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    actions {
        main: Kirigami.Action {
            text: i18n("Create")
            icon.name: "list-add"
            onTriggered: root.addTodo(root.filter.collectionId);
        }
        left: Kirigami.Action {
            text: i18n("Sort")
            icon.name: "view-sort"

            KActionFromAction {
                kalendarAction: "todoview_sort_by_due_date"
                checked: root.sortBy === Kalendar.TodoSortFilterProxyModel.EndTimeColumn
                onCheckedChanged: __action.checked = checked // Needed for the actions in the menu bars to be checked on load
            }
            KActionFromAction {
                kalendarAction: "todoview_sort_by_priority"
                checked: root.sortBy === Kalendar.TodoSortFilterProxyModel.PriorityIntColumn
                onCheckedChanged: __action.checked = checked
            }
            KActionFromAction {
                kalendarAction: "todoview_sort_alphabetically"
                checked: root.sortBy === Kalendar.TodoSortFilterProxyModel.SummaryColumn
                onCheckedChanged: __action.checked = checked
            }

            Kirigami.Action { separator: true }

            KActionFromAction {
                kalendarAction: "todoview_order_ascending"
                checked: root.ascendingOrder
                onCheckedChanged: __action.checked = checked
            }
            KActionFromAction {
                kalendarAction: "todoview_order_descending"
                checked: !root.ascendingOrder
                onCheckedChanged: __action.checked = checked
            }
        }
        right: KActionFromAction {
            kalendarAction: "todoview_show_completed"
            text: i18n("Show Completed")
        }

    }

    property Component completedSheetComponent: Kirigami.ScrollablePage {
        id: completedSheet
        title: root.filterCollectionDetails && root.filter && root.filter.collectionId > -1 ?
            i18n("Completed Tasks in %1", root.filterCollectionDetails.displayName) : i18n("Completed Tasks")

        TodoTreeView {
            id: completeView
            Layout.fillWidth: true
            Layout.fillHeight: true

            filter: root.filter
            filterCollectionDetails: root.filterCollectionDetails

            showCompleted: Kalendar.TodoSortFilterProxyModel.ShowCompleteOnly
            sortBy: root.sortBy
            ascendingOrder: root.ascendingOrder
            onAddTodo: {
                root.addTodo(collectionId)
                completedSheet.closeDialog();
            }
            onViewTodo: {
                root.retainTodoData(todoData, collectionData);
                completedSheet.closeDialog();
            }
            onEditTodo: {
                root.editTodo(todoPtr, collectionId);
                completedSheet.closeDialog();
            }
            onDeleteTodo: {
                root.deleteTodo(todoPtr, deleteDate);
                completedSheet.closeDialog();
            }
            onDeselect: root.deselect()
            onCompleteTodo: root.completeTodo(todoPtr);
            onAddSubTodo: root.addSubTodo(parentWrapper)
        }
    }

    Component {
        id: collectionPickerSheetComponent
        Kirigami.ScrollablePage {
            id: collectionPickerSheet
            title: i18n("Choose a Task Calendar")

            property var incidenceWrapper

            ListView {
                id: collectionsList
                implicitWidth: Kirigami.Units.gridUnit * 30
                currentIndex: -1
                header: ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right

                }

                model: KDescendantsProxyModel {
                    model: Kalendar.CalendarManager.todoCollections
                }

                delegate: DelegateChooser {
                    role: 'kDescendantExpandable'
                    DelegateChoice {
                        roleValue: true

                        Kirigami.BasicListItem {
                            label: display
                            labelItem.color: Kirigami.Theme.disabledTextColor
                            labelItem.font.weight: Font.DemiBold
                            topPadding: 2 * Kirigami.Units.largeSpacing
                            hoverEnabled: false
                            background: Item {}

                            separatorVisible: false

                            trailing: Kirigami.Icon {
                                width: Kirigami.Units.iconSizes.small
                                height: Kirigami.Units.iconSizes.small
                                source: model.kDescendantExpanded ? 'arrow-up' : 'arrow-down'
                                x: -4
                            }

                            onClicked: collectionsList.model.toggleChildren(index)
                        }
                    }

                    DelegateChoice {
                        roleValue: false
                        Kirigami.BasicListItem {
                            label: display
                            labelItem.color: Kirigami.Theme.textColor

                            hoverEnabled: false

                            separatorVisible: false

                            onClicked: {
                                collectionPickerSheet.incidenceWrapper.collectionId = collectionId;
                                Kalendar.CalendarManager.addIncidence(collectionPickerSheet.incidenceWrapper);
                                collectionPickerSheet.closeDialog();
                                addField.clear();
                            }

                            trailing: Rectangle {
                                color: model.collectionColor
                                radius: Kirigami.Units.smallSpacing
                                width: height
                                height: Kirigami.Units.iconSizes.small
                            }
                        }
                    }
                }
            }
        }
    }

    TodoTreeView {
        id: incompleteView
        z: 5
        Layout.fillWidth: true
        Layout.fillHeight: true

        filter: root.filter
        filterCollectionDetails: root.filterCollectionDetails

        showCompleted: Kalendar.TodoSortFilterProxyModel.ShowIncompleteOnly
        sortBy: root.sortBy
        ascendingOrder: root.ascendingOrder
        onAddTodo: root.addTodo(collectionId)
        onViewTodo: root.retainTodoData(todoData, collectionData)
        onEditTodo: root.editTodo(todoPtr, collectionId)
        onDeleteTodo: root.deleteTodo(todoPtr, deleteDate)
        onCompleteTodo: root.completeTodo(todoPtr);
        onAddSubTodo: root.addSubTodo(parentWrapper)
        onDeselect: root.deselect()
    }


    footer: Kirigami.ActionTextField {
        id: addField
        placeholderText: i18n("Create a New Task…")
        FontMetrics {
            id: textMetrics
        }

        implicitHeight: textMetrics.height + Kirigami.Units.largeSpacing + 1 // To align with 'Show all' button in sidebar

        background: Rectangle {
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Window
            color: Kirigami.Theme.backgroundColor
            Kirigami.Separator {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
            }
        }

        function addTodo() {
            if(addField.text) {
                let incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', this, "incidence");
                incidenceWrapper.setNewTodo();
                incidenceWrapper.summary = addField.text;

                if(root.filter && root.filter.collectionId >= 0) {
                    incidenceWrapper.collectionId = root.filter.collectionId;
                    Kalendar.CalendarManager.addIncidence(incidenceWrapper);
                    addField.clear();
                } else {
                    QQC2.ApplicationWindow.window.pageStack.pushDialogLayer(collectionPickerSheetComponent, {
                        incidenceWrapper: incidenceWrapper
                    });
                }
            }
        }

        rightActions: Kirigami.Action {
            icon.name: "list-add"
            text: i18n("Quickly Add a New Task.")
            tooltip: i18n("Quickly Add a New Task.")
            onTriggered: addField.addTodo()
        }
        onAccepted: addField.addTodo()
    }
}
