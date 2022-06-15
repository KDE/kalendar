// SPDX-FileCopyrightText 2019 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtQml.Models 2.2
import org.kde.kalendar 1.0
import org.kde.kalendar.mail 1.0
import org.kde.kirigami 2.19 as Kirigami

ColumnLayout {
    id: root

    property string content
    property bool autoLoadImages: false

    property string searchString
    property int contentHeight: childrenRect.height

    spacing: Kirigami.Units.smallSpacing

    Kirigami.InlineMessage {
        id: signedButton
        Layout.fillWidth: true
        Layout.maximumWidth: parent.width
        visible: true
        text: i18n("This mail contains an invitation")
    }
}
