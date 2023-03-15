// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2023 Vanshpreet S Kohli <vskohli1718@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0
import org.kde.kalendar.calendar 1.0 as Calendar
import org.kde.akonadi 1.0 as Akonadi

RowLayout {
    id: root

    // Property from model
    required property int index
    required property int startOffset
    required property int endOffset
    required property var time
    required property int type

    // Other required properties
    required property var remindersModel
    required property bool isTodo

    property bool customReminder: false
    property int selectedIndex: 0

    function setReminder(seconds: int) {
        if (root.isTodo) {
            root.remindersModel.setData(
                root.remindersModel.index(root.index, 0),
                seconds,
                RemindersModel.StartOffsetRole
            );
        } else {
            root.remindersModel.setData(
                root.remindersModel.index(root.index, 0),
                seconds,
                RemindersModel.EndOffsetRole
            );
        }
    }

    Layout.fillWidth: true

    QQC2.ComboBox {
        // There is also a chance here to add a feature for the user to pick
        // reminder type.

        Layout.fillWidth: true
        enabled: !root.customReminder
        visible: !root.customReminder

        displayText: if (root.startOffset === "Custom") {
            i18nc("Custom reminder", "Custom")
        } else {
            Calendar.Utils.secondsToReminderLabel(root.startOffset)
        }

        onCurrentValueChanged: if (currentValue === "Custom") {
            root.customReminder = true;
        } else {
            setReminder(currentValue);
        }
        onCountChanged: selectedIndex = currentIndex // Gets called *just* before modelChanged
        onModelChanged: currentIndex = selectedIndex

        // All these times are in seconds.
        model: [
            0, // We times by -1 to make times be before incidence
            -1 * 5 * 60, // 5 minutes
            -1 * 10 * 60,
            -1 * 15 * 60,
            -1 * 30 * 60,
            -1 * 45 * 60,
            -1 * 1 * 60 * 60, // 1 hour
            -1 * 2 * 60 * 60,
            -1 * 1 * 24 * 60 * 60, // 1 day
            -1 * 2 * 24 * 60 * 60,
            -1 * 5 * 24 * 60 * 60,
            "Custom" // Custom reminder
        ]

        delegate: Kirigami.BasicListItem {
            required property string modelData

            text: Calendar.Utils.secondsToReminderLabel(modelData)
        }

        popup.z: 1000
    }

    Kirigami.FormLayout {
        id: customReminderLayout

        visible: root.customReminder

        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.largeSpacing

        function valueInSeconds() {
            let val = 0
            switch (customReminderUnitCombobox.currentIndex) {
                case 0:
                    val = customReminderSpinbox.value * 60
                    break
                case 1:
                    val = customReminderSpinbox.value * 60 * 60
                    break
                case 2:
                    val = customReminderSpinbox.value * 60 * 60 * 24
                    break
            }
            switch (customReminderTypeBox.currentIndex) {
                case 0:
                    if (val > 0) val = val * -1
                    break
                case 1:
                    if (val < 0) val = val * -1
                    break
            }
            return val
        }

        function addCustomReminder() {
            if (!root.customReminder){
                return;
            }

            root.setReminder(valueInSeconds());
        }

        RowLayout {
            Layout.fillWidth: true

            QQC2.SpinBox {
                id: customReminderSpinbox
                Layout.fillWidth: true

                from: 1
                onValueChanged: customReminderLayout.addCustomReminder()
            }

            QQC2.ComboBox {
                id: customReminderUnitCombobox
                Layout.fillWidth: true

                currentIndex: 0
                model: [
                    i18n("minutes"),
                    i18n("hours"),
                    i18n("days")
                ]
                onCurrentValueChanged: customReminderLayout.addCustomReminder()

                popup.z: 1000
            }

            QQC2.ComboBox {
                id: customReminderTypeBox
                Layout.fillWidth: true

                model: [
                    i18n("before start of event"),
                    i18n("after start of event")
                ]
                onCurrentValueChanged: customReminderLayout.addCustomReminder()

                popup.z: 1000
            }
        }
    }

    QQC2.Button {
        text: i18n("Remove")
        display: QQC2.AbstractButton.IconOnly
        icon.name: "edit-delete-remove"
        onClicked: root.remindersModel.deleteAlarm(root.index);
    }
}
