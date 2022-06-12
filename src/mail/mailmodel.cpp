// SPDX-FileCopyrightText: 2021 Simon Schmeisser <s.schmeisser@gmx.net>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "mailmodel.h"

//#include "messagewrapper.h"
//#include "messageviewer/viewer.h"

#include <Akonadi/EntityTreeModel>
#include <KFormat>
#include <KLocalizedString>
#include <KMime/Message>
#include <QQmlEngine>
#include <kformat.h>
#include <qvariant.h>

MailModel::MailModel(QObject *parent)
    : QIdentityProxyModel(parent)
//    , m_viewerHelper(new ViewerHelper(this))
{
}

QHash<int, QByteArray> MailModel::roleNames() const
{
    return {
        {TitleRole, QByteArrayLiteral("title")},
        {DateRole, QByteArrayLiteral("date")},
        {DateTimeRole, QByteArrayLiteral("datetime")},
        {SenderRole, QByteArrayLiteral("sender")},
        {FromRole, QByteArrayLiteral("from")},
        {ToRole, QByteArrayLiteral("to")},
        {UnreadRole, QByteArrayLiteral("unread")},
        {FavoriteRole, QByteArrayLiteral("favorite")},
        {TextColorRole, QByteArrayLiteral("textColor")},
        {BackgroundColorRole, QByteArrayLiteral("backgroudColor")},
        {ItemRole, QByteArrayLiteral("item")},
    };
}

QVariant MailModel::data(const QModelIndex &index, int role) const
{
    QVariant itemVariant = sourceModel()->data(mapToSource(index), Akonadi::EntityTreeModel::ItemRole);

    Akonadi::Item item = itemVariant.value<Akonadi::Item>();

    if (!item.hasPayload<KMime::Message::Ptr>()) {
         return {};
    }
    const KMime::Message::Ptr mail = item.payload<KMime::Message::Ptr>();

    //const Collection parentCol = parentCollectionForRow(row);

    QString sender;
    if (mail->from()) {
        sender = mail->from()->asUnicodeString();
    }
    QString receiver;
    if (mail->to()) {
        receiver = mail->to()->asUnicodeString();
    }

    // Static for speed reasons
    static const QString noSubject = i18nc("displayed as subject when the subject of a mail is empty", "No Subject");
    static const QString unknown(i18nc("displayed when a mail has unknown sender, receiver or date", "Unknown"));

    if (sender.isEmpty()) {
        sender = unknown;
    }
    if (receiver.isEmpty()) {
        receiver = unknown;
    }

    //mi->initialSetup(mail->date()->dateTime().toSecsSinceEpoch(), item.size(), sender, receiver, bUseReceiver);
    //mi->setItemId(item.id());
    //mi->setParentCollectionId(parentCol.id());

    QString subject = mail->subject()->asUnicodeString();
    if (subject.isEmpty()) {
        subject = QLatin1Char('(') + noSubject + QLatin1Char(')');
    }

    //mi->setSubject(subject);

    //auto it = d->mFolderHash.find(item.storageCollectionId());
    //if (it == d->mFolderHash.end()) {
    //    QString folder;
    //    Collection collection = collectionForId(item.storageCollectionId());
    //    while (collection.parentCollection().isValid()) {
    //        folder = collection.displayName() + QLatin1Char('/') + folder;
    //        collection = collection.parentCollection();
    //    }
    //    folder.chop(1);
    //    it = d->mFolderHash.insert(item.storageCollectionId(), folder);
    //}
    //mi->setFolder(it.value());

    // NOTE: remember to update AkonadiBrowserSortModel::lessThan if you insert/move columns
    switch (role) {
    case TitleRole:
        if (mail->subject()) {
            return mail->subject()->asUnicodeString();
        } else {
            return QStringLiteral("(No subject)");
        }
    case FromRole:
        if (mail->from()) {
            return mail->from()->asUnicodeString();
        } else {
            return QString();
        }
    case SenderRole:
        if (mail->sender()) {
            return mail->sender()->asUnicodeString();
        } else {
            return QString();
        }
    case ToRole:
        if (mail->to()) {
            return mail->sender()->asUnicodeString();
        } else {
            return QString();
        }
    case DateRole:
        if (mail->date()) {
            KFormat format;
            return format.formatRelativeDate(mail->date()->dateTime().date(), QLocale::LongFormat);
        } else {
            return QString();
        }
    case DateTimeRole:
        if (mail->date()) {
            return mail->date()->dateTime();
        } else {
            return QString();
        }
    case ItemRole:
        return QVariant::fromValue(item);
    }

    return {};
}

void MailModel::loadItem(int row)
{
    //if (!m_viewerHelper) {
    //    return;
    //}
    QVariant itemVariant = sourceModel()->data(mapToSource(index(row, 0)), Akonadi::EntityTreeModel::ItemRole);

    Akonadi::Item item = itemVariant.value<Akonadi::Item>();

    //m_viewerHelper->setMessageItem(item);
}

//void MailModel::setViewerHelper(ViewerHelper *viewerHelper)
//{
//    if (m_viewerHelper == viewerHelper) {
//        return;
//    }
//    m_viewerHelper = viewerHelper;
//    Q_EMIT viewerHelperChanged();
//}
//
//ViewerHelper *MailModel::viewerHelper() const
//{
//    return m_viewerHelper;
//}
