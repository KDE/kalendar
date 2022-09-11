// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.12 as QQC2
import org.kde.kalendar.components 1.0

QQC2.MenuBar {
    FileMenu {}

    EditMenu {}

    ViewMenu {
        QQC2.MenuSeparator {
        }

        KActionFromAction {
            text: i18n('Refresh All Address Books')
            kalendarAction: "refresh_all"
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Create")

        KActionFromAction {
            kalendarAction: "create_contact"
        }
    }

    WindowMenu {}

    SettingsMenu {}

    HelpMenu {}
}
