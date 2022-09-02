// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import Qt.labs.qmlmodels 1.0

import org.kde.kirigami 2.15 as Kirigami
import org.kde.kitemmodels 1.0
import org.kde.raven 1.0

Kirigami.ScrollablePage {
    id: root
    title: i18n("Mailboxes")
    
    MailBoxList {}
}
