// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15 
import org.kde.kalendar 1.0
import QtQml.Models 2.15
import "dateutils.js" as DateUtils

Kirigami.ApplicationWindow {
    id: root

    property date currentDate: new Date()
    property date selectedDate: currentDate

    title: i18n("Calendar")

    pageStack.initialPage: monthViewComponent

    EventEditor {
        id: eventEditor
        onAdded: CalendarManager.addEvent(collectionId, event.eventPtr)
    }

    globalDrawer: Kirigami.GlobalDrawer {
        isMenu: true
        actions: [
            Kirigami.Action {
                text: i18n("Settings")
                onTriggered: pageStack.layers.push("qrc:/SettingsPage.qml")
            }
        ]
    }

    Component {
        id: monthViewComponent

        MonthView {
            title: root.selectedDate.toLocaleDateString(Qt.locale(), "<b>MMMM</b> yyyy")
            currentDate: root.currentDate
            startDate: DateUtils.getFirstDayOfWeek(DateUtils.getFirstDayOfMonth(root.selectedDate))
            month: root.selectedDate.getMonth()
            actions.contextualActions: [
                Kirigami.Action {
                    text: i18n("Add event")
                    icon.name: "list-add"
                    onTriggered: eventEditor.open()
                }
            ]
        }
    }
}
