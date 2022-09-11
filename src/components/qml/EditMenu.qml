// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Window 2.15
import org.kde.kalendar.components 1.0

QQC2.Menu {
    id: editMenu
    property Window _window: applicationWindow()

    title: i18nc("@action:menu", "Edit")

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
        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canUndo
            text: i18nc("text editing menu action", "Undo Text")
            onTriggered: {
                editMenu.field.undo()
                editMenu.close()
            }
        },

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canRedo
            text: i18nc("text editing menu action", "Redo Text")
            onTriggered: {
                editMenu.field.undo()
                editMenu.close()
            }
        },

        QQC2.MenuSeparator {
        },

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText
            text: i18nc("text editing menu action", "Cut")
            onTriggered: {
                editMenu.field.cut()
                editMenu.close()
            }
        },

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText
            text: i18nc("text editing menu action", "Copy")
            onTriggered: {
                editMenu.field.copy()
                editMenu.close()
            }
        },

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canPaste
            text: i18nc("text editing menu action", "Paste")
            onTriggered: {
                editMenu.field.paste()
                editMenu.close()
            }
        },

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText !== ""
            text: i18nc("text editing menu action", "Delete")
            onTriggered: {
                editMenu.field.remove(editMenu.field.selectionStart, editMenu.field.selectionEnd)
                editMenu.close()
            }
        },

        QQC2.MenuSeparator {
        },

        QQC2.MenuItem {
            enabled: editMenu.field !== null
            text: i18nc("text editing menu action", "Select All")
            onTriggered: {
                editMenu.field.selectAll()
                editMenu.close()
            }
        }
    ]
}
