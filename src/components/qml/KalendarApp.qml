// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQml 2.15
import QtQuick.Controls 2.15 as QQC2

QtObject {
    required property url menuBar
    required property url globalMenuBar
    property list<QQC2.Action> hamburgerActions
}