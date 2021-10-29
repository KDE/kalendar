// SPDX-FileCopyrightText: 2021 Carson Black <uhhadd@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later
import Qt.labs.platform 1.1 as Labs
import QtQuick 2.15
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.10
import org.kde.kirigami 2.15 as Kirigami

Labs.Menu {
    id: editMenu
    required property Item field

    NativeMenuItemFromAction {
        kalendarAction: 'edit_undo'
    }
    NativeMenuItemFromAction {
        kalendarAction: 'edit_redo'
    }
    Labs.MenuSeparator {
    }
    Labs.MenuItem {
        enabled: editMenu.field !== null && editMenu.field.canUndo
        shortcut: StandardKey.Undo
        text: i18nc("text editing menu action", "Undo")

        onTriggered: {
            editMenu.field.undo();
            editMenu.close();
        }
    }
    Labs.MenuItem {
        enabled: editMenu.field !== null && editMenu.field.canRedo
        shortcut: StandardKey.Redo
        text: i18nc("text editing menu action", "Redo")

        onTriggered: {
            editMenu.field.undo();
            editMenu.close();
        }
    }
    Labs.MenuSeparator {
    }
    Labs.MenuItem {
        enabled: editMenu.field !== null && editMenu.field.selectedText
        shortcut: StandardKey.Cut
        text: i18nc("text editing menu action", "Cut")

        onTriggered: {
            editMenu.field.cut();
            editMenu.close();
        }
    }
    Labs.MenuItem {
        enabled: editMenu.field !== null && editMenu.field.selectedText
        shortcut: StandardKey.Copy
        text: i18nc("text editing menu action", "Copy")

        onTriggered: {
            editMenu.field.copy();
            editMenu.close();
        }
    }
    Labs.MenuItem {
        enabled: editMenu.field !== null && editMenu.field.canPaste
        shortcut: StandardKey.Paste
        text: i18nc("text editing menu action", "Paste")

        onTriggered: {
            editMenu.field.paste();
            editMenu.close();
        }
    }
    Labs.MenuItem {
        enabled: editMenu.field !== null && editMenu.field.selectedText !== ""
        shortcut: ""
        text: i18nc("text editing menu action", "Delete")

        onTriggered: {
            editMenu.field.remove(editMenu.field.selectionStart, editMenu.field.selectionEnd);
            editMenu.close();
        }
    }
    Labs.MenuSeparator {
    }
    Labs.MenuItem {
        enabled: editMenu.field !== null
        shortcut: StandardKey.SelectAll
        text: i18nc("text editing menu action", "Select All")

        onTriggered: {
            editMenu.field.selectAll();
            editMenu.close();
        }
    }
}
