// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.10
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar.calendar 1.0
import QtQuick.Templates 2.15 as T

QQC2.Dialog {
    id: root

    parent: applicationWindow().overlay
    modal: true

    width: Math.min(700, parent.width)
    height: 400

    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0
    topPadding: 0

    anchors.centerIn: applicationWindow().overlay

    onClosed: parent.active = false
    onOpened: {
        searchField.forceActiveFocus();
        searchField.text = CalendarApplication.actionsModel.filterString; // set the previous searched text on reopening
        searchField.selectAll(); // select entire text
    }

    header: T.Control {
        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                implicitContentHeight + topPadding + bottomPadding)
        
        padding: Kirigami.Units.largeSpacing
        bottomPadding: verticalPadding + headerSeparator.implicitHeight // add space for bottom separator

        contentItem: Kirigami.SearchField {
            id: searchField
            KeyNavigation.down: actionList
            onTextChanged: CalendarApplication.actionsModel.filterString = text
        }

        // header background
        background: Kirigami.ShadowedRectangle {
            corners.topLeftRadius: Kirigami.Units.smallSpacing
            corners.topRightRadius: Kirigami.Units.smallSpacing
            Kirigami.Theme.colorSet: Kirigami.Theme.Header
            Kirigami.Theme.inherit: false
            color: Kirigami.Theme.backgroundColor
            Kirigami.Separator {
                id: headerSeparator
                width: parent.width
                anchors.bottom: parent.bottom
            }
        }
    }

    QQC2.ScrollView {
        anchors.fill: parent
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
        ListView {
            id: actionList
            model: CalendarApplication.actionsModel
            Keys.onPressed: if (event.text.length > 0) {
                searchField.forceActiveFocus();
                searchField.text += event.text;
            }
            delegate: Kirigami.BasicListItem {
                icon: model.decoration
                text: model.display
                trailing: QQC2.Label {
                    text: model.shortcut
                    color: Kirigami.Theme.disabledTextColor
                }
                onClicked: {
                    model.action.trigger()
                    root.close()
                }
            }
            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                text: i18n("No results found")
                visible: actionList.count === 0
                width: parent.width - Kirigami.Units.gridUnit * 4
            }
        }
    }
}
