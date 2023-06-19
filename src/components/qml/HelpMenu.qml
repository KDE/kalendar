// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kalendar.components 1.0

QQC2.Menu {
    id: root

    required property var application

    title: i18nc("@action:menu", "Help")

    KActionFromAction {
        action: root.application.action("open_about_page")
    }

    KActionFromAction {
        action: root.application.action("open_about_kde_page")
    }

    QQC2.MenuItem {
        text: i18nc("@action:menu", "Kalendar Handbook") // todo
        visible: false
    }
}
