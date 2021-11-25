
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

    property alias decoration: decoration

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
        },
        Binding {
            target: contentItem.anchors
            property: "left"
            value: delegate.left
        },
        Binding {
            target: contentItem.anchors
            property: "leftMargin"
            value: decoration.width + delegate.padding * 2 + Kirigami.Units.smallSpacing
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

    Keys.onRightPressed: if (kDescendantExpandable) {
        if (kDescendantExpanded && delegate.ListView.view) {
            ListView.view.incrementCurrentIndex();
        } else {
            decoration.model.expandChildren(index);
        }
    }

    onDoubleClicked: if (kDescendantExpandable) {
        decoration.model.toggleChildren(index);
    }

    // FIXME: it should probably use leftInset property but Kirigami.AbstractListItem doesn't have it because can't import QQC2 more than 2.0
    background.anchors {
        left: delegate.left
        leftMargin: decoration.width + delegate.padding * 2
    }
}
