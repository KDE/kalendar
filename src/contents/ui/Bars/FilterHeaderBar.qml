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

    property bool isDark: KalendarUiUtils.darkMode
    property var mode: Kalendar.KalendarApplication.Event
    property var filter: {
        "tags": [],
        "collectionId": -1
    }
    property var filterCollectionDetails: filter && filter.collectionId >= 0 ?
        Kalendar.CalendarManager.getCollectionDetails(filter.collectionId) : null

    visible: mode === Kalendar.KalendarApplication.Todo || filter.tags.length > 0 || filter.collectionId > -1
    height: visible ? implicitHeight : 0

    spacing: Kirigami.Units.smallSpacing

    Connections {
        target: Kalendar.CalendarManager
        function onCollectionColorsChanged() {
            // Trick into reevaluating filterCollectionDetails
            headerLayout.filterChanged();
        }
    }

    RowLayout {
        Layout.margins: Kirigami.Units.largeSpacing
        Kirigami.Heading {
            id: heading

            Layout.alignment: Qt.AlignVCenter
            width: implicitWidth

            text: headerLayout.mode !== Kalendar.KalendarApplication.Todo ? i18n("Filtering by tags") : headerLayout.filterCollectionDetails && headerLayout.filter.collectionId > -1 ?
                headerLayout.filterCollectionDetails.displayName : i18n("All Tasks")
            font.weight: headerLayout.mode !== Kalendar.KalendarApplication.Todo ? Font.Normal : Font.Bold
            color: headerLayout.mode === Kalendar.KalendarApplication.Todo && headerLayout.filterCollectionDetails && headerLayout.filter.collectionId > -1 ?
                headerLayout.filterCollectionDetails.color : Kirigami.Theme.textColor
            elide: Text.ElideRight
            level: headerLayout.mode === Kalendar.KalendarApplication.Todo ? 1 : 2
        }
        QQC2.ToolButton {
            Layout.alignment: Qt.AlignVCenter
            icon.name: "edit-reset"
            visible: headerLayout.mode === Kalendar.KalendarApplication.Todo && headerLayout.filter.collectionId > -1
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

        Repeater {
            id: tagRepeater
            model: headerLayout.filter ? headerLayout.filter.tags : {}

            Tag {
                id: filterTag

                text: modelData

                implicitWidth: itemLayout.implicitWidth > tagFlow.width ?
                    tagFlow.width : itemLayout.implicitWidth
                isHeading: true
                headingItem.color: headerLayout.mode === Kalendar.KalendarApplication.Todo && headerLayout.filterCollectionDetails ?
                    headerLayout.filterCollectionDetails.color : Kirigami.Theme.textColor

                onClicked: headerLayout.removeFilterTag(modelData)
                actionIcon.name: "edit-delete-remove"
                actionText: i18n("Remove filtering tag")
            }
        }
    }

    Kirigami.Heading {
        id: numTasksHeading

        Layout.fillWidth: true
        Layout.rightMargin: Kirigami.Units.largeSpacing
        horizontalAlignment: Text.AlignRight

        function updateTasksCount() {
            if (headerLayout.mode === Kalendar.KalendarApplication.Todo) {
                text = applicationWindow().pageStack.currentItem.incompleteView.model.rowCount();
            }
        }

        Connections {
            target: headerLayout.mode === Kalendar.KalendarApplication.Todo ? applicationWindow().pageStack.currentItem.incompleteView.model : null
            function onRowsInserted() {
                numTasksHeading.updateTasksCount();
            }

            function onRowsRemoved() {
                numTasksHeading.updateTasksCount();
            }
        }

        text: headerLayout.mode === Kalendar.KalendarApplication.Todo ? applicationWindow().pageStack.currentItem.incompleteView.model.rowCount() : ''
        font.weight: Font.Bold
        color: headerLayout.mode === Kalendar.KalendarApplication.Todo && headerLayout.filterCollectionDetails && headerLayout.filter.collectionId > -1 ?
            headerLayout.filterCollectionDetails.color : Kirigami.Theme.textColor
        elide: Text.ElideRight
        visible: headerLayout.mode === Kalendar.KalendarApplication.Todo
    }
}
