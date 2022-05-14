// SPDX-FileCopyrightText: 2022 Carl Schwan <car@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.2
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kalendar.contact 1.0

Item {
    id: contactApplet

    Plasmoid.toolTipMainText: i18n("Contact")
    Plasmoid.icon: 'im-user'

    Plasmoid.switchWidth: PlasmaCore.Units.gridUnit * 5
    Plasmoid.switchHeight: PlasmaCore.Units.gridUnit * 5

    Plasmoid.fullRepresentation: PlasmaExtras.Representation {
        Layout.minimumWidth: PlasmaCore.Units.gridUnit * 5
        Layout.minimumHeight: PlasmaCore.Units.gridUnit * 5
        collapseMarginsHint: true

        focus: true

        header: stack.currentItem.header

        property string itemTitle: stack.currentItem.title
        onItemTitleChanged: contactApplet.Plasmoid.title = itemTitle ?? i18n("Contact")

        property alias listMargins: listItemSvg.margins

        PlasmaCore.FrameSvgItem {
            id : listItemSvg
            imagePath: "widgets/listitem"
            prefix: "normal"
            visible: false
        }

        Keys.forwardTo: [stack.currentItem]

        QQC2.StackView {
            id: stack
            anchors.fill: parent
            initialItem: ContactsPage {}
        }
    }
}
