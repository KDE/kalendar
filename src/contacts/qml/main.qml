// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kalendar.components 1.0
import org.kde.kalendar.contact 1.0 as Contact
import org.kde.akonadi 1.0 as Akonadi
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm

Kirigami.ApplicationWindow {
    id: root

    menuBar: Loader {
        active: !Kirigami.Settings.hasPlatformMenuBar && !Kirigami.Settings.isMobile && Contact.Config.showMenubar && applicationWindow().pageStack.currentItem

        visible: Contact.Config.showMenubar
        height: visible ? implicitHeight : 0
        sourceComponent: Contact.MenuBar {}
        onItemChanged: if (item) {
            item.Kirigami.Theme.colorSet = Kirigami.Theme.Header;
        }
    }

    pageStack {
        globalToolBar.style: Kirigami.ApplicationHeaderStyle.ToolBar
        initialPage: Contact.ContactView {}
    }

    globalDrawer: Contact.Sidebar {
        id: sidebar
    }

    Loader {
        id: globalMenuLoader
        active: !Kirigami.Settings.isMobile
        sourceComponent: Contact.GlobalMenuBar {}
    }

    Connections {
        target: Contact.ContactApplication

        function onOpenTagManager() {
            const openDialogWindow = pageStack.pushDialogLayer(tagManagerPage, {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 30
            });

            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
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

        function onOpenSettings() {
            const openDialogWindow = pageStack.pushDialogLayer("qrc:/qml/Settings.qml", {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 30
            });
        }

        function onRefreshAll() {
            Contact.ContactManager.updateAllCollections();
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
