// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Dialogs 1.0
import org.kde.kalendar.calendar 1.0 as Calendar

FileDialog {
    id: root

    property string selectedUrl: ""
    property bool calendarImportInProgress: false
    required property Calendar.ICalImporter icalImporter

    title: i18n("Import a calendar")
    folder: shortcuts.home
    nameFilters: [i18n("Calendar files (*.ics *.vcs)")]

    onAccepted: {
        selectedUrl = fileUrl;
        const openDialogWindow = pageStack.pushDialogLayer(importChoicePageComponent, {
            width: root.width
        }, {
            width: Kirigami.Units.gridUnit * 30,
            height: Kirigami.Units.gridUnit * 8
        });

        openDialogWindow.Keys.escapePressed.connect(() => {
            openDialogWindow.closeDialog();
        });
    }

    Component {
        id: importChoicePageComponent

        Kirigami.Page {
            id: importChoicePage

            signal closed()

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
                            root.icalImporter.closeDialog();
                            const openDialogWindow = pageStack.pushDialogLayer(importMergeCollectionPickerComponent, {
                                width: root.width
                            }, {
                                width: Kirigami.Units.gridUnit * 30,
                                height: Kirigami.Units.gridUnit * 30
                            });

                            openDialogWindow.Keys.escapePressed.connect(() => {
                                openDialogWindow.closeDialog();
                            });
                        }
                    }

                    QQC2.Button {
                        Layout.fillWidth: true
                        icon.name: "document-new"
                        text: i18n("Create new calendar")
                        onClicked: {
                            root.calendarImportInProgress = false;
                            root.icalImporter.importCalendarFromUrl(root.selectedUrl, false);
                            root.icalImporter.closeDialog();
                        }
                    }

                    QQC2.Button {
                        icon.name: "gtk-cancel"
                        text: i18n("Cancel")
                        onClicked: {
                            root.calendarImportInProgress = false;
                            root.icalImporter.closeDialog();
                        }
                    }
                }
            }
        }
    }

    Component {
        id: importMergeCollectionPickerComponent

        CollectionPickerPage {
            onCollectionPicked: {
                root.icalImporter.importCalendarFromUrl(importFileDialog.selectedUrl, true, collectionId);
                root.calendarImportInProgress = false;
                root.icalImporter.closeDialog();
            }

            onCancel: {
                root.calendarImportInProgress = false;
                root.icalImporter.closeDialog()
            }
        }
    }
}
