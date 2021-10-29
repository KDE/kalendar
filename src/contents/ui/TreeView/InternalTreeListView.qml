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

ListView {
    id: root
    property alias descendantsModel: descendantsModel
    property alias expandsByDefault: descendantsModel.expandsByDefault
    property QtObject sourceModel

    spacing: 0

    add: Transition {
        // NumberAnimation behaves better than animators here
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
            from: 0
            property: "opacity"
            to: 1
        }
    }
    addDisplaced: Transition {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
            property: "y"
        }
    }
    model: KDescendantsProxyModel {
        id: descendantsModel
        expandsByDefault: false
        model: root.sourceModel
    }
    remove: Transition {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
            from: 1
            property: "opacity"
            to: 0
        }
    }
    removeDisplaced: Transition {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
            property: "y"
        }
    }
}
