// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "mailaccounts.h"

#include <Akonadi/AgentConfigurationDialog>
#include <Akonadi/AgentFilterProxyModel>
#include <Akonadi/AgentInstanceModel>
#include <KMime/Message>

MailAccounts::MailAccounts(QObject *parent)
    : QObject{parent}
{
}

Akonadi::AgentFilterProxyModel *MailAccounts::runningMailAgents()
{
    if (m_runningMailAgents) {
        return m_runningMailAgents;
    }

    auto agentInstanceModel = new Akonadi::AgentInstanceModel(this);
    m_runningMailAgents = new Akonadi::AgentFilterProxyModel(this);

    m_runningMailAgents->addMimeTypeFilter(KMime::Message::mimeType());
    m_runningMailAgents->setSourceModel(agentInstanceModel);
    m_runningMailAgents->addCapabilityFilter(QStringLiteral("Resource"));
    m_runningMailAgents->excludeCapabilities(QStringLiteral("MailTransport"));
    m_runningMailAgents->excludeCapabilities(QStringLiteral("Notes"));
    return m_runningMailAgents;
}

void MailAccounts::remove(int index)
{
    Akonadi::AgentManager::self()->removeInstance(instanceFromIndex(index));
}

void MailAccounts::openConfigWindow(int index)
{
    auto agentInstance = instanceFromIndex(index);

    if (agentInstance.isValid()) {
        Akonadi::AgentConfigurationDialog *dlg = new Akonadi::AgentConfigurationDialog(agentInstance);
        dlg->exec();
        delete dlg;
    }
}

Akonadi::AgentInstance MailAccounts::instanceFromIndex(int index)
{
    return runningMailAgents()->data(runningMailAgents()->index(index, 0), Akonadi::AgentInstanceModel::InstanceRole).value<Akonadi::AgentInstance>();
}
