// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.19 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kalendar 1.0
import org.kde.akonadi 1.0
import org.kde.kalendar.calendar 1.0 as Calendar
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm


Kirigami.ScrollablePage {
    id: freeBusySettingsPage
    title: i18n("Configure Free/Busy")
    leftPadding: 0
    rightPadding: 0

    ColumnLayout {
        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            contentItem: ColumnLayout {
                spacing: 0
                MobileForm.FormCardHeader {
                    id: freeBusyPublishHeader
                    title: i18n("Free/Busy Publishing settings")
                }
                MobileForm.FormTextDelegate {
                    id: freeBusyPublishInfo
                    description: i18n("When you publish your free/busy information, it enables others to consider your calendar availability when inviting you to a meeting. Only the times that are already marked as busy are disclosed, without revealing the specific reasons for your availability.")
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormCheckDelegate {
                    id: autoPublishDelegate
                    text: i18n("Publish your free/busy information automatically")
                    checked: Calendar.CalendarSettings.FreeBusyPublishAuto
                    onCheckedChanged: {
                        Calendar.CalendarSettings.FreeBusyPublishAuto = checked;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormSpinBoxDelegate {
                    id: autoPublishDelayDelegate
                    Layout.fillWidth: true
                    visible: autoPublishDelegate.checked
                    label: i18n("Minimum time (in minutes) between uploads")
                    value: Calendar.CalendarSettings.FreeBusyPublishDelay
                    from: 1
                    to: 10080
                    onValueChanged: {
                        Calendar.CalendarSettings.FreeBusyPublishDelay = value;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormSpinBoxDelegate {
                    id: publishDaysDelegate
                    Layout.fillWidth: true
                    label: i18n("Number of days of free/busy info to publish: ")
                    value: Calendar.CalendarSettings.FreeBusyPublishDays
                    from: 1
                    to: 365
                    onValueChanged: {
                        Calendar.CalendarSettings.FreeBusyPublishDays = value;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormTextDelegate {
                    id: publishServerTitle
                    description: i18n("Server information")
                }
                MobileForm.FormTextFieldDelegate {
                    id: publishServerUrl
                    label: i18n("Server URL")
                    text: Calendar.CalendarSettings.FreeBusyPublishUrl
                    onEditingFinished: {
                        Calendar.CalendarSettings.FreeBusyPublishUrl = text;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormTextFieldDelegate {
                    id: publishServerUser
                    label: i18n("Username")
                    text: Calendar.CalendarSettings.FreeBusyPublishUser
                    onEditingFinished: {
                        Calendar.CalendarSettings.FreeBusyPublishUser = text;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormTextFieldDelegate {
                    id: publishServerPassword
                    label: i18n("Password")
                    text: Calendar.CalendarSettings.FreeBusyPublishPassword
                    onEditingFinished: {
                        Calendar.CalendarSettings.FreeBusyPublishPassword = text;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormCheckDelegate {
                    id: publishServerSavePassword
                    text: i18n("Save password")
                    checked: Calendar.CalendarSettings.FreeBusyPublishSavePassword
                    onCheckedChanged: {
                        Calendar.CalendarSettings.FreeBusyPublishSavePassword = checked;
                        Calendar.CalendarSettings.save();
                    }
                }
            }
        }
    }
}