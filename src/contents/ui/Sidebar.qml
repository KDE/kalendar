// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0

Kirigami.OverlayDrawer {
    id: sidebar

    signal calendarClicked(int collectionId)
    signal calendarCheckChanged(int collectionId, bool checked)
    signal viewAllTodosClicked
    signal tagClicked(string tagName)

    property bool todoMode: false
    property alias toolbar: toolbar

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
            id: toolbar
            Layout.fillWidth: true
            Layout.preferredHeight: pageStack.globalToolBar.preferredHeight

            leftPadding: Kirigami.Units.smallSpacing
            rightPadding: Kirigami.Units.smallSpacing
            topPadding: 0
            bottomPadding: 0

            RowLayout {
                id: searchContainer
                anchors.fill: parent

                /*Kirigami.SearchField { // TODO: Make this open a new search results page
                 *    id: searchItem
                 *    Layout.fillWidth: true
                }*/

                Kirigami.Heading {
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                    text: i18n("Kalendar")
                }

                Kirigami.ActionToolBar {
                    id: menu
                    anchors.fill: parent
                    visible: Kirigami.Settings.isMobile
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
            Layout.topMargin: toolbar.visible ? -Kirigami.Units.smallSpacing - 1 : 0
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            contentWidth: availableWidth

            clip: true

            ListView {
                id: generalList
                currentIndex: {
                    switch (pageStack.currentItem.objectName) {
                        case "monthView":
                            return 0;
                        case "scheduleView":
                            return 1;
                        case "todoView":
                            return 2;
                        default:
                            return 0;
                    }
                }
                property list<Kirigami.Action> actions: [
                    Kirigami.Action {
                        icon.name: KalendarApplication.iconName(monthViewAction.icon)
                        text: monthViewAction.text
                        shortcut: monthViewAction.shortcut
                        onTriggered: {
                            monthViewAction.trigger()
                            if(sidebar.modal) sidebar.close()
                        }
                    },
                    Kirigami.Action {
                        icon.name: KalendarApplication.iconName(scheduleViewAction.icon)
                        text: scheduleViewAction.text
                        shortcut: scheduleViewAction.shortcut
                        onTriggered: {
                            scheduleViewAction.trigger()
                            if(sidebar.modal) sidebar.close()
                        }
                    },
                    Kirigami.Action {
                        icon.name: KalendarApplication.iconName(todoViewAction.icon)
                        text: todoViewAction.text
                        shortcut: todoViewAction.shortcut
                        onTriggered: {
                            todoViewAction.trigger()
                            if(sidebar.modal) sidebar.close()
                        }
                    },
                    Kirigami.Action {
                        text: i18n("Settings")
                        icon.name: KalendarApplication.iconName(configureAction.icon)
                        onTriggered: {
                            configureAction.trigger()
                            if(sidebar.modal) sidebar.close()
                        }
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

        QQC2.ScrollView {
            id: calendarView
            implicitWidth: Kirigami.Units.gridUnit * 16
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Kirigami.Units.largeSpacing * 2
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            contentWidth: availableWidth
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Kirigami.Heading {
                    id: tagsHeading
                    Layout.fillWidth: true
                    anchors.left: parent.left
                    anchors.right: parent.right
                    leftPadding: Kirigami.Units.largeSpacing
                    text: i18n("Tags")
                    color: Kirigami.Theme.disabledTextColor

                    font.weight: Font.Bold
                    level: 5
                    visible: tagList.count > 0
                    z: 10
                    background: Rectangle {color: Kirigami.Theme.backgroundColor}
                }

                Repeater {
                    id: tagList

                    model: TagManager.tagModel
                    onModelChanged: currentIndex = -1

                    delegate: Kirigami.BasicListItem {
                        Layout.fillWidth: true
                        label: display
                        labelItem.color: Kirigami.Theme.textColor

                        hoverEnabled: sidebar.todoMode
                        separatorVisible: false

                        onClicked: tagClicked(display)
                    }
                }

                Kirigami.Heading {
                    id: calendarsHeading
                    anchors.left: parent.left
                    anchors.right: parent.right
                    Layout.topMargin: tagsHeading.visible ? Kirigami.Units.largeSpacing * 2 : 0
                    leftPadding: Kirigami.Units.largeSpacing
                    text: i18n("Calendars")
                    color: Kirigami.Theme.disabledTextColor
                    font.weight: Font.Bold
                    level: 5
                    z: 10
                    background: Rectangle {color: Kirigami.Theme.backgroundColor}
                }

                Repeater {
                    id: calendarList

                    model: KDescendantsProxyModel {
                        model: sidebar.todoMode ? CalendarManager.todoCollections : CalendarManager.viewCollections
                    }
                    onModelChanged: currentIndex = -1

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
                                }

                                onClicked: calendarList.model.toggleChildren(index)
                            }
                        }

                        DelegateChoice {
                            roleValue: false
                            Kirigami.BasicListItem {
                                label: display
                                labelItem.color: Kirigami.Theme.textColor

                                hoverEnabled: sidebar.todoMode

                                separatorVisible: false

                                trailing: ColoredCheckbox {
                                    id: calendarCheckbox

                                visible: model.checkState != null
                                color: model.collectionColor
                                checked: model.checkState === 2
                                onCheckedChanged: calendarCheckChanged(collectionId, checked)
                                onClicked: {
                                    model.checkState = model.checkState === 0 ? 2 : 0
                                    calendarCheckChanged(collectionId, checked)
                                }
                            }

                                onClicked: {
                                    calendarClicked(collectionId)
                                    if(sidebar.modal && sidebar.todoMode) sidebar.close()
                                }
                            }
                        }
                    }
                }
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
            if(sidebar.modal && sidebar.todoMode) sidebar.close()
        }
    }


}
