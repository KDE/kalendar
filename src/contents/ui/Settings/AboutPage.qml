// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm

MobileForm.AboutPage {
    objectName: "aboutPage"
    aboutData: AboutType.aboutData
}
