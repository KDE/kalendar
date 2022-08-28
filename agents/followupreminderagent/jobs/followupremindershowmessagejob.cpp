/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "followupremindershowmessagejob.h"
#include "followupreminderagent_debug.h"
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusInterface>

FollowUpReminderShowMessageJob::FollowUpReminderShowMessageJob(Akonadi::Item::Id id, QObject *parent)
    : QObject(parent)
    , mId(id)
{
}

FollowUpReminderShowMessageJob::~FollowUpReminderShowMessageJob() = default;

void FollowUpReminderShowMessageJob::start()
{
    if (mId < 0) {
        qCWarning(FOLLOWUPREMINDERAGENT_LOG) << " value < 0";
        deleteLater();
        return;
    }
    const QString kmailInterface = QStringLiteral("org.kde.kmail");
    if (!QDBusConnection::sessionBus().interface()->isServiceRegistered(kmailInterface)) {
        // Program is not already running, so start it
        QString errmsg;
        if (!QDBusConnection::sessionBus().interface()->startService(QStringLiteral("org.kde.kmail2")).isValid()) {
            qCDebug(FOLLOWUPREMINDERAGENT_LOG) << " Can not start kmail" << errmsg;
            deleteLater();
            return;
        }
    }
    QDBusInterface kmail(kmailInterface, QStringLiteral("/KMail"), QStringLiteral("org.kde.kmail.kmail"));
    kmail.call(QStringLiteral("showMail"), mId);
    deleteLater();
}
