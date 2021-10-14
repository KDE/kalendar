/*
 *  SPDX-FileCopyrightText: 2020 Marco Martin <mart@kde.org>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.6
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.13 as Kirigami
import org.kde.kitemmodels 1.0
import org.kde.kirigamiaddons.treeview 1.0 as TreeView


ListView {
    id: root
    spacing: 0
    property QtObject sourceModel
    property alias descendantsModel: descendantsModel
    property alias expandsByDefault: descendantsModel.expandsByDefault

    add: Transition {
        // NumberAnimation behaves better than animators here
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
    }
    addDisplaced: Transition {
        NumberAnimation {
            property: "y"
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
    }
    remove: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
    }
    removeDisplaced: Transition {
        NumberAnimation {
            property: "y"
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
    }

    model: KDescendantsProxyModel {
        id: descendantsModel
        expandsByDefault: false
        model: root.sourceModel
    }
}

