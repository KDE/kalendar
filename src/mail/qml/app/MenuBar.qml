// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kalendar.components 1.0
import org.kde.kalendar.mail 1.0

QQC2.MenuBar {
    id: bar

    FileMenu {}

    EditMenu {}

    QQC2.Menu {
        title: i18nc("@action:menu", "View")

        KActionFromAction {
            action: MailApplication.action('open_kcommand_bar')
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Create")

        KActionFromAction {
            action: MailApplication.action("create_mail")
        }
    }

    WindowMenu {}

    SettingsMenu {
        application: MailApplication
    }

    HelpMenu {
        application: MailApplication
    }
}
