// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar 1.0 as Kalendar

Kirigami.ScrollablePage {
    id: root
    title: i18n("Calendars")

    signal addTodo(int collectionId)
    signal viewTodo(var todoData, var collectionData)
    signal editTodo(var todoPtr, int collectionId)
    signal deleteTodo(var todoPtr, date deleteDate)
    signal completeTodo (var todoPtr)
    signal addSubTodo(var parentWrapper)

    Component {
        id: loadingPageComponent
        Kirigami.Page {
            id: loadingPage
            QQC2.BusyIndicator {
                anchors.centerIn: parent
                running: true
            }
        }
    }

    Loader {
        id: allTodosPageLoader
        active: true
        asynchronous: true
        sourceComponent: TodoPage {
            onAddTodo: root.addTodo(collectionId)
            onViewTodo: root.viewTodo(todoData, collectionData)
            onEditTodo: root.editTodo(todoPtr, collectionId)
            onDeleteTodo: root.deleteTodo(todoPtr, deleteDate)
            onCompleteTodo: root.completeTodo(todoPtr)
            onAddSubTodo: root.addSubTodo(parentWrapper)
        }
        visible: false
        onLoaded: {
            if (loadingPageComponent.visible) {
                pageStack.pop(root);
            }
            pageStack.push(allTodosPageLoader.item);
        }
    }

    ListView {
        currentIndex: -1
        header: ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            QQC2.ToolButton {
                Layout.fillWidth: true
                icon.name: "view-process-all"
                text: i18n("View all todos")
                onClicked: pageStack.push(allTodosPageLoader.item)
            }
        }

        model: Kalendar.CalendarManager.todoCollections
        delegate: Kirigami.BasicListItem {
            property int itemCollectionId: collectionId

            leftPadding: ((Kirigami.Units.gridUnit * 2) * (kDescendantLevel - 1)) + Kirigami.Units.largeSpacing
            enabled: model.checkState != null
            trailing: QQC2.CheckBox {
                id: collectionCheckbox

                indicator: Rectangle {
                    height: parent.height * 0.8
                    width: height
                    x: collectionCheckbox.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: 3
                    border.color: model.collectionColor
                    color: Qt.rgba(0,0,0,0)

                    Rectangle {
                        anchors.margins: parent.height * 0.2
                        anchors.fill: parent
                        radius: 1
                        color: model.collectionColor
                        visible: model.checkState == 2
                    }
                }
                checked: model.checkState == 2
                onClicked: model.checkState = model.checkState === 0 ? 2 : 0
            }

            label: display

            Loader {
                id: todoPageLoader
                active: true
                asynchronous: true
                sourceComponent: TodoPage {
                    filterCollectionId: collectionId
                    onAddTodo: root.addTodo(collectionId)
                    onViewTodo: root.viewTodo(todoData, collectionData)
                    onEditTodo: root.editTodo(todoPtr, collectionId)
                    onDeleteTodo: root.deleteTodo(todoPtr, deleteDate)
                    onCompleteTodo: root.completeTodo(todoPtr)
                    onAddSubTodo: root.addSubTodo(parentWrapper)
                }
                visible: false
            }

            onClicked: if(model.checkState != null) {
                model.checkState = 2;
                pageStack.push(todoPageLoader.item);
            }
        }
    }
}
