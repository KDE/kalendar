// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar.calendar 1.0 as Calendar
import org.kde.kalendar 1.0

Calendar.ICalImporter {
    id: root

    property alias calendarImportInProgress: importFileDialog.calendarImportInProgress
    property var action: KalendarApplication.action(kalendarAction)

    onImportStarted: action.enabled = false
    onImportFinished: action.enabled = true

    onImportIntoExistingFinished: (success, total) => {
        filterHeaderBar.active = true;
        pageStack.currentItem.header = filterHeaderBar.item;

        if(success) {
            filterHeaderBar.item.messageItem.type = Kirigami.MessageType.Positive;
            filterHeaderBar.item.messageItem.text = i18nc("%1 is a number", "%1 incidences were imported successfully.", total);
        } else {
            filterHeaderBar.item.messageItem.type = Kirigami.MessageType.Error;
            filterHeaderBar.item.messageItem.text = i18nc("%1 is the error message", "An error occurred importing incidences: %1", KalendarApplication.importErrorMessage);
        }

        filterHeaderBar.item.messageItem.visible = true;
    }

    onImportIntoNewFinished: (success) => {
        filterHeaderBar.active = true;
        pageStack.currentItem.header = filterHeaderBar.item;

        if(success) {
            filterHeaderBar.item.messageItem.type = Kirigami.MessageType.Positive;
            filterHeaderBar.item.messageItem.text = i18n("New calendar  created from imported file successfully.");
        } else {
            filterHeaderBar.item.messageItem.type = Kirigami.MessageType.Error;
            filterHeaderBar.item.messageItem.text = i18nc("%1 is the error message", "An error occurred importing incidences: %1", KalendarApplication.importErrorMessage);
        }

        filterHeaderBar.item.messageItem.visible = true;
    }

    Connections {
        target: KalendarApplication

        function onImportCalendar() {
            filterHeaderBar.active = true;
            importFileDialog.open();
        }

        function onImportCalendarFromFile(file) {

            if (root.calendarImportInProgress) {
                // Save urls to import
                root.calendarFilesToImport.push(file)
                return;
            }
            importFileDialog.selectedUrl = file // FIXME don't piggy-back on importFileDialog
            root.calendarImportInProgress = true;

            const openDialogWindow = pageStack.pushDialogLayer(importChoicePageComponent, {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 8
            });
            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }

    }

    ImportFileDialog {
        id: importFileDialog
        icalImporter: root
    }
}
