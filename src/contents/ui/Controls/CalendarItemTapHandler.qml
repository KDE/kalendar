// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.0
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar 1.0 as Kalendar

TapHandler {
    id: calendarTapHandler

    signal deleteCalendar(int collectionId, var collectionDetails)

    property var collectionId
    property var collectionDetails

    acceptedButtons: Kirigami.Settings.isMobile ? Qt.LeftButton | Qt.RightButton : Qt.RightButton

    onTapped: if(!Kirigami.Settings.isMobile) {
        calendarActions.createObject(calendarTapHandler, {}).open();
    }

    onLongPressed: if(Kirigami.Settings.isMobile) {
        calendarActions.createObject(calendarTapHandler, {}).open();
    }

    property Loader colorDialogLoader: Loader {
        id: colorDialogLoader
        active: false
        sourceComponent: ColorDialog {
            id: colorDialog
            title: i18nc("@title:window", "Choose Calendar Color")
            color: calendarTapHandler.collectionDetails.color
            onAccepted: Kalendar.CalendarManager.setCollectionColor(calendarTapHandler.collectionId, color)
            onRejected: {
                close();
                colorDialogLoader.active = false;
            }
        }
    }

    property Component calendarActions: Component {
        CalendarItemMenu {
            parent: calendarTapHandler.parent
            collectionId: calendarTapHandler.collectionId
            collectionDetails: calendarTapHandler.collectionDetails

            Component.onCompleted: if(calendarTapHandler.collectionId && !calendarTapHandler.collectionDetails) {
                calendarTapHandler.collectionDetails = Kalendar.CalendarManager.getCollectionDetails(calendarTapHandler.collectionId)
            }
        }
    }
}
