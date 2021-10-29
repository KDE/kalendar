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
    property var filter: {
        "tags": [],
        "collectionId": -1
    }
    property var filterCollectionDetails: filter && filter.collectionId >= 0 ? Kalendar.CalendarManager.getCollectionDetails(filter.collectionId) : null
    property bool isDark: false
    property bool todoMode: false

    columnSpacing: 0
    columns: width > Kirigami.Units.gridUnit * 30 && filter.tags.length > 0 ? 3 : width > Kirigami.Units.gridUnit * 30 ? 2 : 1
    height: visible ? implicitHeight : 0
    rowSpacing: Kirigami.Units.smallSpacing
    rows: width > Kirigami.Units.gridUnit * 30 ? 1 : 2
    visible: todoMode || filter.tags.length > 0 || filter.collectionId > -1

    signal removeFilterTag(string tagName)
    signal searchTextChanged(string text)

    Kirigami.Heading {
        id: heading
        Layout.bottomMargin: headerLayout.rows > 1 ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing
        Layout.fillWidth: headerLayout.todoMode
        Layout.margins: Kirigami.Units.largeSpacing
        color: headerLayout.todoMode && headerLayout.filterCollectionDetails && headerLayout.filter.collectionId > -1 ? LabelUtils.getIncidenceLabelColor(headerLayout.filterCollectionDetails.color, headerLayout.isDark) : Kirigami.Theme.textColor
        elide: Text.ElideRight
        font.weight: !headerLayout.todoMode ? Font.Normal : Font.Bold
        level: headerLayout.todoMode ? 1 : 2
        text: !headerLayout.todoMode ? i18n("Filtering by tags") : headerLayout.filterCollectionDetails && headerLayout.filter.collectionId > -1 ? headerLayout.filterCollectionDetails.displayName : i18n("All Tasks")
        width: implicitWidth
    }
    Flow {
        id: tagFlow
        Layout.bottomMargin: headerLayout.rows > 1 ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing
        Layout.fillWidth: true
        Layout.margins: Kirigami.Units.largeSpacing
        clip: true
        layoutDirection: Qt.RightToLeft
        spacing: Kirigami.Units.smallSpacing
        visible: headerLayout.filter.tags.length > 0

        Repeater {
            id: tagRepeater
            model: headerLayout.filter ? headerLayout.filter.tags : {}

            Tag {
                id: filterTag
                actionText: i18n("Remove filtering tag")
                headingItem.color: headerLayout.todoMode && headerLayout.filterCollectionDetails ? LabelUtils.getIncidenceLabelColor(headerLayout.filterCollectionDetails.color, headerLayout.isDark) : Kirigami.Theme.textColor
                icon.name: "edit-delete-remove"
                implicitWidth: itemLayout.implicitWidth > tagFlow.width ? tagFlow.width : itemLayout.implicitWidth
                isHeading: true
                text: modelData

                onClicked: headerLayout.removeFilterTag(modelData)
            }
        }
    }
    Kirigami.SearchField {
        id: searchField
        Layout.bottomMargin: Kirigami.Units.largeSpacing - 1
        Layout.columnSpan: headerLayout.rows > 1 ? 2 : 1
        Layout.fillWidth: headerLayout.rows > 1
        Layout.margins: Kirigami.Units.largeSpacing
        text: headerLayout.filter.name ? headerLayout.filter.name : ""
        visible: headerLayout.todoMode

        onTextChanged: headerLayout.searchTextChanged(text)
    }
}
