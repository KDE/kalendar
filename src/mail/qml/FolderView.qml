// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import org.kde.kalendar.mail 1.0
import org.kde.kitemmodels 1.0 as KItemModels

 Kirigami.ScrollablePage {
    id: folderView
    title: MailManager.selectedFolderName

    Component {
        id: contextMenu
        QQC2.Menu {
            property int row
            property var status

            QQC2.Menu {
                title: i18nc('@action:menu', 'Mark Message')
                QQC2.MenuItem {
                    text: i18n('Mark Message as Read')
                }
                QQC2.MenuItem {
                    text: i18n('Mark Message as Unread')
                }

                QQC2.MenuSeparator {}

                QQC2.MenuItem {
                    text: status.isImportant ? i18n("Don't Mark as Important") : i18n('Mark as Important')
                }
            }

            QQC2.MenuItem {
                icon.name: 'delete'
                text: i18n('Move to Trash')
            }

            QQC2.MenuItem {
                icon.name: 'edit-move'
                text: i18n('Move Message to...')
            }

            QQC2.MenuItem {
                icon.name: 'edit-copy'
                text: i18n('Copy Message to...')
            }

            QQC2.MenuItem {
                icon.name: 'edit-copy'
                text: i18n('Add Followup Reminder')
            }
        }
    }

    ListView {
        id: mails
        model: MailManager.folderModel
        section.delegate: Kirigami.ListSectionHeader {
            required property string section
            label: section
        }
        section.property: "date"
        delegate: Kirigami.BasicListItem {
            label: model.title
            subtitle: model.from
            labelItem.color: if (highlighted) {
                return Kirigami.Theme.highlightedTextColor;
            } else {
                return !model.status || model.status.isRead ? Kirigami.Theme.textColor : Kirigami.Theme.linkColor;
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: {
                    const menu = contextMenu.createObject(folderView, {
                        row: index,
                        status: MailManager.folderModel.copyMessageStatus(model.status),
                    });
                    menu.popup();
                }
            }


            trailing: RowLayout {
                QQC2.Label {
                    text: model.datetime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                    QQC2.ToolTip {
                        text:  model.datetime.toLocaleString()
                    }
                }
                QQC2.ToolButton {
                    icon.name: status.isImportant ? 'starred-symbolic' : 'non-starred-symbolic'
                    implicitHeight: Kirigami.Units.gridUnit
                    implicitWidth: Kirigami.Units.gridUnit
                    onClicked: {
                        const status = MailManager.folderModel.copyMessageStatus(model.status);
                        status.isImportant = !status.isImportant;
                        MailManager.folderModel.updateMessageStatus(index, status)
                    }
                }
            }

            onClicked: {
                applicationWindow().pageStack.push(Qt.resolvedUrl('ConversationViewer.qml'), {
                    item: model.item,
                    props: model,
                });

                if (!model.status.isRead) {
                    const status = MailManager.folderModel.copyMessageStatus(model.status);
                    status.isRead = true;
                    MailManager.folderModel.updateMessageStatus(index, status)
                }
            }
        }
    }
}

