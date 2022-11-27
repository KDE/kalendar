// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2

import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm
import org.kde.akonadi 1.0

MobileForm.FormCard {
    id: root
    required property var mimetypes
    required property string title
    required property string addPageTitle

    readonly property AgentConfiguration _configuration: AgentConfiguration {
        mimetypes: root.mimetypes
    }

    contentItem: ColumnLayout {
        spacing: 0

        MobileForm.FormCardHeader {
            title: root.title
        }

        Repeater {
            model: root._configuration.runningAgents
            delegate: MobileForm.FormButtonDelegate {
                Loader {
                    id: dialogLoader
                    sourceComponent: Kirigami.PromptDialog {
                        id: dialog
                        title: i18n("Configure %1", model.display)
                        subtitle: i18n("Modify or delete this account agent.")
                        standardButtons: Kirigami.Dialog.NoButton

                        customFooterActions: [
                        Kirigami.Action {
                            text: i18n("Modify")
                            iconName: "edit-entry"
                            onTriggered: {
                                root._configuration.edit(model.index);
                                dialog.close();
                            }
                        },
                        Kirigami.Action {
                            text: i18n("Delete")
                            iconName: "delete"
                            onTriggered: {
                                root._configuration.remove(model.index);
                                dialog.close();
                            }
                        }
                        ]
                    }
                }

                leadingPadding: Kirigami.Units.largeSpacing
                leading: Kirigami.Icon {
                    source: model.decoration
                    implicitWidth: Kirigami.Units.iconSizes.medium
                    implicitHeight: Kirigami.Units.iconSizes.medium
                }
                
                text: model.display
                description: model.statusMessage

                onClicked: {
                    dialogLoader.active = true;
                    dialogLoader.item.open();
                }
            }
        }

        MobileForm.FormDelegateSeparator { below: addAccountDelegate }

        MobileForm.FormButtonDelegate {
            id: addAccountDelegate
            text: i18n("Add Account")
            icon.name: "list-add"
            onClicked: pageStack.pushDialogLayer(addAccountPage)
        }
    }

    Component {
        id: addAccountPage
        Kirigami.ScrollablePage {
            id: overlay
            title: root.addPageTitle

            footer: QQC2.DialogButtonBox {
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Window
                standardButtons: QQC2.DialogButtonBox.Close
                onRejected: closeDialog()

                background: Rectangle {
                    color: Kirigami.Theme.backgroundColor
                }
            }

            ListView {
                implicitWidth: Kirigami.Units.gridUnit * 20
                model: root._configuration.availableAgents
                delegate: Kirigami.BasicListItem {
                    label: model.display
                    icon: model.decoration
                    subtitle: model.description
                    subtitleItem.wrapMode: Text.Wrap
                    enabled: root._configuration.availableAgents.flags(root._configuration.availableAgents.index(index, 0)) & Qt.ItemIsEnabled
                    onClicked: {
                        root._configuration.createNew(index);
                        overlay.closeDialog();
                        overlay.destroy();
                    }
                }
            }
        }
    }
}
