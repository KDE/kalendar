// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.akonadi 1.0 as Akonadi
import org.kde.kirigami 2.15 as Kirigami

Kirigami.ScrollablePage {
    id: root

    title: i18n("Manage Tags")

    QQC2.Dialog {
        id: deleteConfirmSheet

        property string tagName
        property var tag

        title: i18n("Delete Tag")
        modal: true
        focus: true
        x: Math.round((parent.width - width) / 2)
        y: Math.round(parent.height / 3)
        width: Math.round(Math.min(parent.width - Kirigami.Units.gridUnit, Kirigami.Units.gridUnit * 30))


        contentItem: ColumnLayout {
            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Are you sure you want to delete tag \"%1\"?", deleteConfirmSheet.tagName)
                wrapMode: Text.Wrap
            }
        }

        footer: QQC2.DialogButtonBox {
            standardButtons: QQC2.DialogButtonBox.Ok | QQC2.DialogButtonBox.Cancel

            onAccepted: {
                Akonadi.TagManager.deleteTag(deleteConfirmSheet.tag);
                deleteConfirmSheet.close();
            }
            onRejected: deleteConfirmSheet.close()
        }
    }

    ListView {
        currentIndex: -1
        model: Akonadi.TagManager.tagModel

        delegate: QQC2.ItemDelegate {
            id: tagDelegate

            required property string name
            required property var tag

            property bool editMode: false

            width: ListView.view.width

            contentItem: Item {
                implicitWidth: delegateLayout.implicitWidth
                implicitHeight: delegateLayout.implicitHeight

                RowLayout {
                    id: delegateLayout

                    anchors {
                        left: parent.left
                        top: parent.top
                        right: parent.right
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: tagDelegate.name
                        visible: !tagDelegate.editMode
                        wrapMode: Text.Wrap
                    }

                    QQC2.ToolButton {
                        icon.name: "edit-rename"
                        onClicked: tagDelegate.editMode = true
                        visible: !tagDelegate.editMode
                    }

                    QQC2.ToolButton {
                        icon.name: "delete"
                        onClicked: {
                            deleteConfirmSheet.tag = tagDelegate.tag;
                            deleteConfirmSheet.tagName = tagDelegate.name;
                            deleteConfirmSheet.open();
                        }
                        visible: !tagDelegate.editMode
                    }

                    QQC2.TextField {
                        id: tagNameField
                        Layout.fillWidth: true
                        text: tagDelegate.name
                        visible: tagDelegate.editMode
                        wrapMode: Text.Wrap
                    }

                    QQC2.ToolButton {
                        icon.name: "gtk-apply"
                        visible: tagDelegate.editMode
                        onClicked: {
                            Akonadi.TagManager.renameTag(tagDelegate.tag, tagNameField.text)
                            tagDelegate.editMode = false;
                        }
                    }

                    QQC2.ToolButton {
                        icon.name: "gtk-cancel"
                        onClicked: {
                            tagDelegate.editMode = false;
                            tagNameField.text = tagDelegate.name
                        }
                        visible: tagDelegate.editMode
                    }
                }
            }
        }
    }

    footer: QQC2.ToolBar {
        background: Rectangle {
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Window

            color: Kirigami.Theme.backgroundColor

            Kirigami.Separator {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
            }
        }

        contentItem: RowLayout {
            QQC2.TextField {
                id: newTagField

                placeholderText: i18n("Create a New Tag…")
                maximumLength: 50
                implicitHeight: Kirigami.Units.gridUnit * 3
                onAccepted: addTagButton.click()
                background: null

                Layout.fillWidth: true
            }

            QQC2.ToolButton {
                id: addTagButton
                icon.name: "tag-new"
                text: i18n("Quickly Add a New Tag.")
                display: QQC2.ToolButton.IconOnly

                onClicked: if (newTagField.text.length > 0) {
                    Akonadi.TagManager.createTag(newTagField.text.replace(/\r?\n|\r/g, " "));
                    newTagField.text = "";
                }

                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }
    }
}
