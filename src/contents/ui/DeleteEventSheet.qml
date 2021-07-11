// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0

Kirigami.OverlaySheet {
    id: deleteEventSheet

    signal addException(date exceptionDate, var eventWrapper)
    signal addRecurrenceEndDate(date endDate, var eventWrapper)
    signal deleteEvent(var eventPtr)

    property var eventWrapper
    property date deleteDate

    header: Kirigami.Heading {
        text: i18n("Delete event")
    }

    footer: Loader {
        active: eventWrapper !== undefined
        sourceComponent: QQC2.DialogButtonBox {

            QQC2.Button {
                icon.name: "deletecell"
                text: i18n("Only delete current")
                visible: eventWrapper.recurrenceData.type > 0
                onClicked: addException(deleteDate, eventWrapper)
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            QQC2.Button {
                icon.name: "edit-table-delete-row"
                text: i18n("Also delete future")
                visible: eventWrapper.recurrenceData.type > 0
                onClicked: {
                    // We want to include the delete date in the deletion
                    // Setting the last recurrence day is not inclusive
                    // (i.e. occurrence on that day is not deleted)
                    let dateBeforeDeleteDate = new Date(deleteDate);
                    dateBeforeDeleteDate.setDate(deleteDate.getDate() - 1);
                    addRecurrenceEndDate(dateBeforeDeleteDate, eventWrapper)
                }
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            QQC2.Button {
                icon.name: "delete"
                text: eventWrapper.recurrenceData.type > 0 ? i18n("Delete all") : i18n("Delete")
                onClicked: deleteEvent(eventWrapper.eventPtr)
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            QQC2.Button {
                icon.name: "dialog-cancel"
                text: i18n("Cancel")
                onClicked: deleteEventSheet.close()
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.DestructiveRole
            }

            onRejected: deleteEventSheet.close()
        }
    }

    Loader {
        Layout.maximumWidth: Kirigami.Units.gridUnit * 30

        active: eventWrapper !== undefined
        sourceComponent: RowLayout {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 30

            Kirigami.Icon {
                Layout.fillHeight: true
                Layout.minimumHeight: Kirigami.Units.gridUnit * 4
                Layout.minimumWidth: height
                source: "dialog-warning"
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Do you really want to delete item: \"%1\"?", eventWrapper.summary)
                visible: eventWrapper.recurrenceData.type === 0
                wrapMode: Text.WordWrap
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("The calendar item \"%1\" recurs over multiple dates. Do you want to delete the selected ocurrence on %2, also future occurrences, or all of its occurrences?", eventWrapper.summary, deleteDate.toLocaleDateString(Qt.locale()))
                visible: eventWrapper.recurrenceData.type > 0
                wrapMode: Text.WordWrap
            }
        }
    }
}
