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
Kirigami.AbstractListItem {
    id: delegate
    separatorVisible: false

    onDoubleClicked: {
        if (kDescendantExpandable) {
            decoration.model.toggleChildren(index);
        }
    }

    // FIXME: it should probably use leftInset property but Kirigami.AbstractListItem doesn't have it because can't import QQC2 more than 2.0
    background.anchors {
        left: delegate.left
        leftMargin: decoration.width + delegate.padding * 2
    }

    data: [
        TreeViewDecoration {
            id: decoration
            model: delegate.ListView.view ? delegate.ListView.view.descendantsModel : (delegate.TableView.view ? delegate.TableView.view.descendantsModel : null)
            parent: delegate
            parentDelegate: delegate

            anchors {
                bottom: parent.bottom
                left: parent.left
                leftMargin: delegate.padding
                top: parent.top
            }
        },
        Binding {
            property: "left"
            target: contentItem.anchors
            value: delegate.left
        },
        Binding {
            property: "leftMargin"
            target: contentItem.anchors
            value: decoration.width + delegate.padding * 2 + Kirigami.Units.smallSpacing
        }
    ]
}
