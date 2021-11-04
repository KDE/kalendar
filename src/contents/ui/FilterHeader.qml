// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar 1.0 as Kalendar
import "labelutils.js" as LabelUtils

RowLayout {
    id: headerLayout

    signal resetFilterCollection()
    signal removeFilterTag(string tagName)
    signal searchTextChanged(string text)

    property bool isDark: false
    property bool todoMode: false
    property var filter: {
        "tags": [],
        "collectionId": -1
    }
    property var filterCollectionDetails: filter && filter.collectionId >= 0 ?
        Kalendar.CalendarManager.getCollectionDetails(filter.collectionId) : null

    visible: todoMode || filter.tags.length > 0 || filter.collectionId > -1
    height: visible ? implicitHeight : 0

    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.margins: Kirigami.Units.largeSpacing
        Kirigami.Heading {
            id: heading

            Layout.alignment: Qt.AlignVCenter
            width: implicitWidth

            text: !headerLayout.todoMode ? i18n("Filtering by tags") : headerLayout.filterCollectionDetails && headerLayout.filter.collectionId > -1 ?
                headerLayout.filterCollectionDetails.displayName : i18n("All Tasks")
            font.weight: !headerLayout.todoMode ? Font.Normal : Font.Bold
            color: headerLayout.todoMode && headerLayout.filterCollectionDetails && headerLayout.filter.collectionId > -1 ?
                LabelUtils.getIncidenceLabelColor(headerLayout.filterCollectionDetails.color, headerLayout.isDark) : Kirigami.Theme.textColor
            elide: Text.ElideRight
            level: headerLayout.todoMode ? 1 : 2
        }
        QQC2.ToolButton {
            Layout.alignment: Qt.AlignVCenter
            icon.name: "edit-reset"
            visible: headerLayout.todoMode && headerLayout.filter.collectionId > -1
            onClicked: headerLayout.resetFilterCollection()
        }
    }

    Flow {
        id: tagFlow

        Layout.fillWidth: true
        Layout.margins: Kirigami.Units.largeSpacing
        Layout.bottomMargin: headerLayout.rows > 1 ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing

        spacing: Kirigami.Units.smallSpacing
        layoutDirection: Qt.RightToLeft
        clip: true
        visible: headerLayout.filter.tags.length > 0

        move: Transition {
            NumberAnimation {
                properties: "x, y"
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        Repeater {
            id: tagRepeater
            model: headerLayout.filter ? headerLayout.filter.tags : {}

            Tag {
                id: filterTag

                text: modelData

                implicitWidth: itemLayout.implicitWidth > tagFlow.width ?
                    tagFlow.width : itemLayout.implicitWidth
                isHeading: true
                headingItem.color: headerLayout.todoMode && headerLayout.filterCollectionDetails ?
                    LabelUtils.getIncidenceLabelColor(headerLayout.filterCollectionDetails.color, headerLayout.isDark) : Kirigami.Theme.textColor

                icon.name: "edit-delete-remove"
                onClicked: headerLayout.removeFilterTag(modelData)
                actionText: i18n("Remove filtering tag")
            }
        }
    }
}
