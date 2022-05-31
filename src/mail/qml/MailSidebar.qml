// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0
import org.kde.kalendar.mail 1.0

QQC2.ScrollView {
    id: folderListView
    implicitWidth: Kirigami.Units.gridUnit * 16
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.topMargin: Kirigami.Units.largeSpacing * 2
    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
    contentWidth: availableWidth
    clip: true

    ListView {
        id: calendarList

        model: KDescendantsProxyModel {
            id: foldersModel
            model: MailManager.foldersModel
        }
        onModelChanged: currentIndex = -1

        delegate: DelegateChooser {
            role: 'kDescendantExpandable'
            DelegateChoice {
                roleValue: true

                Kirigami.BasicListItem {
                    label: display
                    labelItem.color: Kirigami.Theme.disabledTextColor
                    labelItem.font.weight: Font.DemiBold
                    topPadding: 2 * Kirigami.Units.largeSpacing
                    leftPadding: (Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing) + Kirigami.Units.gridUnit * (model.kDescendantLevel - 1)
                    hoverEnabled: false
                    background: Item {}

                    separatorVisible: false

                    leading: Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                        color: Kirigami.Theme.disabledTextColor
                        isMask: true
                        source: model.decoration
                    }
                    leadingPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                    trailing: Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                        source: model.kDescendantExpanded ? 'arrow-up' : 'arrow-down'
                    }

                    onClicked: calendarList.model.toggleChildren(index)
                }
            }

            DelegateChoice {
                roleValue: false
                Kirigami.BasicListItem {
                    label: display
                    labelItem.color: Kirigami.Theme.textColor
                    leftPadding: Kirigami.Units.largeSpacing * 2 * (model.kDescendantLevel - 2)
                    separatorVisible: false
                    reserveSpaceForIcon: true

                    onClicked: {
                        model.checkState = model.checkState === 0 ? 2 : 0
                        MailManager.loadMailCollection(foldersModel.mapToSource(foldersModel.index(model.index, 0)));
                        //if (sidebar.mailListPage) {
                        //    sidebar.mailListPage.title = model.display
                        //    sidebar.mailListPage.forceActiveFocus();
                        //    applicationWindow().pageStack.currentIndex = 1;
                        //} else {
                        //    sidebar.mailListPage = root.pageStack.push(folderPageComponent, {
                        //        title: model.display
                        //    });
                        //}
                    }
                }
            }
        }
    }
}
