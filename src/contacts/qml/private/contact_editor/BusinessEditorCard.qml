// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1
import QtGraphicalEffects 1.0

import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm
import org.kde.kalendar.contact 1.0
import org.kde.akonadi 1.0 as Akonadi

MobileForm.FormCard {
    id: root

    required property ContactEditor contactEditor

    Layout.fillWidth: true
    Layout.topMargin: Kirigami.Units.largeSpacing

    contentItem: ColumnLayout {
        spacing: 0

        MobileForm.FormCardHeader {
            title: i18n("Business Information")
        }

        MobileForm.FormTextFieldDelegate {
            id: organizationId
            label: i18n("Organization")
            text: root.contactEditor.contact.organization
            onTextEdited: root.contactEditor.contact.organization = text
            placeholderText: i18nc("Placeholder value for name of Organization", "KDE")
        }

        MobileForm.FormDelegateSeparator {}

        MobileForm.FormTextFieldDelegate {
            id: professionId
            label: i18n("Profession")
            text: root.contactEditor.contact.profession
            onTextEdited: root.contactEditor.contact.profession = text
            placeholderText: i18nc("Placeholder value for name of Profession", "Software Developer")
        }

        MobileForm.FormDelegateSeparator {}

        MobileForm.FormTextFieldDelegate {
            id: titleId
            label: i18n("Title")
            text: root.contactEditor.contact.title
            onTextEdited: root.contactEditor.contact.title = text
            placeholderText: i18nc("Placeholder value for Title", "SDE-1")
        }

        MobileForm.FormDelegateSeparator {}

        MobileForm.FormTextFieldDelegate {
            id: deptId
            label: i18n("Department")
            text: root.contactEditor.contact.department
            onTextEdited: root.contactEditor.contact.department = text
            placeholderText: i18nc("Placeholder value for name of Department", "Kalendar-Team")
        }

        MobileForm.FormDelegateSeparator {}

        MobileForm.FormTextFieldDelegate {
            id: officeId
            label: i18n("Office")
            text: root.contactEditor.contact.office
            onTextEdited: root.contactEditor.contact.office = text
            placeholderText: i18nc("Placeholder value for Office", "Tech Wing, 4th Floor")
        }

        MobileForm.FormDelegateSeparator {}

        MobileForm.FormTextFieldDelegate {
            id: managersNameId
            label: i18n("Manager's Name")
            text: root.contactEditor.contact.managersName
            onTextEdited: root.contactEditor.contact.managersName = text
            placeholderText: i18nc("Placeholder value for Manager's Name", "Bob")
        }

        MobileForm.FormDelegateSeparator {}

        MobileForm.FormTextFieldDelegate {
            id: assistantsNameId
            label: i18n("Assistant's Name")
            text: root.contactEditor.contact.assistantsName
            onTextEdited: root.contactEditor.contact.assistantsName = text
            placeholderText: i18nc("Placeholder value for Assistants's Name", "Jill")
        }
    }
}
