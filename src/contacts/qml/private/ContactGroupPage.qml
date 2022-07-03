// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kalendar 1.0
import org.kde.kalendar.contact 1.0

Kirigami.ScrollablePage {
    id: page
    property int itemId
    title: contactGroup.name
    property int mode: KalendarApplication.Contact

    leftPadding: 0
    rightPadding: 0
    topPadding: 0

    function openEditor() {
        pageStack.pushDialogLayer(Qt.resolvedUrl("ContactGroupEditorPage.qml"), {
            mode: ContactGroupEditor.EditMode,
            item: page.contactGroup.item
        })
    }

    property ContactGroupWrapper contactGroup: ContactGroupWrapper {
        id: contactGroup
        item: ContactManager.getItem(page.itemId)
    }

    actions {
        main: Kirigami.Action {
            iconName: "document-edit"
            text: i18n("Edit")
            onTriggered: openEditor()
        }
    }

    ListView {
        model: contactGroup.model
        delegate: Kirigami.BasicListItem {
            icon: model.iconName
            label: model.display
            subtitle: model.email
        }
    }
}