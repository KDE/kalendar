// SPDX-FileCopyrightText: 2021 Carson Black <uhhadd@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import Qt.labs.platform 1.1 as Labs
import QtQuick 2.15
import QtQuick.Window 2.15
import org.kde.kalendar.components 1.0

Labs.Menu {
    id: editMenu
    title: i18nc("@action:menu", "Edit")

    property Window _window: applicationWindow()

    property Connections _textInputConnection: Connections {
        target: _window
        function onActiveFocusItemChanged() {
            if (_window.activeFocusItem instanceof TextEdit || _window.activeFocusItem instanceof TextInput) {
                editMenu.field = _window.activeFocusItem;
            }
        }
    }

    property Item field: null

    Component.onCompleted: {
        for (let i in additionalMenuItems) {
            editMenu.addItem(additionalMenuItems[i])
        }
        for (let i in _menuItems) {
            editMenu.addItem(_menuItems[i])
        }
    }

    default property list<QtObject> additionalMenuItems

    property list<QtObject> _menuItems: [
        Labs.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canUndo
            text: i18nc("text editing menu action", "Undo")
            shortcut: StandardKey.Undo
            onTriggered: {
                editMenu.field.undo()
                editMenu.close()
            }
        },

        Labs.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canRedo
            text: i18nc("text editing menu action", "Redo")
            shortcut: StandardKey.Redo
            onTriggered: {
                editMenu.field.undo()
                editMenu.close()
            }
        },

        Labs.MenuSeparator {
        },

        Labs.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText
            text: i18nc("text editing menu action", "Cut")
            shortcut: StandardKey.Cut
            onTriggered: {
                editMenu.field.cut()
                editMenu.close()
            }
        },

        Labs.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText
            text: i18nc("text editing menu action", "Copy")
            shortcut: StandardKey.Copy
            onTriggered: {
                editMenu.field.copy()
                editMenu.close()
            }
        },

        Labs.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canPaste
            text: i18nc("text editing menu action", "Paste")
            shortcut: StandardKey.Paste
            onTriggered: {
                editMenu.field.paste()
                editMenu.close()
            }
        },

        Labs.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText !== ""
            text: i18nc("text editing menu action", "Delete")
            shortcut: ""
            onTriggered: {
                editMenu.field.remove(editMenu.field.selectionStart, editMenu.field.selectionEnd)
                editMenu.close()
            }
        },

        Labs.MenuSeparator {
        },

        Labs.MenuItem {
            enabled: editMenu.field !== null
            text: i18nc("text editing menu action", "Select All")
            shortcut: StandardKey.SelectAll
            onTriggered: {
                editMenu.field.selectAll()
                editMenu.close()
            }
        }
    ]
}
