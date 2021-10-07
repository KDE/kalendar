// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar 1.0 as Kalendar
import "labelutils.js" as LabelUtils

GridLayout {
    id: headerLayout

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

    columnSpacing: 0
    rowSpacing: Kirigami.Units.smallSpacing

    columns: width > Kirigami.Units.gridUnit * 30 && filter.tags.length > 0 ? 3 :
        width > Kirigami.Units.gridUnit * 30 ? 2 : 1
    rows: width > Kirigami.Units.gridUnit * 30 ? 1 : 2

    Kirigami.Heading {
        id: heading

        width: implicitWidth
        Layout.fillWidth: headerLayout.todoMode
        Layout.margins: Kirigami.Units.largeSpacing
        Layout.bottomMargin: headerLayout.rows > 1 ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing

        text: !headerLayout.todoMode ? i18n("Filtering by tags") : headerLayout.filterCollectionDetails && headerLayout.filter.collectionId > -1 ?
            headerLayout.filterCollectionDetails.displayName : i18n("All Tasks")
        font.weight: !headerLayout.todoMode ? Font.Normal : Font.Bold
        color: headerLayout.todoMode && headerLayout.filterCollectionDetails && headerLayout.filter.collectionId > -1 ?
            LabelUtils.getIncidenceLabelColor(headerLayout.filterCollectionDetails.color, headerLayout.isDark) : Kirigami.Theme.textColor
        elide: Text.ElideRight
        level: headerLayout.todoMode ? 1 : 2
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

    Kirigami.SearchField {
        id: searchField
        Layout.fillWidth: headerLayout.rows > 1
        Layout.margins: Kirigami.Units.largeSpacing
        Layout.bottomMargin: Kirigami.Units.largeSpacing - 1
        Layout.columnSpan: headerLayout.rows > 1 ? 2 : 1
        text: headerLayout.filter.name
        onTextChanged: headerLayout.searchTextChanged(text);
        visible: headerLayout.todoMode
    }
}
