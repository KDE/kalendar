// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0

Kirigami.OverlayDrawer {
    id: sidebar

    signal calendarClicked(int collectionId)
    signal viewAllTodosClicked

    property bool todoMode: false

    edge: Qt.application.layoutDirection === Qt.RightToLeft ? Qt.RightEdge : Qt.LeftEdge
    modal: !wideScreen
    onModalChanged: drawerOpen = !modal
    handleVisible: !wideScreen
    handleClosedIcon.source: null
    handleOpenIcon.source: null
    drawerOpen: !Settings.isMobile
    width: Kirigami.Units.gridUnit * 16

    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    contentItem: ColumnLayout {
        id: container

        QQC2.ToolBar {
            Layout.fillWidth: true
            Layout.preferredHeight: pageStack.globalToolBar.preferredHeight

            leftPadding: Kirigami.Units.smallSpacing
            rightPadding: Kirigami.Units.smallSpacing
            topPadding: 0
            bottomPadding: 0

            RowLayout {
                id: searchContainer
                anchors {
                    left: parent.left
                    leftMargin: Kirigami.Units.smallSpacing
                    right: parent.right
                    rightMargin: Kirigami.Units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }

                /*Kirigami.SearchField { // TODO: Make this open a new search results page
                    id: searchItem
                    Layout.fillWidth: true
                }*/

                Kirigami.Heading {
                    Layout.fillWidth: true
                    text: i18n("Kalendar")
                    type: Kirigami.Heading.Type.Primary
                }

                Kirigami.ActionToolBar {
                    id: menu
                    anchors.fill: parent
                    overflowIconName: "application-menu"

                    actions: [
                        Kirigami.Action {
                            icon.name: "edit-undo"
                            text: CalendarManager.undoRedoData.undoAvailable ?
                                i18n("Undo: ") + CalendarManager.undoRedoData.nextUndoDescription :
                                undoAction.text
                            shortcut: undoAction.shortcut
                            enabled: CalendarManager.undoRedoData.undoAvailable && !(root.activeFocusItem instanceof TextEdit || root.activeFocusItem instanceof TextInput)
                            onTriggered: CalendarManager.undoAction();
                        },
                        Kirigami.Action {
                            icon.name: KalendarApplication.iconName(redoAction.icon)
                            text: CalendarManager.undoRedoData.redoAvailable ?
                                i18n("Redo: ") + CalendarManager.undoRedoData.nextRedoDescription :
                                redoAction.text
                            shortcut: redoAction.shortcut
                            enabled: CalendarManager.undoRedoData.redoAvailable && !(root.activeFocusItem instanceof TextEdit || root.activeFocusItem instanceof TextInput)

                            onTriggered: CalendarManager.redoAction();
                        },
                        Kirigami.Action {
                            icon.name: KalendarApplication.iconName(quitAction.icon)
                            text: quitAction.text
                            shortcut: quitAction.shortcut
                            onTriggered: quitAction.trigger()
                            visible: !Kirigami.Settings.isMobile
                        }
                    ]

                    Component.onCompleted: {
                        for (let i in actions) {
                            let action = actions[i]
                            action.displayHint = Kirigami.DisplayHint.AlwaysHide
                        }
                    }
                }
            }
        }

        QQC2.ScrollView {
            id: generalView
            implicitWidth: Kirigami.Units.gridUnit * 16
            Layout.fillWidth: true
            Layout.topMargin: -Kirigami.Units.smallSpacing - 1
            Layout.bottomMargin: -Kirigami.Units.smallSpacing
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            contentWidth: availableWidth

            clip: true

            ListView {
                id: generalList
                currentIndex: 0
                property list<Kirigami.Action> actions: [
                    Kirigami.Action {
                        icon.name: KalendarApplication.iconName(monthViewAction.icon)
                        text: monthViewAction.text
                        shortcut: monthViewAction.shortcut
                        onTriggered: monthViewAction.trigger()
                    },
                    Kirigami.Action {
                        icon.name: KalendarApplication.iconName(scheduleViewAction.icon)
                        text: scheduleViewAction.text
                        shortcut: scheduleViewAction.shortcut
                        onTriggered: scheduleViewAction.trigger()
                    },
                    Kirigami.Action {
                        icon.name: KalendarApplication.iconName(todoViewAction.icon)
                        text: todoViewAction.text
                        shortcut: todoViewAction.shortcut
                        onTriggered: todoViewAction.trigger()
                    },
                    Kirigami.Action {
                        text: i18n("Settings")
                        icon.name: KalendarApplication.iconName(configureAction.icon)
                        onTriggered: configureAction.trigger()
                        shortcut: configureAction.shortcut
                    }
                ]
                model: actions
                delegate: Kirigami.BasicListItem {
                    text: modelData.text
                    icon: modelData.icon.name
                    separatorVisible: false
                    action: modelData
                }
            }
        }

        Kirigami.Heading {
            Layout.fillWidth: true
            topPadding: Kirigami.Units.largeSpacing * 2
            bottomPadding: Kirigami.Units.largeSpacing
            leftPadding: Kirigami.Units.largeSpacing
            text: i18n("Calendars")
            level: 6
            type: Kirigami.Heading.Type.Primary
            opacity: 0.7
        }

        QQC2.ScrollView {
            id: calendarView
            implicitWidth: Kirigami.Units.gridUnit * 16
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: -Kirigami.Units.smallSpacing - 1
            Layout.bottomMargin: -Kirigami.Units.smallSpacing
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            contentWidth: availableWidth

            clip: true

            ListView {
                id: calendarList

                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.largeSpacing

                currentIndex: -1

                model: sidebar.todoMode ? CalendarManager.todoCollections : CalendarManager.viewCollections
                onModelChanged: currentIndex = -1

                delegate: Kirigami.BasicListItem {
                    enabled: model.checkState != null
                    label: display
                    labelItem.color: Kirigami.Theme.textColor

                    hoverEnabled: sidebar.todoMode

                    separatorVisible: false
                    trailing: QQC2.CheckBox {
                        id: calendarCheckbox

                        indicator: Rectangle {
                            height: parent.height * 0.8
                            width: height
                            x: calendarCheckbox.leftPadding
                            y: parent.height / 2 - height / 2
                            radius: 3
                            border.color: model.collectionColor
                            color: Qt.rgba(0,0,0,0)

                            Rectangle {
                                anchors.margins: parent.height * 0.2
                                anchors.fill: parent
                                radius: 1
                                color: model.collectionColor
                                visible: model.checkState === 2
                            }
                        }
                        checked: model.checkState === 2
                        onClicked: model.checkState = model.checkState === 0 ? 2 : 0
                    }
                    onClicked: calendarClicked(collectionId)
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }
        Kirigami.BasicListItem {
            Layout.topMargin: -Kirigami.Units.smallSpacing
            icon: "show-all-effects"
            label: i18n("View all todos")
            labelItem.color: Kirigami.Theme.textColor
            visible: sidebar.todoMode
            separatorVisible: false
            onClicked: {
                viewAllTodosClicked();
                calendarList.currentIndex = -1;
            }
        }
    }
}
