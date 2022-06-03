// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
import org.kde.kalendar.mail 1.0
import org.kde.kitemmodels 1.0 as KItemModels

 Kirigami.ScrollablePage {
    id: folderView
    property var mailViewer: null;
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
            subtitle: sender
            onClicked: {
                if (!folderView.mailViewer) {
                    folderView.mailViewer = root.pageStack.push(mailComponent, {
                        viewerHelper: MailManager.folderModel.viewerHelper
                    });
                } else {
                    applicationWindow().pageStack.currentIndex = applicationWindow().pageStack.depth - 1;
                }

                QuickMail.folderModel.loadItem(index);
            }
        }
    }
}

