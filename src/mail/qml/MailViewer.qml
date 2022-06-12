// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import org.kde.kalendar 1.0
import org.kde.kalendar.mail 1.0
import org.kde.kitemmodels 1.0 as KItemModels
import './mailpartview'

QQC2.Page {
    id: root
    property var item
    property string subject
    property string from
    property string sender
    property string to
    property date dateTime

    Layout.fillWidth: true
    header: QQC2.ToolBar {
        topInset: 1
        leftInset: 1
        rightInset: 1
        bottomInset: 1
        leftPadding: Kirigami.Units.largeSpacing
        rightPadding: Kirigami.Units.largeSpacing
        topPadding: Kirigami.Units.largeSpacing
        bottomPadding: Kirigami.Units.largeSpacing
        background: Item {
            implicitHeight: 40
            Kirigami.Separator {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: undefined
                    bottom:  parent.bottom
                }
            }
        }
        contentItem: GridLayout {
            columns: 3
            QQC2.Label {
                text: i18n('From:')
                Layout.rightMargin: Kirigami.Units.largeSpacing
            }

            QQC2.Label {
                text: root.from
            }

            QQC2.Label {
                text: root.dateTime.toLocaleString()
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
            }

            QQC2.Label {
                text: i18n('To:')
                Layout.rightMargin: Kirigami.Units.largeSpacing
            }

            QQC2.Label {
                text: root.to
            }
        }
    }
    contentItem: MailPartView {
        item: root.item
    }
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
        property color borderColor: Kirigami.Theme.textColor
        border.color: Qt.rgba(borderColor.r, borderColor.g, borderColor.b, 0.3)
        radius: 4
    }
}
