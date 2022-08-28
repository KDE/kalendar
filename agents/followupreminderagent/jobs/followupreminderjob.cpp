/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "followupreminderjob.h"

#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/MessageParts>

#include <KMime/Message>

#include "followupreminderagent_debug.h"

FollowUpReminderJob::FollowUpReminderJob(QObject *parent)
    : QObject(parent)
{
}

FollowUpReminderJob::~FollowUpReminderJob() = default;

void FollowUpReminderJob::start()
{
    if (!mItem.isValid()) {
        qCDebug(FOLLOWUPREMINDERAGENT_LOG) << " item is not valid";
        deleteLater();
        return;
    }
    auto job = new Akonadi::ItemFetchJob(mItem);
    job->fetchScope().fetchPayloadPart(Akonadi::MessagePart::Envelope, true);
    job->fetchScope().setAncestorRetrieval(Akonadi::ItemFetchScope::Parent);

    connect(job, &Akonadi::ItemFetchJob::result, this, &FollowUpReminderJob::slotItemFetchJobDone);
}

void FollowUpReminderJob::setItem(const Akonadi::Item &item)
{
    mItem = item;
}

void FollowUpReminderJob::slotItemFetchJobDone(KJob *job)
{
    if (job->error()) {
        qCCritical(FOLLOWUPREMINDERAGENT_LOG) << "Error while fetching item. " << job->error() << job->errorString();
        deleteLater();
        return;
    }

    const Akonadi::ItemFetchJob *fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);

    const Akonadi::Item::List items = fetchJob->items();
    if (items.isEmpty()) {
        qCCritical(FOLLOWUPREMINDERAGENT_LOG) << "Error while fetching item: item not found";
        deleteLater();
        return;
    }
    const Akonadi::Item item = items.at(0);
    if (!item.hasPayload<KMime::Message::Ptr>()) {
        qCCritical(FOLLOWUPREMINDERAGENT_LOG) << "Item has not payload";
        deleteLater();
        return;
    }
    const auto msg = item.payload<KMime::Message::Ptr>();
    if (msg) {
        KMime::Headers::InReplyTo *replyTo = msg->inReplyTo(false);
        if (replyTo) {
            const QString replyToIdStr = replyTo->asUnicodeString();
            Q_EMIT finished(replyToIdStr, item.id());
        }
    }
    deleteLater();
}
