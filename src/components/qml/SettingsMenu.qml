// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kalendar.components 1.0

QQC2.Menu {
    title: i18nc("@action:menu", "Settings")

    KActionFromAction {
        kalendarAction: "open_tag_manager"
    }

    QQC2.MenuSeparator {
    }

    KActionFromAction {
        kalendarAction: "toggle_menubar"
    }

    KActionFromAction {
        kalendarAction: 'options_configure_keybinding'
    }

    KActionFromAction {
        kalendarAction: "options_configure"
    }
}
