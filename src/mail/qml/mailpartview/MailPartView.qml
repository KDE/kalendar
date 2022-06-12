// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2016 Michael Bohlender <michael.bohlender@kdemail.net>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
import org.kde.kalendar 1.0
import org.kde.kalendar.mail 1.0
import org.kde.kitemmodels 1.0 as KItemModels

ListView {
    id: root

    implicitHeight: contentHeight
    property var item
    property alias rootIndex: visualModel.rootIndex
    property alias searchString: visualModel.searchString
    property alias autoLoadImages: visualModel.autoLoadImages
    property var attachmentModel: messageParser.attachments

    interactive: false
    spacing: Kirigami.Units.smallSpacing
    model: MailPartModel {
        id: visualModel
        model: messageParser.parts
    }
    MessageParser {
        id: messageParser
        item: root.item
    }
}
