/*
 *  SPDX-FileCopyrightText: 2020 Marco Martin <mart@kde.org>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.12
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.13 as Kirigami
import org.kde.kitemmodels 1.0 

/**
 * An item delegate for the TreeListView and TreeTableView components.
 *
 * It has the tree expander decoration but no content otherwise,
 * which has to be set as contentItem
 *
 */
QQC2.ItemDelegate {
    id: delegate

    /**
     * This property holds the tree decoration of the list item.
     */
    property alias decoration: decoration

    /**
     * This propery holds the color for the text in the item.
     * It is advised to leave the default value (Kirigami.Theme.textColor)
     *
     * @Note If custom text elements are inserted in an AbstractListItem,
     * their color property will have to be manually bound with this property
     *
     * @since org.kde.kirigamiaddons.treeview 1.0
     */
    property color textColor: Kirigami.Theme.textColor

    /**
     * This property holds the color for the background of the item.
     * It is advised to leave the default value ('transparent')
     *
     * @since org.kde.kirigamiaddons.treeview 1.0
     */
    property color backgroundColor: "transparent"

    /**
     * This property holds the background color to use if alternatingBackground is true.
     * It is advised to leave the default.
     *
     * @since org.kde.kirigamiaddons.treeview 1.0
     */
    property color alternateBackgroundColor: Kirigami.Theme.alternateBackgroundColor

    /**
     * This property holds the color for the text in the item when pressed or
     * selected. It is advised to leave the default value (Kirigami.Theme.highlightedTextColor).
     *
     * @note If custom text elements are inserted in an AbstractListItem,
     * their color property will have to be manually bound with this property.
     */
    property color activeTextColor: Kirigami.Theme.highlightedTextColor

    /**
     * This property holds the color for the background of the item when pressed or
     * selected. It is advised to leave the default value (Kirigami.Theme.highlightColor).
     */
    property color activeBackgroundColor: Kirigami.Theme.highlightColor

    Kirigami.Theme.textColor: textColor
    Kirigami.Theme.backgroundColor: backgroundColor
    Kirigami.Theme.alternateBackgroundColor: alternateBackgroundColor
    Kirigami.Theme.activeTextColor: activeTextColor
    Kirigami.Theme.activeBackgroundColor: activeBackgroundColor

    width: parent && parent.width > 0 ? parent.width : implicitWidth

    padding: Kirigami.Settings.tabletMode ? Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing
    Accessible.role: Accessible.ListItem
    hoverEnabled: true
    height: visible ? implicitHeight : 0
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
    implicitWidth: contentItem ? contentItem.implicitWidth + leftPadding + rightPadding : Kirigami.Units.gridUnit * 12
    Layout.fillWidth: true

    data: [
        TreeViewDecoration {
            id: decoration
            anchors {
                left: parent.left
                top:parent.top
                bottom: parent.bottom
                leftMargin: delegate.padding
            }
            parent: delegate
            parentDelegate: delegate
            model: delegate.ListView.view ? delegate.ListView.view.descendantsModel :
                   (delegate.TableView.view ? delegate.TableView.view.descendantsModel : null)
        }
    ]

    Keys.onLeftPressed: if (kDescendantExpandable && kDescendantExpanded) {
        decoration.model.collapseChildren(index);
    } else if (!kDescendantExpandable && kDescendantLevel > 0) {
        if (delegate.ListView.view) {
            const sourceIndex = decoration.model.mapToSource(decoration.model.index(index, 0));
            const newIndex = decoration.model.mapFromSource(sourceIndex.parent);
            delegate.ListView.view.currentIndex = newIndex.row;
        }
    }

    Keys.onRightPressed: if (kDescendantExpandable && delegate.ListView.view) {
        if (kDescendantExpanded) {
            ListView.view.incrementCurrentIndex();
        } else {
            decoration.model.expandChildren(index);
        }
    }

    activeFocusOnTab: ListView.view ? false : true

    text: action ? action.text : undefined
    checked: action ? action.checked : false
    checkable: action ? action.checkable : false

    onClicked: {
        if (ListView.view && typeof index !== "undefined") {
            ListView.view.currentIndex = index;
        }
        if (action) {
            action.trigger();
        }

        checked = Qt.binding(function() { return action.checked });
    }

    onDoubleClicked: if (kDescendantExpandable) {
        decoration.model.toggleChildren(index);
    }

    leftInset: Qt.application.layoutDirection !== Qt.RightToLeft ? decoration.width + listItem.padding * 2 : 0
    leftPadding: Qt.application.layoutDirection !== Qt.RightToLeft ? decoration.width + listItem.padding * 2 : 0

    rightPadding: Qt.application.layoutDirection === Qt.RightToLeft ? decoration.width + listItem.padding * 2 : 0
    rightInset: Qt.application.layoutDirection === Qt.RightToLeft ? decoration.width + listItem.padding * 2 : 0

    opacity: enabled ? 1 : 0.6

    onVisibleChanged: {
        if (visible) {
            height = Qt.binding(() => { return implicitHeight; })
        } else {
            if (ListView.view && ListView.view.visible) {
                height = 0;
            }
        }
    }

    QtObject {
        id: internal
        property Flickable view: listItem.ListView.view || (listItem.parent ? listItem.parent.ListView.view : null)
        property bool indicateActiveFocus: listItem.pressed || Kirigami.Settings.tabletMode || listItem.activeFocus || (view ? view.activeFocus : false)
    }

    highlighted: focus && ListView.isCurrentItem && ListView.view && ListView.view.keyNavigationEnabled
}
