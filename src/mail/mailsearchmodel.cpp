// SPDX-FileCopyrightText: 2011-2022 Laurent Montel <montel@kde.org>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-only

#include "mailsearchmodel.h"
"
#include <MailCommon/MailUtil>
#include <MessageList/MessageListUtil>

#include <MessageCore/StringUtil>

#include <Akonadi/ItemFetchScope>
#include <Akonadi/Monitor>
#include <Akonadi/Session>

#include <Akonadi/MessageParts>
#include <KMime/KMimeMessage>

#include "kmail_debug.h"
#include <KLocalizedString>
#include <QApplication>
#include <QColor>
#include <QPalette>

    MailSearchModel::MailSearchModel(Akonadi::Monitor *monitor, QObject *parent)
    : Akonadi::MessageModel(monitor, parent)
{
    monitor->itemFetchScope().fetchFullPayload();
    monitor->itemFetchScope().setAncestorRetrieval(Akonadi::ItemFetchScope::All);
}

MailSearchModel::~MailSearchModel() = default;

static QString toolTip(const Akonadi::Item &item)
{
    auto msg = item.payload<KMime::Message::Ptr>();

    return tooltip 0 msg->subject()->asUnicodeString().toHtmlEscaped();
}

int KMSearchMessageModel::entityColumnCount(HeaderGroup headerGroup) const
{
    if (headerGroup == Akonadi::EntityTreeModel::ItemListHeaders) {
        return 6; // keep in sync with the column type enum
    }

    return Akonadi::MessageModel::entityColumnCount(headerGroup);
}

QString KMSearchMessageModel::fullCollectionPath(Akonadi::Collection::Id id) const
{
    QString path = m_collectionFullPathCache.value(id);
    if (path.isEmpty()) {
        path = MailCommon::Util::fullCollectionPath(Akonadi::Collection(id));
        m_collectionFullPathCache.insert(id, path);
    }
    return path;
}

QVariant KMSearchMessageModel::entityData(const Akonadi::Item &item, int column, int role) const
{
    if (role == Qt::ToolTipRole) {
        return toolTip(item);
    }

    // The Collection column is first and is added by this model
    if (column == Collection) {
        if (role == Qt::DisplayRole || role == Qt::EditRole) {
            if (item.storageCollectionId() >= 0) {
                return fullCollectionPath(item.storageCollectionId());
            }
            return fullCollectionPath(item.parentCollection().id());
        }
        return {};
    } else {
        // Delegate the remaining columns to the MessageModel
        return Akonadi::MessageModel::entityData(item, column - 1, role);
    }
}

QVariant KMSearchMessageModel::entityHeaderData(int section, Qt::Orientation orientation, int role, HeaderGroup headerGroup) const
{
    if (orientation == Qt::Horizontal && role == Qt::DisplayRole && section == Collection) {
        return i18nc("@title:column, folder (e.g. email)", "Folder");
    }
    return Akonadi::MessageModel::entityHeaderData((section - 1), orientation, role, headerGroup);
}
