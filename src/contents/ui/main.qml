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
        onCancel: pageStack.pop(root)
    }

    Loader {
        id: editorWindowedLoader
        active: false
        sourceComponent: Kirigami.ApplicationWindow {
            id: root

            width: Kirigami.Units.gridUnit * 40
            height: Kirigami.Units.gridUnit * 30

            // Probably a more elegant way of accessing the editor from outside than this.
            property var eventEditor: eventEditorInLoader

            pageStack.initialPage: eventEditorInLoader

            EventEditor {
                id: eventEditorInLoader
                onAdded: CalendarManager.addEvent(collectionId, event.eventPtr)
                onEdited: CalendarManager.editEvent(event.eventPtr)
                onCancel: root.close()
            }

            visible: true
            onClosing: editorWindowedLoader.active = false
        }
    }

    function editorToUse() {
        if (applicationWindow().wideScreen) {
            editorWindowedLoader.active = true
            return editorWindowedLoader.item.eventEditor
        } else {
            pageStack.push(eventEditor);
            return eventEditor;
        }
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
                let editorToUse = root.editorToUse();
                editorToUse.eventWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; EventWrapper {id: event}',
                                                              editorToUse,
                                                              "event");
                editorToUse.eventWrapper.eventPtr = receivedEventPtr;
                editorToUse.eventWrapper.collectionId = receivedCollectionId;
                editorToUse.editMode = true;
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
                        let editorToUse = root.editorToUse();
                        if (editorToUse.editMode || !editorToUse.eventWrapper) {
                            editorToUse.eventWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; EventWrapper {id: event}',
                                                                          editorToUse,
                                                                          "event");
                        }
                        editorToUse.editMode = false;
                    }
                }
            ]
        }
    }
}
