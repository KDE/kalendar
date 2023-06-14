// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.12 as QQC2
import org.kde.kalendar.components 1.0
import org.kde.kalendar.contact 1.0

QQC2.MenuBar {
    FileMenu {}

    EditMenu {}

    QQC2.Menu {
        title: i18nc("@action:menu", "View")

        KActionFromAction {
            action: ContactApplication.action('open_kcommand_bar')
        }

        KActionFromAction {
            action: ContactApplication.action("refresh_all")
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Create")

        KActionFromAction {
            action: ContactApplication.action("create_contact")
        }
        KActionFromAction {
            action: ContactApplication.action("create_contact_group")
        }
    }

    WindowMenu {}

    QQC2.Menu {
        title: i18nc("@action:menu", "Settings")

        KActionFromAction {
            action: ContactApplication.action("open_tag_manager")
        }

        QQC2.MenuSeparator {
        }

        KActionFromAction {
            action: ContactApplication.action("options_configure_keybinding")
        }

        KActionFromAction {
            action: ContactApplication.action("options_configure")
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Help")

        KActionFromAction {
            action: ContactApplication.action("open_about_page")
        }

        KActionFromAction {
            action: ContactApplication.action("open_about_kde_page")
        }

        QQC2.MenuItem {
            text: i18nc("@action:menu", "Kalendar Handbook") // todo
            visible: false
        }
    }
}
