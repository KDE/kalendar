// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.16 as Kirigami
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
    signal deleteCalendar(int collectionId, var collectionDetails)

    property bool todoMode: false
    property alias toolbar: toolbar
    property var activeTags : []
    property alias searchText: searchField.text

    Connections {
        target: applicationWindow()
        function onWidthChanged() {
            if(!Kirigami.Settings.isMobile && !Config.forceCollapsedSidebar) {
                sidebar.collapsed = applicationWindow().width < Kirigami.Units.gridUnit * 50
            } // HACK: Workaround for incredibly glitchy behaviour caused by using wideScreen property
        }
    }

    Connections {
        target: Config
        function onForceCollapsedSidebarChanged() {
            sidebar.collapsed = Config.forceCollapsedSidebar;
        }
    }

    edge: Qt.application.layoutDirection === Qt.RightToLeft ? Qt.RightEdge : Qt.LeftEdge
    modal: Kirigami.Settings.isMobile || (applicationWindow().width < Kirigami.Units.gridUnit * 50 && !collapsed) // Only modal when not collapsed, otherwise collapsed won't show.
    // Changing the modality automatically opens the drawer, so making the sidebar collapsed opens the
    // drawer. This is more intuitive than having two buttons each of which handle different aspects of
    // the drawer.
    collapsed: Config.forceCollapsedSidebar
    handleVisible: modal
    handleClosedIcon.source: null
    handleOpenIcon.source: null
    drawerOpen: !Kirigami.Settings.isMobile
    // We want the modal drawer to close into a collapsed non-modal drawer, not to close the drawer altogether.
    // Otherwise the collapsed drawer would not be visible (and without the handle we'd have no way to open it).
    // We also have to re-notify because of some dumb glitch, idk.
    onDrawerOpenChanged: if(!Kirigami.Settings.isMobile && modal) collapsed = true, drawerOpen = true, collapsedChanged()
    width: sidebar.collapsed ? menu.Layout.minimumWidth + Kirigami.Units.smallSpacing : Kirigami.Units.gridUnit * 16
    Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad } }

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

            leftPadding: sidebar.collapsed ? 0 : Kirigami.Units.smallSpacing
            rightPadding: sidebar.collapsed ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
            topPadding: 0
            bottomPadding: 0

            RowLayout {
                anchors.fill: parent

                Kirigami.Heading { // TODO: Remove once search results page complete
                    Layout.leftMargin: Kirigami.Units.smallSpacing + Kirigami.Units.largeSpacing
                    text: i18n("Kalendar")

                    visible: !sidebar.todoMode
                    opacity: sidebar.collapsed ? 0 : 1
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

                    visible: sidebar.todoMode
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
                        function onShowMenubarChanged() {
                            if(!Kirigami.Settings.isMobile && !Kirigami.Settings.hasPlatformMenuBar) menu.visible = !Config.showMenubar
                        }
                    }

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
                        KActionFromAction {
                            kalendarAction: "import_calendar"
                        },
                        KActionFromAction {
                            kalendarAction: "refresh_all_calendars"
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

                Kirigami.BasicListItem {
                    id: tagsHeadingItem

                    property bool expanded: Config.tagsSectionExpanded

                    Layout.topMargin: Kirigami.Units.largeSpacing
                    separatorVisible: false
                    hoverEnabled: false
                    visible: TagManager.tagModel.rowCount() > 0
                    Accessible.name: tagsHeadingItem.expanded ? i18nc('Accessible description of dropdown menu', 'Tags, Expanded') : i18nc('Accessible description of dropdown menu', 'Tags, Collapsed')

                    Kirigami.Heading { id: headingSizeCalculator }

                    highlighted: visualFocus
                    leading: Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                        isMask: true
                        color: tagsHeadingItem.labelItem.color
                        source: "action-rss_tag"
                    }
                    text: i18n("Tags")
                    labelItem.color: visualFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                    labelItem.font.pointSize: headingSizeCalculator.headerPointSize(4)
                    Layout.bottomMargin: Kirigami.Units.largeSpacing
                    trailing: Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                        source: tagsHeadingItem.expanded ? 'arrow-up' : 'arrow-down'
                        isMask: true
                        color: tagsHeadingItem.labelItem.color
                    }
                    onClicked: {
                        Config.tagsSectionExpanded = !Config.tagsSectionExpanded;
                        Config.save();
                    }
                }

                Flow {
                    id: tagFlow
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Settings.isMobile ?
                        Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.largeSpacing * 3 :
                        Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.largeSpacing * 2
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    Layout.bottomMargin: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing
                    visible: TagManager.tagModel.rowCount() > 0 && tagsHeadingItem.expanded

                    Repeater {
                        id: tagList

                        model: parent.visible ? TagManager.tagModel : []

                        delegate: Tag {
                            implicitWidth: itemLayout.implicitWidth > tagFlow.width ? tagFlow.width : itemLayout.implicitWidth
                            text: model.display
                            showAction: false
                            activeFocusOnTab: true
                            backgroundColor: sidebar.activeTags.includes(model.display) ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                            enabled: !sidebar.collapsed
                            onClicked: tagClicked(model.display)
                        }
                    }
                }

                Kirigami.BasicListItem {
                    id: calendarHeadingItem
                    property bool expanded: Config.calendarsSectionExpanded

                    separatorVisible: false
                    hoverEnabled: false
                    Layout.topMargin: Kirigami.Units.largeSpacing

                    leading: Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                        source: "view-calendar"
                        isMask: true
                        color: calendarHeadingItem.labelItem.color
                    }
                    text: i18n("Calendars")
                    highlighted: visualFocus
                    labelItem.color: visualFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                    labelItem.font.pointSize: headingSizeCalculator.headerPointSize(4)
                    trailing: Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                        source: calendarHeadingItem.expanded ? 'arrow-up' : 'arrow-down'
                        isMask: true
                        color: calendarHeadingItem.labelItem.color
                    }
                    onClicked: {
                        Config.calendarsSectionExpanded = !Config.calendarsSectionExpanded;
                        Config.save();
                    }
                }

                Repeater {
                    id: calendarList

                    property var calendarModel: KDescendantsProxyModel {
                        model: sidebar.todoMode ? CalendarManager.todoCollections : CalendarManager.viewCollections
                    }

                    model: calendarHeadingItem.expanded ? calendarModel : []

                    delegate: DelegateChooser {
                        role: 'kDescendantExpandable'
                        DelegateChoice {
                            roleValue: true

                            Kirigami.BasicListItem {
                                id: calendarSourceHeading
                                label: display
                                highlighted: visualFocus
                                labelItem.color: visualFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                                labelItem.font.weight: Font.DemiBold
                                Layout.topMargin: 2 * Kirigami.Units.largeSpacing
                                leftPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing
                                hoverEnabled: false
                                enabled: !sidebar.collapsed

                                separatorVisible: false

                                leading: Kirigami.Icon {
                                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                    color: calendarSourceHeading.labelItem.color
                                    isMask: true
                                    source: model.decoration
                                }
                                leadingPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                                trailing: Kirigami.Icon {
                                    implicitWidth: Kirigami.Units.iconSizes.small
                                    implicitHeight: Kirigami.Units.iconSizes.small
                                    source: model.kDescendantExpanded ? 'arrow-up' : 'arrow-down'
                                    color: calendarSourceHeading.labelItem.color
                                    isMask: true
                                }

                                onClicked: calendarList.model.toggleChildren(index)
                            }
                        }

                        DelegateChoice {
                            roleValue: false
                            Kirigami.BasicListItem {
                                id: calendarItem
                                label: display
                                labelItem.color: Kirigami.Theme.textColor
                                leftPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing
                                separatorVisible: false
                                reserveSpaceForIcon: true
                                enabled: !sidebar.collapsed

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

                                CalendarItemMouseArea {
                                    id: calendarItemMouseArea
                                    parent: calendarItem.contentItem // Otherwise label elide breaks
                                    collectionId: model.collectionId
                                    anchors.fill: parent

                                    onDeleteCalendar: sidebar.deleteCalendar(collectionId, collectionDetails)
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
