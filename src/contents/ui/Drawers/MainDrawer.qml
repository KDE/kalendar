// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.16 as Kirigami
import org.kde.kalendar 1.0
import org.kde.kalendar.contact 1.0
import org.kde.kalendar.mail 1.0
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0
import QtGraphicalEffects 1.12

Kirigami.OverlayDrawer {
    id: mainDrawer

    signal calendarClicked(int collectionId)
    signal calendarCheckChanged(int collectionId, bool checked)
    signal viewAllTodosClicked
    signal tagClicked(string tagName)
    signal deleteCalendar(int collectionId, var collectionDetails)

    property var mode: KalendarApplication.Event
    property alias toolbar: toolbar
    property var activeTags : []
    property alias searchText: searchField.text

    Connections {
        target: applicationWindow()
        function onWidthChanged() {
            if(!Kirigami.Settings.isMobile && !Config.forceCollapsedMainDrawer) {
                mainDrawer.collapsed = applicationWindow().width < Kirigami.Units.gridUnit * 50
            } // HACK: Workaround for incredibly glitchy behaviour caused by using wideScreen property
        }
    }

    Connections {
        target: Config
        function onForceCollapsedMainDrawerChanged() {
            mainDrawer.collapsed = Config.forceCollapsedMainDrawer;
        }
    }

    edge: Qt.application.layoutDirection === Qt.RightToLeft ? Qt.RightEdge : Qt.LeftEdge
    modal: Kirigami.Settings.isMobile
    handleVisible: modal
    handleClosedIcon.source: null
    handleOpenIcon.source: null
    width: mainDrawer.collapsed ? menu.Layout.minimumWidth + Kirigami.Units.smallSpacing : Kirigami.Units.gridUnit * 16

    Component.onCompleted: {
        collapsed = Config.forceCollapsedMainDrawer // Fix crashing caused by setting on load
        ContactManager.contactCollections; // Fix crashing because the contactCollections was created too late
    }
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

                    visible: mainDrawer.mode !== KalendarApplication.Event
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
                                         pageStack.currentItem.objectName == "weekView" ||
                                         pageStack.currentItem.objectName == "threeDayView" ||
                                         pageStack.currentItem.objectName == "dayView"
                                         )
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
            sourceComponent: mode === KalendarApplication.Mail ? mailView : calendarContactView
        }

        Component {
            id: calendarContactView
            QQC2.ScrollView {
                id: calendarView
                implicitWidth: Kirigami.Units.gridUnit * 16
                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
                contentWidth: availableWidth
                clip: true
                z: -2

                opacity: mainDrawer.collapsed ? 0 : 1
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
                        visible: TagManager.tagModel.rowCount() > 0 && mode !== KalendarApplication.Contact
                        Accessible.name: tagsHeadingItem.expanded ? i18nc('Accessible description of dropdown menu', 'Tags, Expanded') : i18nc('Accessible description of dropdown menu', 'Tags, Collapsed')

                        Kirigami.Heading {
                            id: headingSizeCalculator
                            level: 4
                        }

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
                        labelItem.font.pointSize: headingSizeCalculator.font.pointSize
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
                            Kirigami.Units.largeSpacing * 2 :
                            Kirigami.Units.largeSpacing
                        Layout.rightMargin: Kirigami.Units.largeSpacing
                        Layout.bottomMargin: Kirigami.Units.largeSpacing
                        spacing: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing
                        visible: TagManager.tagModel.rowCount() > 0 && tagsHeadingItem.expanded && mode !== KalendarApplication.Contact

                        Repeater {
                            id: tagList

                            model: parent.visible ? TagManager.tagModel : []

                            delegate: Tag {
                                implicitWidth: itemLayout.implicitWidth > tagFlow.width ? tagFlow.width : itemLayout.implicitWidth
                                text: model.display
                                showAction: false
                                activeFocusOnTab: true
                                backgroundColor: mainDrawer.activeTags.includes(model.display) ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                                enabled: !mainDrawer.collapsed
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
                        text: switch (mode) {
                            case KalendarApplication.Event:
                            case KalendarApplication.Todo:
                                return i18n("Calendars");
                            case KalendarApplication.Contact:
                                return i18n("Contacts");
                        }
                        highlighted: visualFocus
                        labelItem.color: visualFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                        labelItem.font.pointSize: headingSizeCalculator.font.pointSize
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
                            model: switch(mainDrawer.mode) {
                            case KalendarApplication.Todo:
                                return CalendarManager.todoCollections;
                            case KalendarApplication.Event:
                                return CalendarManager.viewCollections;
                            case KalendarApplication.Contact:
                                return ContactManager.contactCollections;
                            default:
                                console.log('Should not happen', mainDrawer.mode)
                            }
                        }

                        model: calendarHeadingItem.expanded ? calendarModel : []

                        delegate: DelegateChooser {
                            role: 'kDescendantExpandable'
                            DelegateChoice {
                                roleValue: true

                                Kirigami.BasicListItem {
                                    id: calendarSourceItem
                                    label: display
                                    highlighted: visualFocus || incidenceDropArea.containsDrag
                                    labelItem.color: visualFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                                    labelItem.font.weight: Font.DemiBold
                                    Layout.topMargin: 2 * Kirigami.Units.largeSpacing
                                    leftPadding: Kirigami.Settings.isMobile ?
                                        (Kirigami.Units.largeSpacing * 2 * model.kDescendantLevel) + (Kirigami.Units.iconSizes.smallMedium * (model.kDescendantLevel - 1)) :
                                        (Kirigami.Units.largeSpacing * model.kDescendantLevel) + (Kirigami.Units.iconSizes.smallMedium * (model.kDescendantLevel - 1))
                                    hoverEnabled: false
                                    enabled: !mainDrawer.collapsed

                                    separatorVisible: false

                                    leading: Kirigami.Icon {
                                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                        color: calendarSourceItem.labelItem.color
                                        isMask: true
                                        source: model.decoration
                                    }
                                    leadingPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                                    Connections {
                                        target: AgentConfiguration
                                        property var collectionDetails: CalendarManager.getCollectionDetails(collectionId)

                                        function onAgentProgressChanged(agentData) {
                                            if(agentData.instanceId === collectionDetails.resource &&
                                                agentData.status === AgentConfiguration.Running) {

                                                loadingIndicator.visible = true;
                                            } else if (agentData.instanceId === collectionDetails.resource) {
                                                loadingIndicator.visible = false;
                                            }
                                        }
                                    }

                                    trailing: RowLayout {
                                        QQC2.BusyIndicator {
                                            id: loadingIndicator
                                            Layout.fillHeight: true
                                            padding: 0
                                            visible: false
                                            running: visible
                                        }

                                        Kirigami.Icon {
                                            implicitWidth: Kirigami.Units.iconSizes.small
                                            implicitHeight: Kirigami.Units.iconSizes.small
                                            source: model.kDescendantExpanded ? 'arrow-up' : 'arrow-down'
                                            color: calendarSourceItem.labelItem.color
                                            isMask: true
                                        }
                                        ColoredCheckbox {
                                            id: calendarCheckbox

                                            Layout.fillHeight: true
                                            visible: model.checkState != null
                                            color: model.collectionColor ?? Kirigami.Theme.highlightedTextColor
                                            checked: model.checkState === 2
                                            onCheckedChanged: calendarCheckChanged(collectionId, checked)
                                            onClicked: {
                                                model.checkState = model.checkState === 0 ? 2 : 0
                                                calendarCheckChanged(collectionId, checked)
                                            }
                                        }
                                    }

                                    onClicked: calendarList.model.toggleChildren(index)

                                    CalendarItemTapHandler {
                                        parent: calendarSourceItem.contentItem // Otherwise label elide breaks
                                        collectionId: model.collectionId
                                        collectionDetails: CalendarManager.getCollectionDetails(collectionId)
                                        enabled: mode !== KalendarApplication.Contact
                                    }

                                    DropArea {
                                        id: incidenceDropArea
                                        anchors.fill: parent
                                        z: 9999
                                        enabled: calendarSourceItemMouseArea.collectionDetails.canCreate
                                        onDropped: if(drop.source.objectName === "taskDelegate") {
                                            CalendarManager.changeIncidenceCollection(drop.source.incidencePtr, calendarSourceItemMouseArea.collectionId);

                                            const pos = mapToItem(applicationWindow().contentItem, x, y);
                                            drop.source.caughtX = pos.x;
                                            drop.source.caughtY = pos.y;
                                            drop.source.caught = true;
                                        }
                                    }
                                }
                            }

                            DelegateChoice {
                                roleValue: false
                                Kirigami.BasicListItem {
                                    id: calendarItem
                                    label: display
                                    labelItem.color: Kirigami.Theme.textColor
                                    leftPadding: Kirigami.Settings.isMobile ?
                                        (Kirigami.Units.largeSpacing * 2 * model.kDescendantLevel) + (Kirigami.Units.iconSizes.smallMedium * (model.kDescendantLevel - 1)) :
                                        (Kirigami.Units.largeSpacing * model.kDescendantLevel) + (Kirigami.Units.iconSizes.smallMedium * (model.kDescendantLevel - 1))
                                    separatorVisible: false
                                    enabled: !mainDrawer.collapsed
                                    highlighted: visualFocus || incidenceDropArea.containsDrag

                                    leading: Kirigami.Icon {
                                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                        source: model.decoration
                                    }
                                    leadingPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

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
                                        if(mainDrawer.modal) mainDrawer.close()
                                    }

                                    CalendarItemHandler {
                                        parent: calendarItem.contentItem // Otherwise label elide breaks
                                        collectionId: model.collectionId
                                        collectionDetails: CalendarManager.getCollectionDetails(collectionId)
                                        enabled: mode !== KalendarApplication.Contact
                                        onDeleteCalendar: mainDrawer.deleteCalendar(collectionId, collectionDetails)
                                    }

                                    DropArea {
                                        id: incidenceDropArea
                                        anchors.fill: parent
                                        z: 9999
                                        enabled: calendarItemMouseArea.collectionDetails.canCreate
                                        onDropped: if(drop.source.objectName === "taskDelegate") {
                                            CalendarManager.changeIncidenceCollection(drop.source.incidencePtr, calendarItemMouseArea.collectionId);

                                            const pos = mapToItem(applicationWindow().contentItem, x, y);
                                            drop.source.caughtX = pos.x;
                                            drop.source.caughtY = pos.y;
                                            drop.source.caught = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
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
            viewAllTodosClicked();
            if(mainDrawer.modal && mainDrawer.mode === KalendarApplication.Todo) mainDrawer.close()
        }
    }
}
