// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.19 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
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
            id: freeBusyPublishSection
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
                    checked: Calendar.CalendarSettings.freeBusyPublishAuto
                    onCheckedChanged: {
                        Calendar.CalendarSettings.freeBusyPublishAuto = checked;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormSpinBoxDelegate {
                    id: autoPublishDelayDelegate
                    Layout.fillWidth: true
                    visible: autoPublishDelegate.checked
                    label: i18n("Minimum time (in minutes) between uploads")
                    value: Calendar.CalendarSettings.freeBusyPublishDelay
                    from: 1
                    to: 10080
                    onValueChanged: {
                        Calendar.CalendarSettings.freeBusyPublishDelay = value;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormSpinBoxDelegate {
                    id: publishDaysDelegate
                    Layout.fillWidth: true
                    label: i18n("Number of days of free/busy info to publish: ")
                    value: Calendar.CalendarSettings.freeBusyPublishDays
                    from: 1
                    to: 365
                    onValueChanged: {
                        Calendar.CalendarSettings.freeBusyPublishDays = value;
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
                    text: Calendar.CalendarSettings.freeBusyPublishUrl
                    onEditingFinished: {
                        Calendar.CalendarSettings.freeBusyPublishUrl = text;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormTextFieldDelegate {
                    id: publishServerUser
                    label: i18n("Username")
                    text: Calendar.CalendarSettings.freeBusyPublishUser
                    onEditingFinished: {
                        Calendar.CalendarSettings.freeBusyPublishUser = text;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormTextFieldDelegate {
                    id: publishServerPassword
                    label: i18n("Password")
                    text: Calendar.CalendarSettings.freeBusyPublishPassword
                    onEditingFinished: {
                        Calendar.CalendarSettings.freeBusyPublishPassword = text;
                        Calendar.CalendarSettings.save();
                    }
                    Component.onCompleted: {
                        console.log('Starting now\n')
                        for (let i in Calendar.CalendarSettings) {
                            console.log(i, Calendar.CalendarSettings[i])
                        }
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormCheckDelegate {
                    id: publishServerSavePassword
                    text: i18n("Save password")
                    checked: Calendar.CalendarSettings.freeBusyPublishSavePassword
                    onCheckedChanged: {
                        Calendar.CalendarSettings.freeBusyPublishSavePassword = checked;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormButtonDelegate {
                    id: freeBusyPublishButton
                    text: i18n("Click here to publish Free/Busy information manually")
                    onClicked: Calendar.FreeBusyManager.publishFreeBusy();
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.AbstractFormDelegate {
                    id: freeBusyMailDelegate
                    background: null
                    Layout.fillWidth: true
                    contentItem: RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label {
                            text: i18n("Email Free/Busy")
                        }
                        QQC2.TextField {
                            id: freeBusyMailAddress
                            Layout.fillWidth: true
                            placeholderText: i18n("Enter email of recipient...")
                        }
                        QQC2.Button {
                            text: i18n('Send')
                            onClicked: Calendar.FreeBusyManager.mailFreeBusy(freeBusyMailAddress.text);
                        }
                    }
                }
            }
        }
        MobileForm.FormCard{
            id: freeBusyRetrieveSection
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            contentItem: ColumnLayout {
                spacing: 0
                MobileForm.FormCardHeader {
                    id: freeBusyRetrieveHeader
                    title: i18n("Free/Busy Retrieval settings")
                }
                MobileForm.FormTextDelegate {
                    id: freeBusyRetrieveInfo
                    description: i18n("By retrieving Free/Busy information that others have published, you can take their calendar into account when inviting them to a meeting.")
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormCheckDelegate {
                    id: autoRetrieveDelegate
                    text: i18n("Retrieve others' free/busy information automatically")
                    checked: Calendar.CalendarSettings.freeBusyRetrieveAuto
                    onCheckedChanged: {
                        Calendar.CalendarSettings.freeBusyRetrieveAuto = checked;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormCheckDelegate {
                    id: fullDomainRetrievalDelegate
                    text: i18n("Use full email address for retrieval")
                    checked: Calendar.CalendarSettings.freeBusyFullDomainRetrieval
                    onCheckedChanged: {
                        Calendar.CalendarSettings.freeBusyFullDomainRetrieval = checked;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormTextDelegate {
                    id: retrieveServerTitle
                    description: i18n("Server information")
                }
                MobileForm.FormTextFieldDelegate {
                    id: retrieveServerUrl
                    label: i18n("Server URL")
                    text: Calendar.CalendarSettings.freeBusyRetrieveUrl
                    onEditingFinished: {
                        Calendar.CalendarSettings.freeBusyRetrieveUrl = text;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormTextFieldDelegate {
                    id: retrieveServerUser
                    label: i18n("Username")
                    text: Calendar.CalendarSettings.freeBusyRetrieveUser
                    onEditingFinished: {
                        Calendar.CalendarSettings.freeBusyRetrieveUser = text;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormTextFieldDelegate {
                    id: retrieveServerPassword
                    label: i18n("Password")
                    text: Calendar.CalendarSettings.freeBusyRetrievePassword
                    onEditingFinished: {
                        Calendar.CalendarSettings.freeBusyRetrievePassword = text;
                        Calendar.CalendarSettings.save();
                    }
                }
                MobileForm.FormDelegateSeparator {}
                MobileForm.FormCheckDelegate {
                    id: retrieveServerSavePassword
                    text: i18n("Save password")
                    checked: Calendar.CalendarSettings.freeBusyRetrieveSavePassword
                    onCheckedChanged: {
                        Calendar.CalendarSettings.freeBusyRetrieveSavePassword = checked;
                        Calendar.CalendarSettings.save();
                    }
                }
            }
        }
    }
}