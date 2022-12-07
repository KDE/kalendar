// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQml 2.15
import org.kde.kalendar.components 1.0
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kalendar 1.0

KalendarApp {
    menuBar: Qt.resolvedUrl('./private/MenuBar.qml')
    globalMenuBar: Qt.resolvedUrl('./private/GlobalMenuBar.qml')
    hamburgerActions: [
        Kirigami.Action {
            icon.name: "edit-undo"
            text: CalendarManager.undoRedoData.undoAvailable ?
                i18n("Undo: ") + CalendarManager.undoRedoData.nextUndoDescription : undoAction.text
            shortcut: undoAction.shortcut
            enabled: CalendarManager.undoRedoData.undoAvailable
            onTriggered: CalendarManager.undoAction();
        },
        Kirigami.Action {
            icon.name: KalendarApplication.iconName(redoAction.icon)
            text: CalendarManager.undoRedoData.redoAvailable ?
                i18n("Redo: ") + CalendarManager.undoRedoData.nextRedoDescription : redoAction.text
            shortcut: redoAction.shortcut
            enabled: CalendarManager.undoRedoData.redoAvailable
            onTriggered: CalendarManager.redoAction();
        },
        KActionFromAction {
            kalendarAction: "import_calendar"
        },
        KActionFromAction {
            text: i18n("Refresh All Calendars")
            kalendarAction: "refresh_all"
        }
    ]
}
