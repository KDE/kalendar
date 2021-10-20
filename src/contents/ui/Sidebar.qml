// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0
import QtGraphicalEffects 1.12

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
    width: sidebar.collapsed ? menu.Layout.minimumWidth + Kirigami.Units.smallSpacing : Kirigami.Units.gridUnit * 16
    Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad } }

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
        spacing: 0
        clip: true

        QQC2.ToolBar {
            id: toolbar
            Layout.fillWidth: true
            Layout.preferredHeight: pageStack.globalToolBar.preferredHeight

            leftPadding: sidebar.collapsed ? 0 : Kirigami.Units.smallSpacing
            rightPadding: sidebar.collapsed ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
            topPadding: 0
            bottomPadding: 0

            //Kirigami.SearchField { // TODO: Make this open a new search results page
                //id: searchItem
                //Layout.fillWidth: true
            //}

            Kirigami.Heading {
                anchors.left: parent.left
                anchors.leftMargin: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                anchors.verticalCenter: parent.verticalCenter
                text: i18n("Kalendar")

                opacity: sidebar.collapsed ? 0 : 1
                Behavior on opacity {
                    OpacityAnimator {
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Kirigami.ActionToolBar {
                id: menu

                Connections {
                    target: Config
                    onShowMenubarChanged: if(!Kirigami.Settings.isMobile && !Kirigami.Settings.hasPlatformMenuBar) menu.visible = !Config.showMenubar
                }

                anchors.fill: parent
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
                        text: i18n("Configure")
                        icon.name: "settings-configure"
                        KActionFromAction {
                            kalendarAction: "open_tag_manager"
                        }
                        KActionFromAction {
                            kalendarAction: 'options_configure_keybinding'
                        }
                        KActionFromAction {
                            kalendarAction: "options_configure"
                        }
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
                    visible = !Kirigami.Settings.isMobile && !Config.showMenubar && !Kirigami.Settings.hasPlatformMenuBar
                    //HACK: Otherwise if menubar is open and then hidden hamburger refuses to appear (?)
                }
            }
        }

        QQC2.ScrollView {
            id: generalView
            implicitWidth: Kirigami.Units.gridUnit * 16
            Layout.fillWidth: true
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            contentWidth: availableWidth

            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    id: generalActions
                    property list<Kirigami.Action> actions: [
                        KActionFromAction {
                            kalendarAction: "open_month_view"
                            checkable: false
                            onTriggered: {
                                monthViewAction.trigger()
                                if (sidebar.modal) sidebar.close()
                            }
                        },
                        KActionFromAction {
                            kalendarAction: "open_week_view"
                            checkable: false
                            onTriggered: {
                                weekViewAction.trigger()
                                if (sidebar.modal) sidebar.close()
                            }
                        },
                        KActionFromAction {
                            kalendarAction: "open_schedule_view"
                            checkable: false
                            onTriggered: {
                                scheduleViewAction.trigger()
                                if (sidebar.modal) sidebar.close()
                            }
                        },
                        KActionFromAction {
                            kalendarAction: "open_todo_view"
                            checkable: false
                            onTriggered: {
                                todoViewAction.trigger()
                                if (sidebar.modal) sidebar.close()
                            }
                        }
                    ]
                    property list<Kirigami.Action> mobileActions: [
                        KActionFromAction {
                            text: CalendarManager.undoRedoData.undoAvailable ?
                                i18n("Undo: ") + CalendarManager.undoRedoData.nextUndoDescription : i18n("Undo")
                            kalendarAction: "edit_undo"
                        },
                        KActionFromAction {
                            text: CalendarManager.undoRedoData.redoAvailable ?
                                i18n("Redo: ") + CalendarManager.undoRedoData.nextRedoDescription : i18n("Redo")
                            kalendarAction: "edit_redo"
                        },
                        KActionFromAction {
                            kalendarAction: "open_tag_manager"
                            onTriggered: {
                                tagManagerAction.trigger()
                                if (sidebar.modal) sidebar.close()
                            }
                        },
                        KActionFromAction {
                            text: i18n("Settings")
                            kalendarAction: "options_configure"
                            onTriggered: {
                                configureAction.trigger()
                                if (sidebar.modal) sidebar.close()
                            }
                        }
                    ]
                    model: !Kirigami.Settings.isMobile ? actions : mobileActions
                    delegate: Kirigami.BasicListItem {
                        label: modelData.text
                        icon: modelData.icon.name
                        separatorVisible: false
                        action: modelData
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: toolbar.visible ? -Kirigami.Units.smallSpacing - 1 : 0
                    color: Kirigami.Theme.backgroundColor
                    z: -1
                }
            }
        }

        Kirigami.Separator {
            id: headerTopSeparator
            Layout.fillWidth: true
            height: 1
            z: -2

            opacity: sidebar.collapsed ? 0 : 1
            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }

            RectangularGlow {
                anchors.fill: parent
                z: -1
                glowRadius: 5
                spread: 0.3
                color: Qt.rgba(0.0, 0.0, 0.0, 0.15)
            }
        }

        QQC2.ScrollView {
            id: calendarView
            implicitWidth: Kirigami.Units.gridUnit * 16
            Layout.fillWidth: true
            Layout.fillHeight: true
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            contentWidth: availableWidth
            clip: true
            z: -2

            opacity: sidebar.collapsed ? 0 : 1
            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                RowLayout {
                    id: tagsHeadingLayout
                    Layout.topMargin: Kirigami.Units.largeSpacing
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
                    }
                }

                Repeater {
                    id: tagList

                    model: TagManager.tagModel

                    delegate: Kirigami.BasicListItem {
                        Layout.fillWidth: true

                        label: display
                        labelItem.color: Kirigami.Theme.textColor
                        reserveSpaceForIcon: true

                        separatorVisible: false

                        onClicked: tagClicked(display)
                    }
                }

                RowLayout {
                    Layout.topMargin: tagsHeading.visible ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing
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
                    }
                }

                Repeater {
                    id: calendarList

                    model: KDescendantsProxyModel {
                        model: sidebar.todoMode ? CalendarManager.todoCollections : CalendarManager.viewCollections
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
                                    calendarClicked(collectionId);
                                    if(sidebar.modal) sidebar.close()
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

        FontMetrics {
            id: textMetrics
        }

        implicitHeight: textMetrics.height + Kirigami.Units.largeSpacing
        icon: "show-all-effects"
        label: i18n("View all tasks")
        labelItem.color: Kirigami.Theme.textColor
        visible: sidebar.todoMode
        separatorVisible: false
        onClicked: {
            viewAllTodosClicked();
            if(sidebar.modal && sidebar.todoMode) sidebar.close()
        }
    }
}
