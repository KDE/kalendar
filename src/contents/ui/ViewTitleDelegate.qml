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

    QQC2.ToolButton {
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        QQC2.ToolTip.text: sidebar.collapsed ? i18n("Expand Sidebar") : i18n("Collapse Sidebar")
        QQC2.ToolTip.visible: hovered
        icon.name: sidebar.collapsed ? "sidebar-expand" : "sidebar-collapse"
        visible: !Kirigami.Settings.isMobile

        onClicked: {
            if (sidebar.collapsed && !wideScreen) {
                // Collapsed due to narrow window
                // We don't want to write to config as when narrow the button will only open the modal drawer
                sidebar.collapsed = !sidebar.collapsed;
            } else {
                Config.forceCollapsedSidebar = !Config.forceCollapsedSidebar;
                Config.save();
            }
        }
    }
    TitleDateButton {
        id: titleDataButton
    }
}
