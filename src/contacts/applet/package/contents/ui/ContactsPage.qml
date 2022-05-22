// SPDX-FileCopyrightText: 2022 Carl Schwan <car@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kalendar.contact 1.0
import org.kde.kitemmodels 1.0

PlasmaComponents3.ScrollView {
    id: scrollView
    anchors.fill: parent
    property string title: i18n("Contacts")

    property var header: PlasmaExtras.PlasmoidHeading {
        focus: true
        RowLayout {
            width: parent.width
            PlasmaExtras.SearchField {
                id: searchField
                Layout.fillWidth: true
                onTextChanged: contactsList.model.setFilterFixedString(text)
            }
        }
    }

    Keys.onPressed: {
        function goToCurrent() {
            contactsList.positionViewAtIndex(contactsList.currentIndex, ListView.Contain);
            if (contactsList.currentIndex != -1) {
                contactsList.currentItem.forceActiveFocus();
            }
        }
        if (event.modifiers & Qt.ControlModifier && event.key == Qt.Key_F) {
            toolbar.searchField.forceActiveFocus();
            toolbar.searchField.selectAll();
            event.accepted = true;
        } else if (event.key == Qt.Key_Down) {
            contactsList.incrementCurrentIndex();
            goToCurrent()
            event.accepted = true;
        } else if (event.key == Qt.Key_Up) {
            if (contactsList.currentIndex == 0) {
                contactsList.currentIndex = -1;
                searchField.forceActiveFocus();
                searchField.selectAll();
            } else {
                contactsList.decrementCurrentIndex();
                goToCurrent();
            }
            event.accepted = true;
        }
    }


    // HACK: workaround for https://bugreports.qt.io/browse/QTBUG-83890
    PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

    contentWidth: availableWidth - contentItem.leftMargin - contentItem.rightMargin

    contentItem: ListView {
        id: contactsList
        model: KSortFilterProxyModel {
            filterCaseSensitivity: Qt.CaseInsensitive
            sourceModel: ContactsModel {}
        }
        boundsBehavior: Flickable.StopAtBounds
        topMargin: PlasmaCore.Units.smallSpacing * 2
        bottomMargin: PlasmaCore.Units.smallSpacing * 2
        leftMargin: PlasmaCore.Units.smallSpacing * 2
        rightMargin: PlasmaCore.Units.smallSpacing * 2
        spacing: PlasmaCore.Units.smallSpacing
        activeFocusOnTab: true

        section.property: "display"
        section.criteria: ViewSection.FirstCharacter
        section.delegate: PlasmaExtras.Heading {level: 4; text: section}
        highlight: PlasmaExtras.Highlight { }
        highlightMoveDuration: 0
        highlightResizeDuration: 0
        focus: true
        delegate: ContactListItem {
            width: contactsList.width - contactsList.leftMargin - contactsList.rightMargin
            height: PlasmaCore.Units.gridUnit * 2
            name: model && model.display
            avatarIcon: model && model.decoration
            onClicked: stack.push(Qt.resolvedUrl('./ContactPage.qml'), {
                itemId: model.itemId,
            })
            Binding {
                target: contactsList; when: hovered
                property: "currentIndex"; value: index
                restoreMode: Binding.RestoreBinding
            }
        }
    }
}
