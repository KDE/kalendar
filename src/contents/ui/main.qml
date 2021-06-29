// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
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

    EventEditor {
        id: eventEditor
        onAdded: CalendarManager.addEvent(collectionId, event.eventPtr)
        onEdited: CalendarManager.editEvent(event.eventPtr)
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

    globalDrawer: Kirigami.GlobalDrawer {
        isMenu: true
        actions: [
            Kirigami.Action {
                text: i18n("Settings")
                icon.name: "settings-configure"
                onTriggered: pageStack.layers.push("qrc:/SettingsPage.qml")
            }
        ]
    }

    Component {
        id: monthViewComponent

        MonthView {
            // Make sure we get day from correct date, that is in the month we want
            title: DateUtils.addDaysToDate(startDate, 7).toLocaleDateString(Qt.locale(), "<b>MMMM</b> yyyy")
            currentDate: root.currentDate
            startDate: DateUtils.getFirstDayOfWeek(DateUtils.getFirstDayOfMonth(root.selectedDate))
            month: root.selectedDate.getMonth()

            onEditEventReceived: {
                eventEditor.eventWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; EventWrapper {id: event}',
                                                              eventEditor,
                                                              "event");
                eventEditor.eventWrapper.eventPtr = receivedEventPtr;
                eventEditor.eventWrapper.collectionId = receivedCollectionId;
                eventEditor.editMode = true;
                eventEditor.open();
            }
            onDeleteEventReceived: {
                deleteEventSheet.eventWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; EventWrapper {id: event}',
                                                                    deleteEventSheet,
                                                                    "event");
                deleteEventSheet.eventWrapper.eventPtr = receivedEventPtr
                deleteEventSheet.deleteDate = receivedDeleteDate
                deleteEventSheet.open()
            }

            actions.contextualActions: [
                Kirigami.Action {
                    text: i18n("Add event")
                    icon.name: "list-add"
                    onTriggered: {
                        if (eventEditor.editMode || !eventEditor.eventWrapper) {
                            eventEditor.eventWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; EventWrapper {id: event}',
                                                                          eventEditor,
                                                                          "event");
                        }
                        eventEditor.editMode = false;
                        eventEditor.open();
                    }
                }
            ]
        }
    }
}
