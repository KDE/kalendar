// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0

import org.kde.kalendar.calendar 1.0 as Calendar
import org.kde.kalendar.utils 1.0
import org.kde.kalendar.components 1.0
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Kirigami.ScrollablePage {
    id: root
    objectName: "todoView"

    property var mode: Calendar.CalendarApplication.Todo

    property var filterCollectionDetails: Calendar.Filter.collectionId >= 0 ?
        Calendar.CalendarManager.getCollectionDetails(Calendar.Filter.collectionId) : null

    property int sortBy: switch (Calendar.Config.sort) {
        case Calendar.Config.DueTime:
            return Calendar.TodoSortFilterProxyModel.DueDateColumn;
        case Calendar.Config.Priority:
            return Calendar.TodoSortFilterProxyModel.PriorityColumn;
        case Calendar.Config.Alphabetically:
            return Calendar.TodoSortFilterProxyModel.SummaryColumn;
    }

    property bool ascendingOrder: Calendar.Config.ascendingOrder

    readonly property color standardTextColor: Kirigami.Theme.textColor
    readonly property bool isDark: CalendarUiUtils.darkMode

    readonly property alias incompleteView: incompleteView

    padding: 0
    leftPadding: Kirigami.Units.largeSpacing

    titleDelegate: RowLayout {
        spacing: 0
        MainDrawerToggleButton {}
        Kirigami.Heading {
            text: i18n("Tasks")
        }
    }

    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    actions {
        main: Kirigami.Action {
            text: i18n("Create")
            icon.name: "list-add"
            onTriggered: CalendarUiUtils.setUpAdd(Calendar.IncidenceWrapper.TypeTodo, new Date(), Calendar.Filter.collectionId);
        }
        left: Kirigami.Action {
            text: i18n("Sort")
            icon.name: "view-sort"

            KActionFromAction {
                action: Calendar.CalendarApplication.action("todoview_sort_by_due_date")
                checked: root.sortBy === Calendar.TodoSortFilterProxyModel.DueDateColumn
                onCheckedChanged: __action.checked = checked // Needed for the actions in the menu bars to be checked on load
            }
            KActionFromAction {
                action: Calendar.CalendarApplication.action("todoview_sort_by_priority")
                checked: root.sortBy === Calendar.TodoSortFilterProxyModel.PriorityColumn
                onCheckedChanged: __action.checked = checked
            }
            KActionFromAction {
                action: Calendar.CalendarApplication.action("todoview_sort_alphabetically")
                checked: root.sortBy === Calendar.TodoSortFilterProxyModel.SummaryColumn
                onCheckedChanged: __action.checked = checked
            }

            Kirigami.Action { separator: true }

            KActionFromAction {
                action: Calendar.CalendarApplication.action("todoview_order_ascending")
                checked: root.ascendingOrder
                onCheckedChanged: __action.checked = checked
            }
            KActionFromAction {
                action: Calendar.CalendarApplication.action("todoview_order_descending")
                checked: !root.ascendingOrder
                onCheckedChanged: __action.checked = checked
            }
        }
        right: KActionFromAction {
            action: Calendar.CalendarApplication.action("todoview_show_completed")
            text: i18n("Show Completed")
        }

    }

    property Component completedSheetComponent: Kirigami.ScrollablePage {
        id: completedSheet
        title: root.filterCollectionDetails && Calendar.Filter.collectionId > -1 ?
            i18n("Completed Tasks in %1", root.filterCollectionDetails.displayName) : i18n("Completed Tasks")

        TodoTreeView {
            id: completeView
            Layout.fillWidth: true
            Layout.fillHeight: true

            filterCollectionDetails: root.filterCollectionDetails

            showCompleted: Calendar.TodoSortFilterProxyModel.ShowCompleteOnly
            sortBy: root.sortBy
            ascendingOrder: root.ascendingOrder
        }
    }

    Component {
        id: collectionPickerSheetComponent
        CollectionPickerPage {
            id: collectionPickerSheet
            property var incidenceWrapper

            mode: Calendar.CalendarApplication.Todo
            onCollectionPicked: {
                collectionPickerSheet.incidenceWrapper.collectionId = collectionId;
                Calendar.CalendarManager.addIncidence(collectionPickerSheet.incidenceWrapper);
                collectionPickerSheet.closeDialog();
                addField.clear();
            }
            onCancel: closeDialog()
        }
    }

    TodoTreeView {
        id: incompleteView
        z: 5
        Layout.fillWidth: true
        Layout.fillHeight: true

        filterCollectionDetails: root.filterCollectionDetails

        showCompleted: Calendar.TodoSortFilterProxyModel.ShowIncompleteOnly
        sortBy: root.sortBy
        ascendingOrder: root.ascendingOrder
    }


    footer: Kirigami.ActionTextField {
        id: addField
        placeholderText: i18n("Create a New Task…")
        FontMetrics {
            id: textMetrics
        }

        implicitHeight: textMetrics.height + Kirigami.Units.largeSpacing * 2 + 1 // To align with 'Show all' button in mainDrawer

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
                let incidenceWrapper = Qt.createQmlObject('import org.kde.Calendar.calendar 1.0; IncidenceWrapper {id: incidence}', this, "incidence");
                incidenceWrapper.setNewTodo();
                incidenceWrapper.summary = addField.text;

                if(Calendar.Filter.collectionId >= 0) {
                    incidenceWrapper.collectionId = Calendar.Filter.collectionId;
                    Calendar.CalendarManager.addIncidence(incidenceWrapper);
                    addField.clear();
                } else {
                    const openDialogWindow = QQC2.ApplicationWindow.window.pageStack.pushDialogLayer(collectionPickerSheetComponent, {
                        incidenceWrapper: incidenceWrapper
                    });
                    openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
                }
            }
        }

        rightActions: Kirigami.Action {
            icon.name: "list-add"
            text: i18n("Quickly Add a New Task.")
            tooltip: i18n("Quickly Add a New Task.")
            enabled: addField.text !== ""
            onTriggered: addField.addTodo()
        }
        onAccepted: addField.addTodo()
    }
}
