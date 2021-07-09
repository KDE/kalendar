// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.15 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15 
import org.kde.kalendar 1.0
import QtQml.Models 2.15
import "dateutils.js" as DateUtils

Kirigami.ApplicationWindow {
    id: root

    property date currentDate: new Date()
    property date selectedDate: currentDate

    title: i18n("Calendar")

    pageStack.initialPage: monthViewComponent

    globalDrawer: Kirigami.GlobalDrawer {
        isMenu: true
        actions: [
            Kirigami.Action {
                text: i18n("Settings")
                onTriggered: pageStack.layers.push("qrc:/SettingsPage.qml")
            }
        ]
    }

    contextDrawer: EventInfo {
        id: eventInfo

        contentItem.implicitWidth: Kirigami.Units.gridUnit * 25
        modal: !root.wideScreen || !enabled
        onEnabledChanged: drawerOpen = enabled && !modal
        onModalChanged: drawerOpen = !modal
        enabled: eventData != undefined && pageStack.layers.depth < 2 && pageStack.depth < 3
        handleVisible: enabled && pageStack.layers.depth < 2 && pageStack.depth < 3
        interactive: Kirigami.Settings.isMobile

        onEditEvent: {
            root.pageStack.pushDialogLayer("qrc:/EventEditor.qml", {
                eventWrapper: CalendarManager.createNewEventWrapperFrom(eventPtr, collectionId),
                editMode: true,
            });
            if (modal) { eventInfo.close() }
        }
        onDeleteEvent: {
            setUpDelete(eventPtr, deleteDate)
            if (modal) { eventInfo.close() }
        }
    }

    function setUpView(modelData, collectionData) {
        eventInfo.eventData = modelData
        eventInfo.collectionData = collectionData
        eventInfo.open()
    }

    function setUpDelete(eventPtr, deleteDate) {
        deleteEventSheet.eventWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; EventWrapper {id: event}',
                                                           deleteEventSheet,
                                                           "event");
        deleteEventSheet.eventWrapper.eventPtr = eventPtr
        deleteEventSheet.deleteDate = deleteDate
        deleteEventSheet.open()
    }

    DeleteEventSheet {
        id: deleteEventSheet
        onAddException: {
            eventWrapper.recurrenceExceptionsModel.addExceptionDateTime(exceptionDate);
            CalendarManager.editEvent(eventWrapper.eventPtr);
            deleteEventSheet.close();
        }
        onAddRecurrenceEndDate: {
            eventWrapper.recurrenceEndDateTime = endDate;
            CalendarManager.editEvent(eventWrapper.eventPtr);
            deleteEventSheet.close();
        }
        onDeleteEvent: {
            CalendarManager.deleteEvent(eventPtr);
            deleteEventSheet.close();
        }
    }

    Component {
        id: monthViewComponent

        MonthView {
            // Make sure we get day from correct date, that is in the month we want
            title: DateUtils.addDaysToDate(startDate, 7).toLocaleDateString(Qt.locale(), "<b>MMMM</b> yyyy")
            currentDate: root.currentDate
            startDate: DateUtils.getFirstDayOfWeek(DateUtils.getFirstDayOfMonth(root.selectedDate))
            month: root.selectedDate.getMonth()

            Layout.minimumWidth: applicationWindow().width * 0.66

            onViewEventReceived: root.setUpView(receivedModelData, receivedCollectionData)
            onEditEventReceived: root.setUpEdit(receivedEventPtr, receivedCollectionData)
            onDeleteEventReceived: root.setUpDelete(receivedEventPtr, receivedDeleteDate)

            actions.contextualActions: [
                Kirigami.Action {
                    text: i18n("Add event")
                    icon.name: "list-add"
                    onTriggered: {
                        root.pageStack.pushDialogLayer("qrc:/EventEditor.qml", {
                            eventWrapper: CalendarManager.createNewEvent(),
                            editMode: false,
                        });
                    }
                }
            ]
        }
    }
}
