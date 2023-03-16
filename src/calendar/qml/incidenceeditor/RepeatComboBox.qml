// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.15 as Kirigami

QQC2.ComboBox {
    id: root

    required property bool isTodo

    Kirigami.FormData.label: i18n("Repeat:")
    Layout.fillWidth: true

    enabled: !incidenceForm.isTodo || !isNaN(root.incidenceWrapper.incidenceStart.getTime()) || !isNaN(root.incidenceWrapper.incidenceEnd.getTime())
    textRole: "display"
    valueRole: "interval"
    onCurrentIndexChanged: if(currentIndex === 0) { root.incidenceWrapper.clearRecurrences() }
    currentIndex: {
        switch(root.incidenceWrapper.recurrenceData.type) {
            case 0:
                return root.incidenceWrapper.recurrenceData.type;
            case 3: // Daily
                return root.incidenceWrapper.recurrenceData.frequency === 1 ?
                    root.incidenceWrapper.recurrenceData.type - 2 : 5
            case 4: // Weekly
                return root.incidenceWrapper.recurrenceData.frequency === 1 ?
                    (root.incidenceWrapper.recurrenceData.weekdays.filter(x => x === true).length === 0 ?
                    root.incidenceWrapper.recurrenceData.type - 2 : 5) : 5
            case 5: // Monthly on position (e.g. third Monday)
            case 8: // Yearly on day
            case 9: // Yearly on position
            case 10: // Other
                return 5;
            case 6: // Monthly on day (1st of month)
                return 3;
            case 7: // Yearly on month
                return 4;
        }
    }
    model: [
        {key: "never", display: i18n("Never"), interval: -1},
        {key: "daily", display: i18n("Daily"), interval: IncidenceWrapper.Daily},
        {key: "weekly", display: i18n("Weekly"), interval: IncidenceWrapper.Weekly},
        {key: "monthly", display: i18n("Monthly"), interval: IncidenceWrapper.Monthly},
        {key: "yearly", display: i18n("Yearly"), interval: IncidenceWrapper.Yearly},
        {key: "custom", display: i18n("Custom"), interval: -1}
    ]
    delegate: Kirigami.BasicListItem {
        text: modelData.display
        onClicked: if (modelData.interval >= 0) {
            root.incidenceWrapper.setRegularRecurrence(modelData.interval)
        } else {
            root.incidenceWrapper.clearRecurrences();
        }
    }
    popup.z: 1000
}
