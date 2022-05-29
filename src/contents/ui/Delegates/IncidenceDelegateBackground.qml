// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar
import "labelutils.js" as LabelUtils

Kirigami.ShadowedRectangle {
    id: incidenceDelegateBackground

    property bool isOpenOccurrence: false
    property bool reactToCurrentMonth: false
    property bool isInCurrentMonth: true
    property bool isDark: false

    anchors.fill: parent
    color: isOpenOccurrence ? modelData.color :
        LabelUtils.getIncidenceDelegateBackgroundColor(modelData, root.isDark, Kalendar.Config.pastEventsTransparencyLevel)
    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
    opacity: isOpenOccurrence || isInCurrentMonth ? 1.0 : 0
    Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }

    radius: Kirigami.Units.smallSpacing

    shadow.size: Kirigami.Units.largeSpacing
    shadow.color: Qt.rgba(0.0, 0.0, 0.0, 0.2)
    shadow.yOffset: 2

    border.width: 1
    border.color: Kirigami.ColorUtils.tintWithAlpha(color, Kirigami.Theme.textColor, 0.2)
}
