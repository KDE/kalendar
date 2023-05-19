// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQml 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kalendar.components 1.0

/**
 * @brief Base element for an application
 */
QtObject {
    id: root

    /**
     * This property holds the name of the application
     */
    required property string appName

    /**
     * The menubar displayed on top of the window if the menubar is enabled.
     */
    required property url menuBar

    /**
     * The global menubar displayed on top of the screen if the global menu
     * applet is available.
     */
    required property url globalMenuBar

    /**
     * The actions displayed in the hamburger menu if the hamburger menu is
     * enabled.
     */
    property list<QQC2.Action> hamburgerActions

    /**
     * This signal is triggered when the Navigation requested a specific view
     *
     * @args string viewName The name of the view
     * @args string args An object containing the various arguments for the view
     */
    signal switchView(viewName: string, args: var)

    /**
     * This signal is triggered when the Navigation requested the current view
     * but with different arguments
     *
     * @args string args An object containing the various arguments for the view
     */
    signal argsUpdated(args: var)

    property Connections _connNav: Connections {
        target: Navigation

        function onSwitchViewRequested(app, viewName, args) {
            if (app !== root.appName) {
                return;
            }

            root.switchView(viewName, args);
        }

        function onArgsUpdated(app, args) {
            if (app !== root.appName) {
                return;
            }

            root.argsUpdated(args);
        }
    }
}