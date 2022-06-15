// SPDX-FileCopyrightText: 2016 Michael Bohlender <michael.bohlender@kdemail.net>
// SPDX-FileCopyrightText: 2017 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4

Item {
    id: root
    property variant errorType
    property string errorString
    property string searchString
    property bool autoLoadImages: false
    height: partListView.height
    width: parent.width

    Column {
        id: partListView
        anchors {
            top: parent.top
            left: parent.left
        }
        width: parent.width
        spacing: 5
        Text {
            text: i18n("An error occurred: %1", errorString)
        }
    }
}
