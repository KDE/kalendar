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
    property bool ascendingOrder: Kalendar.Config.ascendingOrder
    property Component completedSheetComponent: Kirigami.ScrollablePage {
        id: completedSheet
        title: root.filterCollectionDetails && root.filter && root.filter.collectionId > -1 ? i18n("Completed Tasks in %1", root.filterCollectionDetails.displayName) : i18n("Completed Tasks")

        TodoTreeView {
            id: completeView
            Layout.fillHeight: true
            Layout.fillWidth: true
            ascendingOrder: root.ascendingOrder
            filter: root.filter
            filterCollectionDetails: root.filterCollectionDetails
            showCompleted: Kalendar.TodoSortFilterProxyModel.ShowCompleteOnly
            sortBy: root.sortBy

            onAddSubTodo: root.addSubTodo(parentWrapper)
            onAddTodo: {
                root.addTodo(collectionId);
                completedSheet.closeDialog();
            }
            onCompleteTodo: root.completeTodo(todoPtr)
            onDeleteTodo: {
                root.deleteTodo(todoPtr, deleteDate);
                completedSheet.closeDialog();
            }
            onDeselect: root.deselect()
            onEditTodo: {
                root.editTodo(todoPtr, collectionId);
                completedSheet.closeDialog();
            }
            onViewTodo: {
                root.retainTodoData(todoData, collectionData);
                completedSheet.closeDialog();
            }
        }
    }
    property var filter: {
        "collectionId": -1,
        "tags": [],
        "name": ""
    }
    property var filterCollectionDetails: root.filter && root.filter.collectionId >= 0 ? Kalendar.CalendarManager.getCollectionDetails(root.filter.collectionId) : null
    readonly property bool isDark: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)
    property var retainedCollectionData: {
    }
    property var retainedTodoData: {
    }
    property int sortBy: switch (Kalendar.Config.sort) {
    case Kalendar.Config.DueTime:
        return Kalendar.TodoSortFilterProxyModel.EndTimeColumn;
    case Kalendar.Config.Priority:
        return Kalendar.TodoSortFilterProxyModel.PriorityIntColumn;
    case Kalendar.Config.Alphabetically:
        return Kalendar.TodoSortFilterProxyModel.SummaryColumn;
    }
    readonly property color standardTextColor: Kirigami.Theme.textColor

    leftPadding: Kirigami.Units.largeSpacing
    padding: 0

    signal addSubTodo(var parentWrapper)
    signal addTodo(int collectionId)
    signal completeTodo(var todoPtr)
    signal deleteTodo(var todoPtr, date deleteDate)
    signal deselect
    signal editTodo(var todoPtr, int collectionId)

    // We need to store a copy of opened incidence data or we will lose it as we scroll the listviews.
    function retainTodoData(todoData, collectionData) {
        retainedTodoData = {
            "incidencePtr": todoData.incidencePtr,
            "incidenceId": todoData.incidenceId,
            "collectionId": collectionData.id,
            "text": todoData.text,
            "color": todoData.color,
            "startTime": todoData.startTime,
            "endTime": todoData.endTime,
            "durationString": todoData.durationString
        };
        retainedCollectionData = Kalendar.CalendarManager.getCollectionDetails(collectionData.id);
        viewTodo(retainedTodoData, retainedCollectionData);
    }
    signal viewTodo(var todoData, var collectionData)

    actions {
        left: Kirigami.Action {
            icon.name: "view-sort"
            text: i18n("Sort")

            KActionFromAction {
                checked: root.sortBy === Kalendar.TodoSortFilterProxyModel.EndTimeColumn
                kalendarAction: "todoview_sort_by_due_date"

                onCheckedChanged: __action.checked = checked // Needed for the actions in the menu bars to be checked on load
            }
            KActionFromAction {
                checked: root.sortBy === Kalendar.TodoSortFilterProxyModel.PriorityIntColumn
                kalendarAction: "todoview_sort_by_priority"

                onCheckedChanged: __action.checked = checked
            }
            KActionFromAction {
                checked: root.sortBy === Kalendar.TodoSortFilterProxyModel.SummaryColumn
                kalendarAction: "todoview_sort_alphabetically"

                onCheckedChanged: __action.checked = checked
            }
            Kirigami.Action {
                separator: true
            }
            KActionFromAction {
                checked: root.ascendingOrder
                kalendarAction: "todoview_order_ascending"

                onCheckedChanged: __action.checked = checked
            }
            KActionFromAction {
                checked: !root.ascendingOrder
                kalendarAction: "todoview_order_descending"

                onCheckedChanged: __action.checked = checked
            }
        }
        main: Kirigami.Action {
            icon.name: "list-add"
            text: i18n("Create")

            onTriggered: root.addTodo(root.filter.collectionId)
        }
        right: KActionFromAction {
            kalendarAction: "todoview_show_completed"
            text: i18n("Show Completed")
        }
    }
    Component {
        id: collectionPickerSheetComponent
        Kirigami.ScrollablePage {
            id: collectionPickerSheet
            property var incidenceWrapper

            title: i18n("Choose a Task Calendar")

            ListView {
                id: collectionsList
                currentIndex: -1
                implicitWidth: Kirigami.Units.gridUnit * 30

                delegate: DelegateChooser {
                    role: 'kDescendantExpandable'

                    DelegateChoice {
                        roleValue: true

                        Kirigami.BasicListItem {
                            hoverEnabled: false
                            label: display
                            labelItem.color: Kirigami.Theme.disabledTextColor
                            labelItem.font.weight: Font.DemiBold
                            separatorVisible: false
                            topPadding: 2 * Kirigami.Units.largeSpacing

                            onClicked: collectionsList.model.toggleChildren(index)

                            background: Item {
                            }
                            trailing: Kirigami.Icon {
                                height: Kirigami.Units.iconSizes.small
                                source: model.kDescendantExpanded ? 'arrow-up' : 'arrow-down'
                                width: Kirigami.Units.iconSizes.small
                                x: -4
                            }
                        }
                    }
                    DelegateChoice {
                        roleValue: false

                        Kirigami.BasicListItem {
                            hoverEnabled: false
                            label: display
                            labelItem.color: Kirigami.Theme.textColor
                            separatorVisible: false

                            onClicked: {
                                collectionPickerSheet.incidenceWrapper.collectionId = collectionId;
                                Kalendar.CalendarManager.addIncidence(collectionPickerSheet.incidenceWrapper);
                                collectionPickerSheet.closeDialog();
                                addField.clear();
                            }

                            trailing: Rectangle {
                                color: model.collectionColor
                                height: Kirigami.Units.iconSizes.small
                                radius: Kirigami.Units.smallSpacing
                                width: height
                            }
                        }
                    }
                }
                header: ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                }
                model: KDescendantsProxyModel {
                    model: Kalendar.CalendarManager.todoCollections
                }
            }
        }
    }
    TodoTreeView {
        id: incompleteView
        Layout.fillHeight: true
        Layout.fillWidth: true
        ascendingOrder: root.ascendingOrder
        filter: root.filter
        filterCollectionDetails: root.filterCollectionDetails
        showCompleted: Kalendar.TodoSortFilterProxyModel.ShowIncompleteOnly
        sortBy: root.sortBy
        z: 5

        onAddSubTodo: root.addSubTodo(parentWrapper)
        onAddTodo: root.addTodo(collectionId)
        onCompleteTodo: root.completeTodo(todoPtr)
        onDeleteTodo: root.deleteTodo(todoPtr, deleteDate)
        onDeselect: root.deselect()
        onEditTodo: root.editTodo(todoPtr, collectionId)
        onViewTodo: root.retainTodoData(todoData, collectionData)
    }

    background: Rectangle {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.inherit: false
        color: Kirigami.Theme.backgroundColor
    }
    footer: Kirigami.ActionTextField {
        id: addField
        implicitHeight: textMetrics.height + Kirigami.Units.largeSpacing + 1 // To align with 'Show all' button in sidebar
        placeholderText: i18n("Create a New Task…")

        function addTodo() {
            if (addField.text) {
                let incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', this, "incidence");
                incidenceWrapper.setNewTodo();
                incidenceWrapper.summary = addField.text;
                if (root.filter && root.filter.collectionId >= 0) {
                    incidenceWrapper.collectionId = root.filter.collectionId;
                    Kalendar.CalendarManager.addIncidence(incidenceWrapper);
                    addField.clear();
                } else {
                    QQC2.ApplicationWindow.window.pageStack.pushDialogLayer(collectionPickerSheetComponent, {
                            "incidenceWrapper": incidenceWrapper
                        });
                }
            }
        }

        onAccepted: addField.addTodo()

        FontMetrics {
            id: textMetrics
        }

        background: Rectangle {
            Kirigami.Theme.colorSet: Kirigami.Theme.Window
            Kirigami.Theme.inherit: false
            color: Kirigami.Theme.backgroundColor

            Kirigami.Separator {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
            }
        }
        rightActions: Kirigami.Action {
            icon.name: "list-add"
            text: i18n("Quickly Add a New Task.")
            tooltip: i18n("Quickly Add a New Task.")

            onTriggered: addField.addTodo()
        }
    }
}
