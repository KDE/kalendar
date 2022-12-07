// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import Qt.labs.qmlmodels 1.0
import QtGraphicalEffects 1.12

import org.kde.akonadi 1.0
import org.kde.kalendar 1.0
import org.kde.kalendar.contact 1.0
import org.kde.kalendar.mail 1.0
import org.kde.kalendar.components 1.0
import org.kde.kirigami 2.16 as Kirigami
import org.kde.kitemmodels 1.0

Kirigami.OverlayDrawer {
    id: mainDrawer

    signal calendarClicked(int collectionId)
    signal deleteCalendar(int collectionId, var collectionDetails)

    property var mode: KalendarApplication.Event
    property alias toolbar: toolbar
    property var activeTags : Filter.tags

    readonly property int collapsedWidth: menu.Layout.minimumWidth + Kirigami.Units.smallSpacing
    readonly property int expandedWidth: Kirigami.Units.gridUnit * 16
    property bool refuseModal: false
    property int prevWindowWidth: applicationWindow().width
    property int narrowWindowWidth: Kirigami.Units.gridUnit * 50

    Connections {
        target: applicationWindow()
        function onWidthChanged() {
            if(!Kirigami.Settings.isMobile) {
                const currentWindowWidthNarrow = applicationWindow().width < narrowWindowWidth;
                const prevWindowWidthNarrow = mainDrawer.prevWindowWidth < narrowWindowWidth;
                const prevCollapsed = mainDrawer.collapsed;

                // We don't want to go into modal when we are resizing the window to narrow and the drawer is collapsing
                if(currentWindowWidthNarrow && !prevWindowWidthNarrow) {
                    mainDrawer.collapsed = true;
                    refuseModal = !prevCollapsed;
                } else if (!currentWindowWidthNarrow && prevWindowWidthNarrow) {
                    if(!Config.forceCollapsedMainDrawer) {
                        mainDrawer.collapsed = false;
                    } else if(!mainDrawer.collapsed) {
                        mainDrawer.collapsed = true;
                    }
                }

                mainDrawer.prevWindowWidth = applicationWindow().width;
            }
        }
    }

    Connections {
        target: Config
        function onForceCollapsedMainDrawerChanged() {
            mainDrawer.collapsed = Config.forceCollapsedMainDrawer;
        }
    }

    edge: Qt.application.layoutDirection === Qt.RightToLeft ? Qt.RightEdge : Qt.LeftEdge
    // Modal when mobile, or when the window is narrow and the drawer is expanded/being expanded
    modal: Kirigami.Settings.isMobile ||
           (applicationWindow().width < narrowWindowWidth && (!collapsed || width > collapsedWidth) && !refuseModal)
    collapsed: !Kirigami.Settings.isMobile &&
               (Config.forceCollapsedMainDrawer || applicationWindow().width < narrowWindowWidth)
    onDrawerOpenChanged: {
        // We want the drawer to be open but collapsed if we close it when it is modal on desktop
        if(!Kirigami.Settings.isMobile && !drawerOpen) {
            drawerOpen = true;
            collapsed = true;
        }
    }

    handleVisible: modal
    handleClosedIcon.source: null
    handleOpenIcon.source: null
    width: mainDrawer.collapsed ? collapsedWidth : expandedWidth
    // Re-enable modal after the drawer has been collapsed after resizing the window to a narrow size
    onWidthChanged: if(width === collapsedWidth) refuseModal = false
    Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad } }

    Component.onCompleted: ContactManager.contactCollections; // Fix crashing because the contactCollections was created too late

    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    contentItem: ColumnLayout {
        id: container
        spacing: 0
        clip: true

        QQC2.ToolBar {
            id: toolbar
            Layout.fillWidth: true
            Layout.preferredHeight: pageStack.globalToolBar.preferredHeight

            leftPadding: mainDrawer.collapsed ? 0 : Kirigami.Units.smallSpacing
            rightPadding: mainDrawer.collapsed ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
            topPadding: 0
            bottomPadding: 0

            RowLayout {
                anchors.fill: parent

                Kirigami.Heading { // TODO: Remove once search results page complete
                    Layout.leftMargin: Kirigami.Units.smallSpacing + Kirigami.Units.largeSpacing
                    text: i18n("Kalendar")

                    visible: !searchField.visible
                    opacity: mainDrawer.collapsed ? 0 : 1
                    Behavior on opacity {
                        OpacityAnimator {
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                Kirigami.SearchField { // TODO: Make this open a new search results page
                    id: searchField
                    Layout.fillWidth: true
                    onTextChanged: Filter.name = text

                    visible: mainDrawer.mode & (KalendarApplication.Todo | KalendarApplication.Mail | KalendarApplication.Contact)
                    opacity: mainDrawer.collapsed ? 0 : 1
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
                        function onShowMenubarChanged() {
                            if(!Kirigami.Settings.isMobile && !Kirigami.Settings.hasPlatformMenuBar) menu.visible = !Config.showMenubar
                        }
                    }

                    Layout.fillHeight: true
                    overflowIconName: "application-menu"

                    property var hamburgerActions: switch (applicationWindow().mode) {
                        case KalendarApplication.Mail:
                            return mailApplication.hamburgerActions;
                        case KalendarApplication.Contact:
                            return contactApplication.hamburgerActions;
                        case KalendarApplication.Event:
                        case KalendarApplication.Todo:
                        case KalendarApplication.ThreeDay:
                        case KalendarApplication.Day:
                        case KalendarApplication.Week:
                        case KalendarApplication.Month:
                        case KalendarApplication.Schedule:
                            return calendarApplication.hamburgerActions;
                        default:
                            return undefined;
                    }

                    property list<QQC2.Action> appActions: [
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

                    actions: []
                    onHamburgerActionsChanged: {
                        actions = []
                        for (let action in hamburgerActions) {
                            actions.push(hamburgerActions[action])
                        }
                        for (let action in appActions) {
                            actions.push(appActions[action])
                        }
                    }

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
        }

        QQC2.ScrollView {
            id: generalView
            implicitWidth: Kirigami.Units.gridUnit * 16
            Layout.fillWidth: true
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            contentWidth: availableWidth

            clip: true

            QQC2.Control {
                anchors.fill: parent
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0
                topInset: toolbar.visible ? -Kirigami.Units.smallSpacing - 1 : 0
                contentItem: ColumnLayout {
                    spacing: 0

                    Repeater {
                        id: generalActions
                        property list<Kirigami.Action> actions: [
                            KActionFromAction {
                                kalendarAction: "open_month_view"
                                checkable: false
                                onTriggered: {
                                    monthViewAction.trigger()
                                    if (mainDrawer.modal) mainDrawer.close()
                                }
                            },
                            KActionFromAction {
                                kalendarAction: "open_week_view"
                                // Override the default checkable behaviour as we want this to stay highlighted
                                // in any of the hourly views, at least in desktop mode
                                checkable: true
                                checked: pageStack.currentItem && (
                                         pageStack.currentItem.mode & (KalendarApplication.Week | KalendarApplication.ThreeDay | KalendarApplication.Day))
                                onTriggered: {
                                    weekViewAction.trigger()
                                    if (mainDrawer.modal) mainDrawer.close()
                                }
                            },
                            KActionFromAction {
                                kalendarAction: "open_schedule_view"
                                checkable: false
                                onTriggered: {
                                    scheduleViewAction.trigger()
                                    if (mainDrawer.modal) mainDrawer.close()
                                }
                            },
                            KActionFromAction {
                                kalendarAction: "open_todo_view"
                                checkable: false
                                onTriggered: {
                                    todoViewAction.trigger()
                                    if (mainDrawer.modal) mainDrawer.close()
                                }
                            },
                            KActionFromAction {
                                kalendarAction: "open_contact_view"
                                checkable: false
                                onTriggered: {
                                    contactViewAction.trigger()
                                    if (mainDrawer.modal) mainDrawer.close()
                                }
                            },
                            KActionFromAction {
                                kalendarAction: "open_mail_view"
                                checkable: false
                                visible: Config.enableMailIntegration
                                onTriggered: {
                                    mailViewAction.trigger()
                                    if (mainDrawer.modal) mainDrawer.close()
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
                                    if (mainDrawer.modal) mainDrawer.close()
                                }
                            },
                            KActionFromAction {
                                text: i18n("Settings")
                                kalendarAction: "options_configure"
                                onTriggered: {
                                    configureAction.trigger()
                                    if (mainDrawer.modal) mainDrawer.close()
                                }
                            }
                        ]
                        model: !Kirigami.Settings.isMobile ? actions : mobileActions
                        delegate: Kirigami.BasicListItem {
                            label: modelData.text
                            icon: modelData.icon.name
                            separatorVisible: false
                            action: modelData
                            visible: modelData.visible
                        }
                    }
                }

                background: Rectangle {
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

            opacity: mainDrawer.collapsed ? 0 : 1
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

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true

            active: true
            sourceComponent: mode === KalendarApplication.Mail ? mailView : calendarAddressBookComponent

            opacity: mainDrawer.collapsed ? 0 : 1
            clip: true
            z: -3

            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Component {
            id: calendarAddressBookComponent

            CheckableCollectionNavigationView {
                onCollectionCheckChanged: mainDrawer.collectionCheckChanged()
                onCloseParentDrawer: mainDrawer.close()
                onDeleteCollection: mainDrawer.deleteCollection(collectionId, collectionDetails)

                mode: mainDrawer.mode
                parentDrawerModal: mainDrawer.modal
                parentDrawerCollapsed: mainDrawer.collapsed
            }
        }

        Component {
            id: mailView

            MailSidebar {}
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
        visible: mainDrawer.mode === KalendarApplication.Todo
        separatorVisible: false
        onClicked: {
            Filter.reset()
            if (mainDrawer.modal && mainDrawer.mode === KalendarApplication.Todo) {
                mainDrawer.close()
            }
        }
    }

    function collectionCheckChanged() {
        if (mode & (KalendarApplication.Event | KalendarApplication.Todo)) {
            CalendarManager.save();
        }
    }
}
