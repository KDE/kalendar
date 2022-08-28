/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "followupremindermanager.h"
#include "followupreminderagent_debug.h"
#include "followupreminderinfo.h"
#include "followupremindernoanswerdialog.h"
#include "followupreminderutil.h"
#include "jobs/followupreminderfinishtaskjob.h"
#include "jobs/followupreminderjob.h"

#include <Akonadi/SpecialMailCollections>

#include <KConfig>
#include <KConfigGroup>
#include <KLocalizedString>
#include <KNotification>
#include <QRegularExpression>
using namespace FollowUpReminder;

FollowUpReminderManager::FollowUpReminderManager(QObject *parent)
    : QObject(parent)
{
    mConfig = KSharedConfig::openConfig();
}

FollowUpReminderManager::~FollowUpReminderManager()
{
    qDeleteAll(mFollowUpReminderInfoList);
    mFollowUpReminderInfoList.clear();
}

void FollowUpReminderManager::load(bool forceReloadConfig)
{
    if (forceReloadConfig) {
        mConfig->reparseConfiguration();
    }
    const QStringList itemList = mConfig->groupList().filter(QRegularExpression(QStringLiteral("FollowupReminderItem \\d+")));
    const int numberOfItems = itemList.count();
    QList<FollowUpReminder::FollowUpReminderInfo *> noAnswerList;
    for (int i = 0; i < numberOfItems; ++i) {
        KConfigGroup group = mConfig->group(itemList.at(i));

        auto info = new FollowUpReminderInfo(group);
        if (info->isValid()) {
            if (!info->answerWasReceived()) {
                mFollowUpReminderInfoList.append(info);
                if (!mInitialize) {
                    auto noAnswerInfo = new FollowUpReminderInfo(*info);
                    noAnswerList.append(noAnswerInfo);
                } else {
                    delete info;
                }
            } else {
                delete info;
            }
        } else {
            delete info;
        }
    }
    if (!noAnswerList.isEmpty()) {
        mInitialize = true;
        if (!mNoAnswerDialog.data()) {
            mNoAnswerDialog = new FollowUpReminderNoAnswerDialog;
            connect(mNoAnswerDialog.data(),
                    &FollowUpReminderNoAnswerDialog::needToReparseConfiguration,
                    this,
                    &FollowUpReminderManager::slotReparseConfiguration);
        }
        mNoAnswerDialog->setInfo(noAnswerList);
        mNoAnswerDialog->wakeUp();
    }
}

void FollowUpReminderManager::addReminder(FollowUpReminder::FollowUpReminderInfo *info)
{
    if (info->isValid()) {
        FollowUpReminderUtil::writeFollowupReminderInfo(FollowUpReminderUtil::defaultConfig(), info, true);
    } else {
        delete info;
    }
}

void FollowUpReminderManager::slotReparseConfiguration()
{
    load(true);
}

void FollowUpReminderManager::checkFollowUp(const Akonadi::Item &item, const Akonadi::Collection &col)
{
    if (mFollowUpReminderInfoList.isEmpty()) {
        return;
    }

    const Akonadi::SpecialMailCollections::Type type = Akonadi::SpecialMailCollections::self()->specialCollectionType(col);
    switch (type) {
    case Akonadi::SpecialMailCollections::Trash:
    case Akonadi::SpecialMailCollections::Outbox:
    case Akonadi::SpecialMailCollections::Drafts:
    case Akonadi::SpecialMailCollections::Templates:
    case Akonadi::SpecialMailCollections::SentMail:
        return;
    default:
        break;
    }

    auto job = new FollowUpReminderJob(this);
    connect(job, &FollowUpReminderJob::finished, this, &FollowUpReminderManager::slotCheckFollowUpFinished);
    job->setItem(item);
    job->start();
}

void FollowUpReminderManager::slotCheckFollowUpFinished(const QString &messageId, Akonadi::Item::Id id)
{
    for (FollowUpReminderInfo *info : std::as_const(mFollowUpReminderInfoList)) {
        qCDebug(FOLLOWUPREMINDERAGENT_LOG) << "FollowUpReminderManager::slotCheckFollowUpFinished info:" << info;
        if (!info) {
            continue;
        }
        if (info->messageId() == messageId) {
            info->setAnswerMessageItemId(id);
            info->setAnswerWasReceived(true);
            answerReceived(info->to());
            if (info->todoId() != -1) {
                auto job = new FollowUpReminderFinishTaskJob(info->todoId(), this);
                connect(job, &FollowUpReminderFinishTaskJob::finishTaskDone, this, &FollowUpReminderManager::slotFinishTaskDone);
                connect(job, &FollowUpReminderFinishTaskJob::finishTaskFailed, this, &FollowUpReminderManager::slotFinishTaskFailed);
                job->start();
            }
            // Save item
            FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(FollowUpReminder::FollowUpReminderUtil::defaultConfig(), info, true);
            break;
        }
    }
}

void FollowUpReminderManager::slotFinishTaskDone()
{
    qCDebug(FOLLOWUPREMINDERAGENT_LOG) << " Task Done";
}

void FollowUpReminderManager::slotFinishTaskFailed()
{
    qCDebug(FOLLOWUPREMINDERAGENT_LOG) << " Task Failed";
}

void FollowUpReminderManager::answerReceived(const QString &from)
{
    KNotification::event(QStringLiteral("mailreceived"),
                         QString(),
                         i18n("Answer from %1 received", from),
                         QStringLiteral("kmail"),
                         nullptr,
                         KNotification::CloseOnTimeout,
                         QStringLiteral("akonadi_followupreminder_agent"));
}

QString FollowUpReminderManager::printDebugInfo() const
{
    QString infoStr;
    if (mFollowUpReminderInfoList.isEmpty()) {
        infoStr = QStringLiteral("No mail");
    } else {
        for (FollowUpReminder::FollowUpReminderInfo *info : std::as_const(mFollowUpReminderInfoList)) {
            if (!infoStr.isEmpty()) {
                infoStr += QLatin1Char('\n');
            }
            infoStr += infoToStr(info);
        }
    }
    return infoStr;
}

QString FollowUpReminderManager::infoToStr(FollowUpReminder::FollowUpReminderInfo *info) const
{
    QString infoStr = QStringLiteral("****************************************");
    infoStr += QStringLiteral("Akonadi Item id :%1\n").arg(info->originalMessageItemId());
    infoStr += QStringLiteral("MessageId :%1\n").arg(info->messageId());
    infoStr += QStringLiteral("Subject :%1\n").arg(info->subject());
    infoStr += QStringLiteral("To :%1\n").arg(info->to());
    infoStr += QStringLiteral("Deadline :%1\n").arg(info->followUpReminderDate().toString());
    infoStr += QStringLiteral("Answer received :%1\n").arg(info->answerWasReceived() ? QStringLiteral("true") : QStringLiteral("false"));
    infoStr += QStringLiteral("****************************************\n");
    return infoStr;
}
