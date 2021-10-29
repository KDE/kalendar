// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later
import QtQuick 2.15
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.10
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0
import QtQuick.Templates 2.15 as T

QQC2.Dialog {
    id: root
    bottomPadding: 0
    height: 400
    leftPadding: 0
    modal: true
    rightPadding: 0
    topPadding: 0
    width: 700
    y: 50

    onClosed: parent.active = false
    onOpened: searchField.forceActiveFocus()

    QQC2.ScrollView {
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
        anchors.fill: parent

        ListView {
            id: actionList
            model: KalendarApplication.actionsModel

            Keys.onPressed: if (event.text.length > 0) {
                searchField.forceActiveFocus();
                searchField.text += event.text;
            }

            delegate: Kirigami.BasicListItem {
                icon: model.decoration
                text: model.display

                onClicked: {
                    model.action.trigger();
                    root.close();
                }

                trailing: QQC2.Label {
                    color: Kirigami.Theme.disabledTextColor
                    text: model.shortcut
                }
            }
        }
    }

    header: T.Control {
        bottomPadding: verticalPadding + headerSeparator.implicitHeight // add space for bottom separator
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset, implicitContentHeight + topPadding + bottomPadding)
        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset, implicitContentWidth + leftPadding + rightPadding)
        padding: Kirigami.Units.largeSpacing

        // header background
        background: Kirigami.ShadowedRectangle {
            Kirigami.Theme.colorSet: Kirigami.Theme.Header
            Kirigami.Theme.inherit: false
            color: Kirigami.Theme.backgroundColor
            corners.topLeftRadius: Kirigami.Units.smallSpacing
            corners.topRightRadius: Kirigami.Units.smallSpacing

            Kirigami.Separator {
                id: headerSeparator
                anchors.bottom: parent.bottom
                width: parent.width
            }
        }
        contentItem: Kirigami.SearchField {
            id: searchField
            KeyNavigation.down: actionList

            onTextChanged: KalendarApplication.actionsModel.filterString = text
        }
    }
}
