// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import "labelutils.js" as LabelUtils

Kirigami.ShadowedRectangle {
    id: incidenceBackground
    property bool isDark: false
    property bool isInCurrentMonth: true
    property bool isOpenOccurrence: false
    property bool reactToCurrentMonth: false

    anchors.fill: parent
    border.color: Kirigami.ColorUtils.tintWithAlpha(color, Kirigami.Theme.textColor, 0.2)
    border.width: 1
    color: isOpenOccurrence ? modelData.color : LabelUtils.getIncidenceBackgroundColor(modelData.color, root.isDark)
    radius: Kirigami.Units.smallSpacing
    shadow.color: Qt.rgba(0.0, 0.0, 0.0, 0.2)
    shadow.size: Kirigami.Units.largeSpacing
    shadow.yOffset: 2
    visible: isOpenOccurrence || isInCurrentMonth
}
