/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "followupremindercreatejob.h"
#include "followupreminderinterface.h"
#include "kalendar_mail_debug.h"

#include <Akonadi/ItemCreateJob>
#include <Akonadi/ServerManager>
#include <KCalendarCore/Todo>
#include <KLocalizedString>

#include <QDBusConnection>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>

class FollowupReminderCreateJobPrivate
{
public:
    Akonadi::Collection mCollection;
    QDate mFollowupDate;
    Akonadi::Item::Id mOriginalMessageItemId = -1;
    Akonadi::Item::Id mTodoId = -1;
    QString mMessageId;
    QString mSubject;
    QString mTo;
};

FollowupReminderCreateJob::FollowupReminderCreateJob(QObject *parent)
    : KJob(parent)
    , d(new FollowupReminderCreateJobPrivate)
{
}

FollowupReminderCreateJob::~FollowupReminderCreateJob() = default;

QDate FollowupReminderCreateJob::followUpReminderDate() const
{
    return d->mFollowupDate;
}

void FollowupReminderCreateJob::setFollowUpReminderDate(const QDate &date)
{
    Q_EMIT followUpReminderDateChanged();
    d->mFollowupDate = date;
}

Akonadi::Item::Id FollowupReminderCreateJob::originalMessageItemId() const
{
    return d->mOriginalMessageItemId;
}

void FollowupReminderCreateJob::setOriginalMessageItemId(Akonadi::Item::Id value)
{
    Q_EMIT originalMessageItemIdChanged();
    d->mOriginalMessageItemId = value;
}

QString FollowupReminderCreateJob::messageId() const
{
    return d->mMessageId;
}

void FollowupReminderCreateJob::setMessageId(const QString &messageId)
{
    Q_EMIT messageIdChanged();
    d->mMessageId = messageId;
}

QString FollowupReminderCreateJob::to() const
{
    return d->mTo;
}

void FollowupReminderCreateJob::setTo(const QString &to)
{
    Q_EMIT toChanged();
    d->mTo = to;
}

QString FollowupReminderCreateJob::subject() const
{
    return d->mSubject;
}

void FollowupReminderCreateJob::setSubject(const QString &subject)
{
    d->mSubject = subject;
}

Akonadi::Collection FollowupReminderCreateJob::collectionToDo() const
{
    return d->mCollection;
}

void FollowupReminderCreateJob::setCollectionToDo(const Akonadi::Collection &collection)
{
    d->mCollection = collection;
}

void FollowupReminderCreateJob::start()
{
    if (!d->mMessageId.isEmpty() && d->mFollowupDate.isValid() && !d->mTo.isEmpty()) {
        if (d->mCollection.isValid()) {
            KCalendarCore::Todo::Ptr todo(new KCalendarCore::Todo);
            todo->setSummary(i18n("Wait answer from \"%1\" send to \"%2\"", d->mSubject, d->mTo));
            todo->setDtDue(QDateTime(d->mFollowupDate, QTime(0, 0, 0)));
            Akonadi::Item newTodoItem;
            newTodoItem.setMimeType(KCalendarCore::Todo::todoMimeType());
            newTodoItem.setPayload<KCalendarCore::Todo::Ptr>(todo);

            auto createJob = new Akonadi::ItemCreateJob(newTodoItem, d->mCollection);
            connect(createJob, &Akonadi::ItemCreateJob::result, this, &FollowupReminderCreateJob::slotCreateNewTodo);
        } else {
            writeFollowupReminderInfo();
        }
    } else {
        qCWarning(KALENDAR_MAIL_LOG) << "FollowupReminderCreateJob info not valid!";
        emitResult();
        return;
    }
}

void FollowupReminderCreateJob::slotCreateNewTodo(KJob *job)
{
    if (job->error()) {
        qCWarning(KALENDAR_MAIL_LOG) << "Error during create new Todo " << job->errorString();
        setError(job->error());
        setErrorText(i18n("Failed to store a new reminder: an error occurred while trying to create a new to-do in your calendar: %1", job->errorString()));
        emitResult();
        return;
    }

    auto createJob = qobject_cast<Akonadi::ItemCreateJob *>(job);
    d->mTodoId = createJob->item().id();
    writeFollowupReminderInfo();
}

void FollowupReminderCreateJob::writeFollowupReminderInfo()
{
    std::unique_ptr<org::freedesktop::Kalendar::FollowUpReminderAgent> iface{new org::freedesktop::Kalendar::FollowUpReminderAgent{
        Akonadi::ServerManager::agentServiceName(Akonadi::ServerManager::Agent, QStringLiteral("akonadi_followupreminder_agent")),
        QStringLiteral("/FollowUpReminder"),
        QDBusConnection::sessionBus()}};

    if (!iface->isValid()) {
        qCWarning(KALENDAR_MAIL_LOG) << "The FollowUpReminder agent is not running!";
        return;
    }

    auto call = iface->addReminder(d->mMessageId, d->mOriginalMessageItemId, d->mTo, d->mSubject, d->mFollowupDate, d->mTodoId);
    auto wait = new QDBusPendingCallWatcher{call, this};
    connect(wait, &QDBusPendingCallWatcher::finished, this, [this, iface_ = std::move(iface)](QDBusPendingCallWatcher *watcher) mutable {
        auto iface = std::move(iface_);
        watcher->deleteLater();

        const QDBusPendingReply<void> reply = *watcher;
        if (reply.isError()) {
            qCWarning(KALENDAR_MAIL_LOG) << "Failed to write the new reminder, agent replied" << reply.error().message();
            setError(KJob::UserDefinedError);
            setErrorText(i18n("Failed to store a new reminder: %1", reply.error().message()));
        }

        emitResult();
    });
}
