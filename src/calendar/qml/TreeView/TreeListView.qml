/*
 *  SPDX-FileCopyrightText: 2020 Marco Martin <mart@kde.org>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.12

/**
 * A ListView with an internal KDescendantsProxyModel already in place.
 * It also features tree node open and close animations.
 *
 * In order to use it, just assign the actual tree model you need.
 * Additional properties:
 * * sourceModel: the tree model we want to show
 * * descendantsModel: The used KDescendantsProxyModel instance
 * * expandsByDefault: If true, the tree view will be loaded completely expanded (default false)
 */
InternalTreeListView {
    id: root
    property alias model: root.sourceModel
}

