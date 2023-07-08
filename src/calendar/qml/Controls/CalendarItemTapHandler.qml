// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kalendar.calendar 1.0 as Kalendar
import org.kde.akonadi 1.0 as Akonadi

TapHandler {
    id: calendarTapHandler

    signal deleteCalendar(int collectionId, var collectionDetails)

    property var collectionId
    property var collectionDetails
    property Akonadi.AgentConfiguration agentConfiguration

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
            agentConfiguration: calendarTapHandler.agentConfiguration

            onDeleteCalendar: calendarTapHandler.deleteCalendar(collectionId, collectionDetails)

            Component.onCompleted: if(calendarTapHandler.collectionId && !calendarTapHandler.collectionDetails) {
                calendarTapHandler.collectionDetails = Kalendar.CalendarManager.getCollectionDetails(calendarTapHandler.collectionId)
            }
        }
    }
}
