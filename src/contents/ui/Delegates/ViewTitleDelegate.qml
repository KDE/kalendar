// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0

RowLayout {
    property alias titleDateButton: titleDataButton

    spacing: 0

    // REMINDER: The collapse button used in the tasks view has its own implementation!!
    // You can find it in its instantiating component in main.qml

    QQC2.ToolButton {
        visible: !Kirigami.Settings.isMobile
        icon.name: mainDrawer.collapsed ? "sidebar-expand" : "sidebar-collapse"
        onClicked: {
            if(mainDrawer.collapsed && !wideScreen) { // Collapsed due to narrow window
                // We don't want to write to config as when narrow the button will only open the modal drawer
                mainDrawer.collapsed = !mainDrawer.collapsed;
            } else {
                Config.forceCollapsedMainDrawer = !Config.forceCollapsedMainDrawer;
                Config.save()
            }
        }

        QQC2.ToolTip.text: mainDrawer.collapsed ? i18n("Expand Main Drawer") : i18n("Collapse Main Drawer")
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
    }
    TitleDateButton {
        id: titleDataButton
    }
}
