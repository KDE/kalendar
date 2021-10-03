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
    drawerOpen: !Kirigami.Settings.isMobile
    width: Kirigami.Units.gridUnit * 16

    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    function getCurrentView() {
        switch (pageStack.currentItem.objectName) {
            case "monthView":
                return 0;
            case "weekView":
                return 1;
            case "scheduleView":
                return 2;
            case "todoView":
                return 3;
            default:
                return 0;
        }
    }

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

                    Connections {
                        target: Config
                        onShowMenubarChanged: menu.visible = !Config.showMenubar
                    }

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    overflowIconName: "application-menu"

                    actions: [
                        Kirigami.Action {
                            icon.name: "edit-undo"
                            text: CalendarManager.undoRedoData.undoAvailable ?
                                i18n("Undo: ") + CalendarManager.undoRedoData.nextUndoDescription : undoAction.text
                            shortcut: undoAction.shortcut
                            enabled: CalendarManager.undoRedoData.undoAvailable
                            onTriggered: CalendarManager.undoAction();
                        },
                        Kirigami.Action {
                            icon.name: KalendarApplication.iconName(redoAction.icon)
                            text: CalendarManager.undoRedoData.redoAvailable ?
                                i18n("Redo: ") + CalendarManager.undoRedoData.nextRedoDescription : redoAction.text
                            shortcut: redoAction.shortcut
                            enabled: CalendarManager.undoRedoData.redoAvailable
                            onTriggered: CalendarManager.redoAction();
                        },
                        KActionFromAction {
                            kalendarAction: "toggle_menubar"
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
                        visible = !Config.showMenubar && !Kirigami.Settings.hasPlatformMenuBar
                        //HACK: Otherwise if menubar is open and then hidden hamburger refuses to appear (?)
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
                    if (!Kirigami.Settings.isMobile) {
                        getCurrentView();
                    } else {
                        return -1;
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
                        icon.name: KalendarApplication.iconName(weekViewAction.icon)
                        text: weekViewAction.text
                        shortcut: weekViewAction.shortcut
                        onTriggered: {
                            weekViewAction.trigger()
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
                            generalList.currentIndex = getCurrentView();
                        }
                        shortcut: configureAction.shortcut
                    }
                ]
                property list<Kirigami.Action> mobileActions: [
                    Kirigami.Action {
                        icon.name: "edit-undo"
                        text: CalendarManager.undoRedoData.undoAvailable ?
                            i18n("Undo: ") + CalendarManager.undoRedoData.nextUndoDescription : i18n("Undo")
                        enabled: CalendarManager.undoRedoData.undoAvailable
                        onTriggered: CalendarManager.undoAction();
                    },
                    Kirigami.Action {
                        icon.name: KalendarApplication.iconName(redoAction.icon)
                        text: CalendarManager.undoRedoData.redoAvailable ?
                            i18n("Redo: ") + CalendarManager.undoRedoData.nextRedoDescription : i18n("Redo")
                        enabled: CalendarManager.undoRedoData.redoAvailable
                        onTriggered: CalendarManager.redoAction();
                    },
                    KActionFromAction {
                        kalendarAction: "open_tag_manager"
                    },
                    Kirigami.Action {
                        text: i18n("Settings")
                        icon.name: KalendarApplication.iconName(configureAction.icon)
                        onTriggered: {
                            configureAction.trigger()
                            if(sidebar.modal) sidebar.close()
                            generalList.currentIndex = -1;
                        }
                    }
                ]
                model: !Kirigami.Settings.isMobile ? actions : mobileActions
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

                RowLayout {
                    id: tagsHeadingLayout
                    Layout.leftMargin: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing
                    spacing: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing
                    visible: tagList.count > 0

                    Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                        color: Kirigami.Theme.disabledTextColor
                        isMask: true
                        source: "action-rss_tag"
                    }
                    Kirigami.Heading {
                        id: tagsHeading
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: i18n("Tags")
                        color: Kirigami.Theme.disabledTextColor

                        level: 4
                        z: 10
                        background: Rectangle {color: Kirigami.Theme.backgroundColor}
                    }
                }

                Repeater {
                    id: tagList

                    model: TagManager.tagModel
                    onModelChanged: currentIndex = -1

                    delegate: Kirigami.BasicListItem {
                        Layout.fillWidth: true

                        label: display
                        labelItem.color: Kirigami.Theme.textColor
                        reserveSpaceForIcon: true

                        hoverEnabled: sidebar.todoMode
                        separatorVisible: false

                        onClicked: tagClicked(display)
                    }
                }

                RowLayout {
                    Layout.topMargin: tagsHeading.visible ? Kirigami.Units.largeSpacing * 2 : 0
                    Layout.leftMargin: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing
                    spacing: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                    Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                        color: Kirigami.Theme.disabledTextColor
                        isMask: true
                        source: "view-calendar"
                    }
                    Kirigami.Heading {
                        id: calendarsHeading
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        text: i18n("Calendars")
                        color: Kirigami.Theme.disabledTextColor

                        level: 4
                        z: 10
                        background: Rectangle {color: Kirigami.Theme.backgroundColor}
                    }
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
                                leftPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing
                                hoverEnabled: false
                                background: Item {}

                                separatorVisible: false

                                leading: Kirigami.Icon {
                                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                    color: Kirigami.Theme.disabledTextColor
                                    isMask: true
                                    source: model.decoration
                                }
                                leadingPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                                trailing: Kirigami.Icon {
                                    implicitWidth: Kirigami.Units.iconSizes.small
                                    implicitHeight: Kirigami.Units.iconSizes.small
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
                                leftPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing
                                hoverEnabled: sidebar.todoMode
                                separatorVisible: false
                                reserveSpaceForIcon: true

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
        Layout.topMargin: -Kirigami.Units.smallSpacing - 1
        icon: "show-all-effects"
        label: i18n("View all tasks")
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
