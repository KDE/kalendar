// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.0
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar.calendar 1.0 as Calendar
import org.kde.kalendar.calendar.private 1.0

Importer {
    id: root

    calendar: Calendar.CalendarManager.calendar
    importAction: Calendar.CalendarApplication.action("import_calendar")

    property var _connectionApplication: Connections {
        target: Calendar.CalendarApplication

        function onImportCalendar() {
            importFileDialog.open();
        }
    }

    onImportCalendarFromFile: (file) => {
        if (root.calendarImportInProgress) {
            // Save urls to import
            root.calendarFilesToImport.push(file);
            return;
        }

        root.currentFile = file;
        root.calendarImportInProgress = true;

        pageStack.pushDialogLayer(importChoicePageComponent, {
            width: root.width
        }, {
            width: Kirigami.Units.gridUnit * 30,
            height: Kirigami.Units.gridUnit * 8,
        });
    }

    onImportIntoExistingFinished: (success, total) => {
        if (success) {
            applicationWindow().showPassiveNotification(
                i18nc("%1 is a number", "%1 incidences were imported successfully.", total),
                "short"
            );
        } else {
            applicationWindow().showPassiveNotification(
                i18nc("%1 is the error message", "An error occurred importing incidences: %1", root.importErrorMessage),
                "long"
            );
        }
    }

    onImportIntoNewFinished: (success) => {
        if (success) {
            applicationWindow().showPassiveNotification(
                i18n("New calendar created from imported file successfully."),
                "short"
            );
        } else {
            applicationWindow().showPassiveNotification(
                i18nc("%1 is the error message", "An error occurred importing incidences: %1", root.importErrorMessage),
                "long"
            );
        }
    }

    property var importMergeCollectionPickerComponent: Component {
        CollectionPickerPage {
            onCollectionPicked: {
                root.importCalendarFromUrl(root.currentFile, true, collectionId);
                root.calendarImportInProgress = false;
                closeDialog();
            }
            onCancel: {
                root.calendarImportInProgress = false;
                closeDialog()
            }
        }
    }

    property FileDialog importFileDialog: FileDialog {
        title: i18n("Import a calendar")
        folder: shortcuts.home
        nameFilters: [i18n("Calendar files (*.ics *.vcs)")]

        onAccepted: {
            root.currentFile = fileUrl;
            const openDialogWindow = pageStack.pushDialogLayer(importChoicePageComponent, {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 8
            });
        }
    }

    property var importChoicePageComponent: Component {
        Kirigami.Page {
            id: importChoicePage

            title: i18n("Import Calendar")

            ColumnLayout {
                anchors.fill: parent

                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: i18n("Would you like to merge this calendar file's events and tasks into one of your existing calendars, or would prefer to create a new calendar from this file?\n ")
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    QQC2.Button {
                        Layout.fillWidth: true
                        icon.name: "document-import"
                        text: i18n("Merge with existing calendar")
                        onClicked: {
                            closeDialog();
                            pageStack.pushDialogLayer(importMergeCollectionPickerComponent, {
                                width: root.width
                            }, {
                                width: Kirigami.Units.gridUnit * 30,
                                height: Kirigami.Units.gridUnit * 30
                            });
                        }
                    }
                    QQC2.Button {
                        Layout.fillWidth: true
                        icon.name: "document-new"
                        text: i18n("Create new calendar")
                        onClicked: {
                            root.calendarImportInProgress = false;
                            root.importCalendarFromUrl(root.currentFile, false);
                            closeDialog();
                        }
                    }
                    QQC2.Button {
                        icon.name: "gtk-cancel"
                        text: i18n("Cancel")
                        onClicked: {
                            root.calendarImportInProgress = false;
                            closeDialog();
                        }
                    }
                }
            }
        }
    }
}
