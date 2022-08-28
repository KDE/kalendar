/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "followupreminderutil.h"
#include "followupreminderinfo.h"
#include <Akonadi/ServerManager>

#include "followupreminderagentsettings.h"
#include <QDBusInterface>

namespace
{
QString serviceName()
{
    return Akonadi::ServerManager::agentServiceName(Akonadi::ServerManager::Agent, QStringLiteral("akonadi_followupreminder_agent"));
}

QString dbusPath()
{
    return QStringLiteral("/FollowUpReminder");
}
}

bool FollowUpReminder::FollowUpReminderUtil::followupReminderAgentWasRegistered()
{
    QDBusInterface interface(serviceName(), dbusPath());
    return interface.isValid();
}

bool FollowUpReminder::FollowUpReminderUtil::followupReminderAgentEnabled()
{
    return FollowUpReminderAgentSettings::self()->enabled();
}

void FollowUpReminder::FollowUpReminderUtil::reload()
{
    QDBusInterface interface(serviceName(), dbusPath());
    if (interface.isValid()) {
        interface.call(QStringLiteral("reload"));
    }
}

void FollowUpReminder::FollowUpReminderUtil::forceReparseConfiguration()
{
    FollowUpReminderAgentSettings::self()->save();
    FollowUpReminderAgentSettings::self()->config()->reparseConfiguration();
}

KSharedConfig::Ptr FollowUpReminder::FollowUpReminderUtil::defaultConfig()
{
    return KSharedConfig::openConfig(QStringLiteral("akonadi_followupreminder_agentrc"), KConfig::SimpleConfig);
}

void FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(KSharedConfig::Ptr config,
                                                                       FollowUpReminder::FollowUpReminderInfo *info,
                                                                       bool forceReload)
{
    if (!info || !info->isValid()) {
        return;
    }

    KConfigGroup general = config->group(QStringLiteral("General"));
    int value = general.readEntry("Number", 0);
    int identifier = info->uniqueIdentifier();
    if (identifier == -1) {
        identifier = value;
    }
    ++value;

    const QString groupName = FollowUpReminder::FollowUpReminderUtil::followUpReminderPattern().arg(identifier);
    // first, delete all filter groups:
    const QStringList filterGroups = config->groupList();
    for (const QString &group : filterGroups) {
        if (group == groupName) {
            config->deleteGroup(group);
        }
    }
    KConfigGroup group = config->group(groupName);
    info->writeConfig(group, identifier);

    general.writeEntry("Number", value);

    config->sync();
    config->reparseConfiguration();
    if (forceReload) {
        reload();
    }
}

bool FollowUpReminder::FollowUpReminderUtil::removeFollowupReminderInfo(KSharedConfig::Ptr config, const QList<qint32> &listRemove, bool forceReload)
{
    if (listRemove.isEmpty()) {
        return false;
    }

    bool needSaveConfig = false;
    KConfigGroup general = config->group(QStringLiteral("General"));
    int value = general.readEntry("Number", 0);

    for (qint32 identifier : listRemove) {
        const QString groupName = FollowUpReminder::FollowUpReminderUtil::followUpReminderPattern().arg(identifier);
        const QStringList filterGroups = config->groupList();
        for (const QString &group : filterGroups) {
            if (group == groupName) {
                config->deleteGroup(group);
                --value;
                needSaveConfig = true;
            }
        }
    }
    if (needSaveConfig) {
        general.writeEntry("Number", value);

        config->sync();
        config->reparseConfiguration();
        if (forceReload) {
            reload();
        }
    }
    return needSaveConfig;
}

QString FollowUpReminder::FollowUpReminderUtil::followUpReminderPattern()
{
    return QStringLiteral("FollowupReminderItem %1");
}
