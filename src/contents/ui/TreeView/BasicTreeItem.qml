/*
 *  SPDX-FileCopyrightText: 2020 Marco Martin <notmart@gmail.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.1
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.0 as QQC2
import org.kde.kirigami 2.14

/**
 * An item delegate for the TreeListView and TreeTableView components.
 *
 * It's intended to make all tree views look coherent.
 * It has a default icon and a label
 *
 * @since org.kde.kirigamiaddons.treeview 1.0
 */
AbstractTreeItem {
    id: listItem

    /**
     * This property holds the single text label the list item will contain.
     *
     * @since org.kde.kirigamiaddons.treeview 1.0
     */
    property alias label: listItem.text

    /**
     * This property holds a subtitle that goes below the main label.
     * Optional; if not defined, the list item will only have a main label.
     *
     * @since org.kde.kirigamiaddons.treeview 1.0
     */
    property alias subtitle: subtitleItem.text

    /**
     * This property controls whether the text (in both primary text and subtitle)
     * should be rendered as bold.
     *
     * @since org.kde.kirigamiaddons.treeview 1.0
     */
    property bool bold: false

    /**
     * This property holds the preferred size for the icon.
     *
     * @since org.kde.kirigamiaddons.treeview 1.0
     */
    property alias iconSize: iconItem.size

    /**
     * This property holds the color the icon should be colorized to.
     * If the icon shouldn't be colorized in any way, set it to "transparent"
     *
     * By default it will be the text color.
     *
     * @since org.kde.kirigamiaddons.treeview 1.0
     */
    property alias iconColor: iconItem.color

    /**
     * @brief This property holds whether when there is no icon the space will
     * still be reserved for it.
     *
     * It's useful in layouts where only some entries have an icon, having the
     * text all horizontally aligned.
     */
    property alias reserveSpaceForIcon: iconItem.visible

    /**
     * @brief This property holds whether the label will try to be as wide as
     * possible.
     *
     * It's useful in layouts containing entries without text. By default, true.
     */
    property alias reserveSpaceForLabel: labelItem.visible

    default property alias _basicDefault: layout.data

    contentItem: RowLayout {
        id: layout
        spacing: LayoutMirroring.enabled ? listItem.rightPadding : listItem.leftPadding
        Icon {
            id: iconItem
            source: {
                if (!listItem.icon) {
                    return undefined
                }
                if (listItem.icon.hasOwnProperty) {
                    if (listItem.icon.hasOwnProperty("name") && listItem.icon.name !== "")
                        return listItem.icon.name;
                    if (listItem.icon.hasOwnProperty("source"))
                        return listItem.icon.source;
                }
                return listItem.icon;
            }
            property int size: Units.iconSizes.smallMedium
            Layout.minimumHeight: size
            Layout.maximumHeight: size
            Layout.minimumWidth: size
            selected: (listItem.highlighted || listItem.checked || (listItem.pressed && listItem.supportsMouseEvents))
            opacity: 1
            visible: source != undefined
        }
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            QQC2.Label {
                id: labelItem
                text: listItem.text
                Layout.fillWidth: true
                color: (listItem.highlighted || listItem.checked || (listItem.pressed && listItem.supportsMouseEvents)) ? listItem.activeTextColor : listItem.textColor
                elide: Text.ElideRight
                font.weight: listItem.bold ? Font.Bold : Font.Normal
                opacity: 1
            }
            QQC2.Label {
                id: subtitleItem
                Layout.fillWidth: true
                color: (listItem.highlighted || listItem.checked || (listItem.pressed && listItem.supportsMouseEvents)) ? listItem.activeTextColor : listItem.textColor
                elide: Text.ElideRight
                font: Theme.smallFont
                opacity: listItem.bold ? 0.9 : 0.7
                visible: text.length > 0
            }
        }
    }
}
