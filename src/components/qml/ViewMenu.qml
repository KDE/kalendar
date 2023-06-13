// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kalendar.components 1.0

    KActionFromAction {
        kalendarAction: "open_contact_view"
    }
    KActionFromAction {
        kalendarAction: "open_mail_view"
    }
    KActionFromAction {
        kalendarAction: 'open_kcommand_bar'
    }
}
