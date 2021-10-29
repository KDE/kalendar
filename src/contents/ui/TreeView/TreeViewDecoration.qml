/*
 *  SPDX-FileCopyrightText: 2020 Marco Martin <mart@kde.org>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */
import QtQuick 2.6
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Templates 2.2 as T2
import org.kde.kitemmodels 1.0
import org.kde.kirigami 2.14 as Kirigami

/**
 * The tree expander decorator for item views.
 *
 * It will have a "> v" expander button graphics, and will have indentation on the left
 * depending on the level of the tree the item is in
 */
RowLayout {

    /**
     * model: KDescendantsProxyModel
     * The KDescendantsProxyModel the view is showing.
     * It needs to be assigned explicitly by the developer.
     */
    property KDescendantsProxyModel model
    /**
     * parentDelegate: ItemDelegate
     * The delegate this decoration will live in.
     * It needs to be assigned explicitly by the developer.
     */
    property T2.ItemDelegate parentDelegate

    Layout.bottomMargin: -parentDelegate.bottomPadding
    Layout.topMargin: -parentDelegate.topPadding

    Repeater {
        model: kDescendantLevel - 1

        delegate: Item {
            Layout.fillHeight: true
            Layout.preferredWidth: controlRoot.width

            Rectangle {
                color: Kirigami.Theme.textColor
                opacity: 0.5
                visible: kDescendantHasSiblings[modelData]
                width: 1

                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                }
            }
        }
    }
    T2.Button {
        id: controlRoot
        Layout.fillHeight: true
        Layout.preferredWidth: Kirigami.Units.gridUnit
        enabled: kDescendantExpandable

        onClicked: model.toggleChildren(index)

        background: Item {
        }
        contentItem: Item {
            id: styleitem
            implicitWidth: Kirigami.Units.gridUnit

            Rectangle {
                color: Kirigami.Theme.textColor
                opacity: 0.5
                width: 1

                anchors {
                    bottom: expander.visible ? expander.top : parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                }
            }
            Kirigami.Icon {
                id: expander
                anchors.centerIn: parent
                height: width
                source: kDescendantExpanded ? "go-down-symbolic" : "go-next-symbolic"
                visible: kDescendantExpandable
                width: Kirigami.Units.iconSizes.small
            }
            Rectangle {
                color: Kirigami.Theme.textColor
                opacity: 0.5
                visible: kDescendantHasSiblings[kDescendantHasSiblings.length - 1]
                width: 1

                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    top: expander.visible ? expander.bottom : parent.verticalCenter
                }
            }
            Rectangle {
                color: Kirigami.Theme.textColor
                height: 1
                opacity: 0.5

                anchors {
                    left: expander.visible ? expander.right : parent.horizontalCenter
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
