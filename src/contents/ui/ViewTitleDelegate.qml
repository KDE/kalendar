// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami

RowLayout {
    property alias titleDateButton: titleDataButton

    spacing: 0
    QQC2.ToolButton {
        visible: !Kirigami.Settings.isMobile
        icon.name: sidebar.collapsed ? "sidebar-expand" : "sidebar-collapse"
        onClicked: sidebar.collapsed = !sidebar.collapsed

        QQC2.ToolTip.text: sidebar.collapsed ? i18n("Expand Sidebar") : i18n("Collapse Sidebar")
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
    }
    TitleDateButton {
        id: titleDataButton
    }
}
