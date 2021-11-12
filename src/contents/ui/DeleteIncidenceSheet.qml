// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0

Kirigami.Page {
    id: deleteSheet

    signal addException(date exceptionDate, var incidenceWrapper)
    signal addRecurrenceEndDate(date endDate, var incidenceWrapper)
    signal deleteIncidence(var incidencePtr)
    signal deleteIncidenceWithChildren(var incidencePtr)
    signal cancel

    // For incidence deletion
    property var incidenceWrapper
    property bool incidenceHasChildren: incidenceWrapper !== undefined ? CalendarManager.hasChildren(incidenceWrapper.incidencePtr) : false
    property date deleteDate

    padding: Kirigami.Units.largeSpacing

    title: incidenceWrapper && incidenceWrapper.incidenceTypeStr ?
        i18nc("%1 is the type of the incidence (e.g event, todo, journal entry)", "Delete %1", incidenceWrapper.incidenceTypeStr) :
        i18n("Delete")

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Kirigami.Icon {
                Layout.fillHeight: true
                Layout.minimumHeight: Kirigami.Units.gridUnit * 3
                Layout.minimumWidth: height
                source: "dialog-warning"
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: if(incidenceWrapper.recurrenceData.type === 0 && !deleteSheet.incidenceHasChildren) {
                    return i18n("Do you want to delete item: \"%1\"?", incidenceWrapper.summary)
                } else if(incidenceWrapper.recurrenceData.type === 0 && deleteSheet.incidenceHasChildren) {
                    return i18n("Item \"%1\" has sub-items. Do you want to delete all related items, or just the currently selected item?", incidenceWrapper.summary)
                } else if (incidenceWrapper.recurrenceData.type > 0 && deleteSheet.incidenceHasChildren) {
                    return i18n("The calendar item \"%1\" recurs over multiple dates. This item also has sub-items.\n\nDo you want to delete the selected occurrence on %2, also future occurrences, or all of its occurrences?\n\nDeleting all will also delete sub-items!", incidenceWrapper.summary, deleteDate.toLocaleDateString(Qt.locale()))
                } else if (incidenceWrapper.recurrenceData.type > 0) {
                    return i18n("The calendar item \"%1\" recurs over multiple dates. Do you want to delete the selected occurrence on %2, also future occurrences, or all of its occurrences?", incidenceWrapper.summary, deleteDate.toLocaleDateString(Qt.locale()))
                }
                wrapMode: Text.WordWrap
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Item {
                Layout.fillWidth: true
            }

            QQC2.Button {
                icon.name: "deletecell"
                text: i18n("Only Delete Current")
                visible: incidenceWrapper.recurrenceData.type > 0
                onClicked: addException(deleteDate, incidenceWrapper)
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
            }

            QQC2.Button {
                icon.name: "group-delete"
                text: i18n("Delete Only This")
                visible: deleteSheet.incidenceHasChildren && incidenceWrapper.recurrenceData.type === 0
                onClicked: deleteIncidence(incidenceWrapper.incidencePtr)
            }

            QQC2.Button {
                icon.name: "delete"
                text: deleteSheet.incidenceHasChildren || incidenceWrapper.recurrenceData.type > 0 ? i18n("Delete All") : i18n("Delete")
                onClicked: deleteSheet.incidenceHasChildren ? deleteIncidenceWithChildren(incidenceWrapper.incidencePtr) : deleteIncidence(incidenceWrapper.incidencePtr)
            }

            QQC2.Button {
                icon.name: "dialog-cancel"
                text: i18n("Cancel")
                onClicked: cancel()
            }
        }
    }
}
