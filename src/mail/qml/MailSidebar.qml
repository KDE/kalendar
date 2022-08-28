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

    contentItem: ListView {
        id: mailList

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

                    icon: model.decoration
                    leadingPadding: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                    trailing: Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                        source: model.kDescendantExpanded ? 'arrow-up' : 'arrow-down'
                    }

                    onClicked: mailList.model.toggleChildren(index)
                }
            }

            DelegateChoice {
                roleValue: false
                QQC2.ItemDelegate {
                    id: controlRoot
                    text: model.display
                    width: ListView.view.width
                    padding: Kirigami.Units.largeSpacing
                    leftPadding: (Kirigami.Settings.isMobile ? 3 : 2) * Kirigami.Units.largeSpacing * model.kDescendantLevel
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        Kirigami.Icon {
                            Layout.alignment: Qt.AlignVCenter
                            source: model.decoration
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            Layout.preferredWidth: Layout.preferredHeight
                        }
                        QQC2.Label {
                            leftPadding: controlRoot.mirrored ? (controlRoot.indicator ? controlRoot.indicator.width : 0) + controlRoot.spacing : 0
                            rightPadding: !controlRoot.mirrored ? (controlRoot.indicator ? controlRoot.indicator.width : 0) + controlRoot.spacing : 0

                            text: controlRoot.text
                            font: controlRoot.font
                            color: Kirigami.Theme.textColor
                            elide: Text.ElideRight
                            visible: controlRoot.text
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            Layout.alignment: Qt.AlignLeft
                            Layout.fillWidth: true
                        }
                    }

                    onClicked: {
                        model.checkState = model.checkState === 0 ? 2 : 0
                        MailManager.loadMailCollectionByIndex(foldersModel.mapToSource(foldersModel.index(model.index, 0)));
                    }
                }
            }
        }
    }
}
