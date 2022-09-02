// SPDX-FileCopyrightText: 2016 Michael Bohlender <michael.bohlender@kdemail.net>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.7
import QtQuick.Controls 2.15 as QQC2

import org.kde.kalendar 1.0
import org.kde.kalendar.mail 1.0
import org.kde.kirigami 2.19 as Kirigami

Item {
    id: root

    property string content
    property bool embedded: true
    property string type
    property bool autoLoadImages: false

    property string searchString
    property int contentHeight: textEdit.height

    onSearchStringChanged: {
        //This is a workaround because otherwise the view will not take the ViewHighlighter changes into account.
        textEdit.text = root.content
    }

    QQC2.TextArea {
        id: textEdit
        objectName: "textView"
        background: Item {}
        readOnly: true
        textFormat: TextEdit.RichText
        padding: 0

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        text: content.substring(0, 100000).replace(/\u00A0/g,' ') //The TextEdit deals poorly with messages that are too large.
        color: embedded ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor
        onLinkActivated: Qt.openUrlExternally(link)

        //Kube.ViewHighlighter {
        //    textDocument: textEdit.textDocument
        //    searchString: root.searchString
        //}
    }
}
