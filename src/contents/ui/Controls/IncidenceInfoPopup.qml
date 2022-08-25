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

    signal tagClicked(string tagName)

    property var incidenceData
    property var activeTags : []

    property alias scrollView: incidenceInfoContents.scrollView

    contentWidth: availableWidth

    topPadding: 0
    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0

    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    contentItem: IncidenceInfoContents {
        id: incidenceInfoContents
        anchors.fill: parent
        incidenceData: root.incidenceData
        activeTags: root.activeTags
        onTagClicked: root.tagClicked(tagName)
    }
}
