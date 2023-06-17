// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.20 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm
import org.kde.kalendar.components 1.0
import org.kde.akonadi 1.0 as Akonadi

Kirigami.ApplicationWindow {
    id: root

    required property var application

    property Item hoverLinkIndicator: QQC2.Control {
        parent: overlay.parent
        property alias text: linkText.text
        opacity: text.length > 0 ? 1 : 0

        z: 99999
        x: 0
        y: parent.height - implicitHeight
        contentItem: QQC2.Label {
            id: linkText
        }
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        background: Rectangle {
             color: Kirigami.Theme.backgroundColor
        }
    }

    width: Kirigami.Units.gridUnit * 65

    minimumWidth: Kirigami.Units.gridUnit * 15
    minimumHeight: Kirigami.Units.gridUnit * 20
    onClosing: root.application.saveWindowGeometry(root)

    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.ToolBar

    QQC2.Action {
        id: closeOverlayAction
        shortcut: "Escape"
        onTriggered: {
            if(pageStack.layers.depth > 1) {
                pageStack.layers.pop();
                return;
            }
            if(contextDrawer && contextDrawer.visible) {
                contextDrawer.close();
                return;
            }
        }
    }

    Connections {
        target: root.application

        function onOpenKCommandBarAction() {
            kcommandbarLoader.active = true;
        }

        function onOpenAboutPage() {
            const openDialogWindow = pageStack.pushDialogLayer(aboutPage, {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 30
            });
        }

        function onOpenAboutKDEPage() {
            const openDialogWindow = pageStack.pushDialogLayer(aboutKDEPage, {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 30
            });
        }

        function onOpenTagManager() {
            const openDialogWindow = pageStack.pushDialogLayer(tagManagerPage, {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 30
            });

            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }

    }

    Loader {
        id: kcommandbarLoader
        active: false
        sourceComponent: KQuickCommandBarPage {
            application: root.application
            onClosed: kcommandbarLoader.active = false
        }
        onActiveChanged: if (active) {
            item.open()
        }
    }

    // TODO Qt6 use module url import instead for faster startup
    Component {
        id: tagManagerPage
        Akonadi.TagManagerPage {}
    }

    Component {
        id: aboutPage
        MobileForm.AboutPage {
            aboutData: About
        }
    }

    Component {
        id: aboutKDEPage
        MobileForm.AboutKDE {}
    }
}