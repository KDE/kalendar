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
    property bool recurringEvent: eventWrapper.recurrenceType > 0

    header: Kirigami.Heading {
        text: i18n("Delete event")
    }

    footer: QQC2.DialogButtonBox {

        QQC2.Button {
            icon.name: "deletecell"
            text: i18n("Only delete current")
            visible: recurringEvent
            onClicked: addException(deleteDate, eventWrapper)
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
        }

        QQC2.Button {
            icon.name: "edit-table-delete-row"
            text: i18n("Also delete future")
            visible: recurringEvent
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
            text: recurringEvent ? i18n("Delete all") : i18n("Delete")
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

    RowLayout {
        Layout.maximumWidth: Kirigami.Units.gridUnit * 30

        Kirigami.Icon {
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 4
            Layout.minimumWidth: height
            source: "dialog-warning"
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("Do you really want to delete item: ") + `"${eventWrapper.summary}"?`
            visible: !recurringEvent
            wrapMode: Text.WordWrap
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("The calendar item ") + `"${eventWrapper.summary}"` +  i18n(" recurs over multiple dates. Do you want to delete the current one on %1, also future occurrences, or all its occurrences?", deleteDate.toLocaleDateString(Qt.locale()))
            visible: recurringEvent
            wrapMode: Text.WordWrap
        }
    }
}
