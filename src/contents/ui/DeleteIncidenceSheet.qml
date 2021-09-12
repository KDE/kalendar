// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0

Kirigami.OverlaySheet {
    id: deleteIncidenceSheet

    signal addException(date exceptionDate, var incidenceWrapper)
    signal addRecurrenceEndDate(date endDate, var incidenceWrapper)
    signal deleteIncidence(var incidencePtr)

    property var incidenceWrapper
    property date deleteDate

    header: Kirigami.Heading {
        text: incidenceWrapper.incidenceTypeStr ?
            i18nc("%1 is the type of the incidence (e.g event, todo, journal entry)", "Delete %1", incidenceWrapper.incidenceTypeStr) : i18n("Delete Incidence")
    }

    footer: Loader {
        active: incidenceWrapper !== undefined
        sourceComponent: QQC2.DialogButtonBox {

            QQC2.Button {
                icon.name: "deletecell"
                text: i18n("Only Delete Current")
                visible: incidenceWrapper.recurrenceData.type > 0
                onClicked: addException(deleteDate, incidenceWrapper)
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            QQC2.Button {
                icon.name: "edit-table-delete-row"
                text: i18n("Also Delete Future")
                visible: incidenceWrapper.recurrenceData.type > 0
                onClicked: {
                    // We want to include the delete date in the deletion
                    // Setting the last recurrence day is not inclusive
                    // (i.e. occurrence on that day is not deleted)
                    let dateBeforeDeleteDate = new Date(deleteDate);
                    dateBeforeDeleteDate.setDate(deleteDate.getDate() - 1);
                    addRecurrenceEndDate(dateBeforeDeleteDate, incidenceWrapper)
                }
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            QQC2.Button {
                icon.name: "delete"
                text: incidenceWrapper.recurrenceData.type > 0 ? i18n("Delete All") : i18n("Delete")
                onClicked: deleteIncidence(incidenceWrapper.incidencePtr)
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            QQC2.Button {
                icon.name: "dialog-cancel"
                text: i18n("Cancel")
                onClicked: deleteIncidenceSheet.close()
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.DestructiveRole
            }

            onRejected: deleteIncidenceSheet.close()
        }
    }

    Loader {
        Layout.maximumWidth: Kirigami.Units.gridUnit * 30

        active: incidenceWrapper !== undefined
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
                text: i18n("Do you really want to delete item: \"%1\"?", incidenceWrapper.summary)
                visible: incidenceWrapper.recurrenceData.type === 0
                wrapMode: Text.WordWrap
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("The calendar item \"%1\" recurs over multiple dates. Do you want to delete the selected ocurrence on %2, also future occurrences, or all of its occurrences?", incidenceWrapper.summary, deleteDate.toLocaleDateString(Qt.locale()))
                visible: incidenceWrapper.recurrenceData.type > 0
                wrapMode: Text.WordWrap
            }
        }
    }
}
