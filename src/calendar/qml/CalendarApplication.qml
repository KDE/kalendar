// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQml 2.15
import org.kde.kalendar.components 1.0
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kalendar 1.0
import org.kde.kalendar.calendar 1.0 as Calendar
import "./private/import" as Import

KalendarApp {
    menuBar: Qt.resolvedUrl('./private/MenuBar.qml')
    globalMenuBar: Qt.resolvedUrl('./private/GlobalMenuBar.qml')
    hamburgerActions: [
        Kirigami.Action {
            icon.name: "edit-undo"
            text: Calendar.CalendarManager.undoRedoData.undoAvailable ?
                i18n("Undo: ") + Calendar.CalendarManager.undoRedoData.nextUndoDescription : undoAction.text
            shortcut: undoAction.shortcut
            enabled: Calendar.CalendarManager.undoRedoData.undoAvailable
            onTriggered: CalendarManager.undoAction();
        },
        Kirigami.Action {
            icon.name: KalendarApplication.iconName(redoAction.icon)
            text: Calendar.CalendarManager.undoRedoData.redoAvailable ?
                i18n("Redo: ") + Calendar.CalendarManager.undoRedoData.nextRedoDescription : redoAction.text
            shortcut: redoAction.shortcut
            enabled: Calendar.CalendarManager.undoRedoData.redoAvailable
            onTriggered: Calendar.CalendarManager.redoAction();
        },
        KActionFromAction {
            kalendarAction: "import_calendar"
        },
        KActionFromAction {
            text: i18n("Refresh All Calendars")
            kalendarAction: "refresh_all"
        }
    ]

    Import.ImportHandler {
        id: importHandler
        readonly property var action: KalendarApplication.action(kalendarAction)
    }
}
