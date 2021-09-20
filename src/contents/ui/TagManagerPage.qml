// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0

Kirigami.ScrollablePage {
    id: root

    title: i18n("Manage Tags")

    Kirigami.OverlaySheet {
        id: deleteConfirmSheet
        title: i18n("Delete Tag")

        property string tagName
        property var tag

        ColumnLayout {
            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Are you sure you want to delete tag \"%1\"?", deleteConfirmSheet.tagName)
                wrapMode: Text.Wrap
            }
        }

        footer: QQC2.DialogButtonBox {
            standardButtons: QQC2.DialogButtonBox.Ok | QQC2.DialogButtonBox.Cancel

            onAccepted: {
                TagManager.deleteTag(deleteConfirmSheet.tag);
                deleteConfirmSheet.close();
            }
            onRejected: deleteConfirmSheet.close()
        }
    }

    ListView {
        currentIndex: -1
        model: TagManager.tagModel
        delegate: Kirigami.BasicListItem {
            contentItem: Item {
                implicitWidth: delegateLayout.implicitWidth
                implicitHeight: delegateLayout.implicitHeight
                RowLayout {
                    id: delegateLayout

                    property bool editMode: false

                    anchors {
                        left: parent.left
                        top: parent.top
                        right: parent.right
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: model.display
                        visible: !delegateLayout.editMode
                    }
                    QQC2.ToolButton {
                        icon.name: "edit-rename"
                        onClicked: delegateLayout.editMode = true
                        visible: !delegateLayout.editMode
                    }
                    QQC2.ToolButton {
                        icon.name: "delete"
                        onClicked: {
                            deleteConfirmSheet.tag = model.tag;
                            deleteConfirmSheet.tagName = model.name;
                            deleteConfirmSheet.open();
                        }
                        visible: !delegateLayout.editMode
                    }

                    QQC2.TextField {
                        id: tagNameField
                        Layout.fillWidth: true
                        text: model.display
                        visible: delegateLayout.editMode
                    }
                    QQC2.ToolButton {
                        icon.name: "gtk-apply"
                        visible: delegateLayout.editMode
                        onClicked: {
                            TagManager.renameTag(model.tag, tagNameField.text)
                            delegateLayout.editMode = false;
                        }
                    }
                    QQC2.ToolButton {
                        icon.name: "gtk-cancel"
                        onClicked: {
                            delegateLayout.editMode = false;
                            tagNameField.text = model.display;
                        }
                        visible: delegateLayout.editMode
                    }
                }
            }
        }
    }


    footer: Kirigami.ActionTextField {
        id: newTagField
        Layout.fillWidth: true
        placeholderText: i18n("Create a New Tag...")
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

        function addTag() {
            if(newTagField.text.length > 0) {
                TagManager.createTag(newTagField.text);
                newTagField.text = "";
            }
        }

        rightActions: Kirigami.Action {
            icon.name: "tag-new"
            tooltip: i18n("Quickly Add a New Tag.")
            onTriggered: newTagField.addTag()
        }
        onAccepted: newTagField.addTag()
    }
}
