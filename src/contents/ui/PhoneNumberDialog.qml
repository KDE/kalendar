// SPDX-FileCopyrightText: 2021 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.6
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.10 as Kirigami

Kirigami.OverlaySheet {

    id: root

    property alias numbers: list.model
    property alias title: heading.text

    signal numberSelected(string number)

    header: Kirigami.Heading {
        id: heading
    }

    ListView {
        id: list
        implicitWidth: Kirigami.Units.gridUnit * 20
        model: 4
        delegate: Kirigami.BasicListItem {
            text: modelData.typeLabel
            subtitle: modelData.number
            onClicked: {
                close()
                root.numberSelected(modelData.normalizedNumber)
            }
        }
    }
}
