// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtLocation 5.15
import "labelutils.js" as LabelUtils

import org.kde.kalendar 1.0

QQC2.Popup {
    id: root

    property var incidenceData
    property alias scrollView: incidenceInfoContents.scrollView

    contentWidth: availableWidth

    clip: false

    background: Kirigami.ShadowedRectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View

        color: Kirigami.Theme.backgroundColor
        radius: Kirigami.Units.largeSpacing

        shadow.size: Kirigami.Units.largeSpacing
        shadow.color: Qt.rgba(0.0, 0.0, 0.0, 0.2)
        shadow.yOffset: 2

        border.width: 1
        border.color: Kirigami.ColorUtils.tintWithAlpha(color, Kirigami.Theme.textColor, 0.2)
    }

    contentItem: IncidenceInfoContents {
        id: incidenceInfoContents
        anchors.fill: parent
        anchors.left: Kirigami.Units.largeSpacing
        anchors.right: Kirigami.Units.largeSpacing

        clip: true
        incidenceData: root.incidenceData
    }
}
