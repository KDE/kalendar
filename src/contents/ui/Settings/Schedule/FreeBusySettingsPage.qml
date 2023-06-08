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
                    description: i18n("By publishing free/busy information, you allow others to take your calendar into account when inviting you for a meeting. Only the times you have already busy are published, not why they are busy.")
                }
                MobileForm.FormDelegateSeparator { above: autoPublishDelegate; below: freeBusyPublishInfo }
                MobileForm.FormCheckDelegate {
                    id: autoPublishDelegate
                    text: i18n("Publish your free/busy information automatically")
                    checked: Calendar.CalendarSettings.FreeBusyPublishAuto
                    onCheckedChanged: {
                        Calendar.CalendarSettings.FreeBusyPublishAuto = checked;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.AbstractFormDelegate {
                    id: autoPublishDelayDelegate
                    background: Item {}
                    // add left padding?
                    leftPadding: Kirigami.Units.largeSpacing * 4
                    Layout.fillWidth: true
                    visible: autoPublishDelegate.checked
                    contentItem: RowLayout {
                        QQC2.Label {
                            text: i18n("Minimum time (in minutes) between uploads: ")
                        }
                        QQC2.SpinBox {
                            Layout.fillWidth: false
                            value: Calendar.CalendarSettings.FreeBusyPublishDelay
                            onValueModified: {
                                Calendar.CalendarSettings.FreeBusyPublishDelay = value;
                                Calendar.CalendarSettings.save();
                            }
                            from: 1
                            to: 10080
                        }
                    }
                }
                MobileForm.AbstractFormDelegate {
                    id: publishDaysDelegate
                    background: Item {}
                    Layout.fillWidth: true
                    visible: autoPublishCheckbox.checked
                    contentItem: RowLayout {
                        QQC2.Label {
                            text: i18n("Number of days of free/busy info to publish: ")
                        }
                        QQC2.SpinBox {
                            Layout.fillWidth: false
                            value: Calendar.CalendarSettings.FreeBusyPublishDays
                            onValueModified: {
                                Calendar.CalendarSettings.FreeBusyPublishDays = value;
                                Calendar.CalendarSettings.save();
                            }
                            from: 1
                            to: 365
                        }
                    }
                }
                MobileForm.FormDelegateSeparator { above: publishServerTitle; below: publishdaysDelegate }
                MobileForm.FormTextDelegate {
                    id: publishServerTitle
                    description: i18n("Server information (not required if using Kolab server version 2)")
                }
                MobileForm.FormTextFieldDelegate {
                    id: publishServerUrl
                    label: i18n("Server URL")
                    text: Calendar.CalendarSettings.FreeBusyPublishUrl
                    onTextChanged: {
                        Calendar.CalendarSettings.FreeBusyPublishUrl = text;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator { above: publishServerUser; below: publishServerUrl }
                MobileForm.FormTextFieldDelegate {
                    id: publishServerUser
                    label: i18n("Username")
                    text: Calendar.CalendarSettings.FreeBusyPublishUser
                    onTextChanged: {
                        Calendar.CalendarSettings.FreeBusyPublishUser = text;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator { above: publishServerPassword; below: publishServerUser }
                MobileForm.FormTextFieldDelegate {
                    id: publishServerPassword
                    label: i18n("Password")
                    text: Calendar.CalendarSettings.FreeBusyPublishPassword
                    onTextChanged: {
                        Calendar.CalendarSettings.FreeBusyPublishPassword = text;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator { above: publishServerSavePassword; below: publishServerPassword }
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