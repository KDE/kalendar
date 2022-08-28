/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <KSharedConfig>

namespace FollowUpReminder
{
class FollowUpReminderInfo;

/** Follow up reminder utilities. */
namespace FollowUpReminderUtil
{
Q_REQUIRED_RESULT bool followupReminderAgentWasRegistered();

Q_REQUIRED_RESULT bool followupReminderAgentEnabled();

void reload();

void forceReparseConfiguration();

KSharedConfig::Ptr defaultConfig();

void writeFollowupReminderInfo(KSharedConfig::Ptr config, FollowUpReminder::FollowUpReminderInfo *info, bool forceReload);

Q_REQUIRED_RESULT bool removeFollowupReminderInfo(KSharedConfig::Ptr config, const QList<qint32> &listRemove, bool forceReload = false);

Q_REQUIRED_RESULT QString followUpReminderPattern();
}
}
