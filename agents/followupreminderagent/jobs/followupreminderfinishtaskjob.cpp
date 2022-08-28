/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "followupreminderfinishtaskjob.h"
#include "followupreminderagent_debug.h"
#include "followupreminderinfo.h"

#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemModifyJob>
#include <KCalendarCore/Todo>

FollowUpReminderFinishTaskJob::FollowUpReminderFinishTaskJob(Akonadi::Item::Id id, QObject *parent)
    : QObject(parent)
    , mTodoId(id)
{
}

FollowUpReminderFinishTaskJob::~FollowUpReminderFinishTaskJob() = default;

void FollowUpReminderFinishTaskJob::start()
{
    if (mTodoId != -1) {
        closeTodo();
    } else {
        qCWarning(FOLLOWUPREMINDERAGENT_LOG) << "Failed to FollowUpReminderFinishTaskJob::start";
        Q_EMIT finishTaskFailed();
        deleteLater();
    }
}

void FollowUpReminderFinishTaskJob::closeTodo()
{
    Akonadi::Item item(mTodoId);
    auto job = new Akonadi::ItemFetchJob(item, this);
    connect(job, &Akonadi::ItemFetchJob::result, this, &FollowUpReminderFinishTaskJob::slotItemFetchJobDone);
}

void FollowUpReminderFinishTaskJob::slotItemFetchJobDone(KJob *job)
{
    if (job->error()) {
        qCWarning(FOLLOWUPREMINDERAGENT_LOG) << "Failed to fetch item in FollowUpReminderFinishTaskJob : " << job->errorString();
        Q_EMIT finishTaskFailed();
        deleteLater();
        return;
    }

    const Akonadi::Item::List lst = qobject_cast<Akonadi::ItemFetchJob *>(job)->items();
    if (lst.count() == 1) {
        const Akonadi::Item item = lst.first();
        if (!item.hasPayload<KCalendarCore::Todo::Ptr>()) {
            qCDebug(FOLLOWUPREMINDERAGENT_LOG) << "FollowUpReminderFinishTaskJob::slotItemFetchJobDone: item is not a todo.";
            Q_EMIT finishTaskFailed();
            deleteLater();
            return;
        }
        auto todo = item.payload<KCalendarCore::Todo::Ptr>();
        todo->setCompleted(true);
        Akonadi::Item updateItem = item;
        updateItem.setPayload<KCalendarCore::Todo::Ptr>(todo);

        auto job = new Akonadi::ItemModifyJob(updateItem);
        connect(job, &Akonadi::ItemModifyJob::result, this, &FollowUpReminderFinishTaskJob::slotItemModifiedResult);
    } else {
        qCWarning(FOLLOWUPREMINDERAGENT_LOG) << " Found item different from 1: " << lst.count();
        Q_EMIT finishTaskFailed();
        deleteLater();
        return;
    }
}

void FollowUpReminderFinishTaskJob::slotItemModifiedResult(KJob *job)
{
    if (job->error()) {
        qCWarning(FOLLOWUPREMINDERAGENT_LOG) << "FollowUpReminderFinishTaskJob::slotItemModifiedResult: Error during modified item: " << job->errorString();
        Q_EMIT finishTaskFailed();
    } else {
        Q_EMIT finishTaskDone();
    }
    deleteLater();
}
