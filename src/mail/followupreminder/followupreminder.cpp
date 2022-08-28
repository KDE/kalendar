/*
   SPDX-FileCopyrightText: 2020 Daniel Vrátil <dvratil@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "followupreminder.h"
#include "followupreminderinterface.h"

#include <Akonadi/ServerManager>

bool FollowUpReminder::isAvailableAndEnabled()
{
    using Akonadi::ServerManager;
    org::freedesktop::Kalendar::FollowUpReminderAgent iface{
        ServerManager::agentServiceName(ServerManager::Agent, QStringLiteral("kalendar_followupreminder_agent")),
        QStringLiteral("/FollowUpReminder"),
        QDBusConnection::sessionBus()};

    return iface.isValid() && iface.enabledAgent();
}
