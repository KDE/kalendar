// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "agentconfiguration.h"
#include <akonadi_version.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 18, 41)
#include <Akonadi/AgentConfigurationDialog>
#include <Akonadi/AgentInstanceCreateJob>
#include <Akonadi/AgentInstanceModel>
#include <Akonadi/AgentManager>
#include <Akonadi/AgentTypeModel>
#else
#include <AgentConfigurationDialog>
#include <AkonadiCore/AgentInstanceCreateJob>
#include <AkonadiCore/AgentInstanceModel>
#include <AkonadiCore/AgentManager>
#include <AkonadiCore/AgentTypeModel>
#endif
#include <KWindowSystem>
#include <QPointer>

using namespace Akonadi;

AgentConfiguration::AgentConfiguration(QObject *parent)
    : QObject(parent)
    , m_runningAgents(nullptr)
    , m_availableAgents(nullptr)
{
}

AgentConfiguration::~AgentConfiguration()
{
}

Akonadi::AgentFilterProxyModel *AgentConfiguration::availableAgents()
{
    if (m_availableAgents) {
        return m_availableAgents;
    }

    auto agentInstanceModel = new AgentTypeModel(this);
    m_availableAgents = new AgentFilterProxyModel(this);
    m_availableAgents->addMimeTypeFilter(QStringLiteral("text/calendar"));
    m_availableAgents->setSourceModel(agentInstanceModel);
    m_availableAgents->addCapabilityFilter(QStringLiteral("Resource")); // show only resources, no agents
    return m_availableAgents;
}

Akonadi::AgentFilterProxyModel *AgentConfiguration::runningAgents()
{
    if (m_runningAgents) {
        return m_runningAgents;
    }

    auto agentInstanceModel = new AgentInstanceModel(this);
    m_runningAgents = new AgentFilterProxyModel(this);
    m_runningAgents->addMimeTypeFilter(QStringLiteral("text/calendar"));
    m_runningAgents->setSourceModel(agentInstanceModel);
    m_runningAgents->addCapabilityFilter(QStringLiteral("Resource")); // show only resources, no agents
    return m_runningAgents;
}

void AgentConfiguration::createNew(int index)
{
    Q_ASSERT(m_availableAgents != nullptr);

    const Akonadi::AgentType agentType = m_availableAgents->data(m_availableAgents->index(index, 0), AgentTypeModel::TypeRole).value<AgentType>();

    if (agentType.isValid()) {
        auto job = new Akonadi::AgentInstanceCreateJob(agentType, this);
        job->configure(nullptr);
        job->start();
    }
}

void AgentConfiguration::edit(int index)
{
    Q_ASSERT(m_runningAgents != nullptr);

    Akonadi::AgentInstance instance = m_runningAgents->data(m_runningAgents->index(index, 0), AgentInstanceModel::InstanceRole).value<AgentInstance>();
    if (instance.isValid()) {
        KWindowSystem::allowExternalProcessWindowActivation();
        QPointer<AgentConfigurationDialog> dlg(new AgentConfigurationDialog(instance, nullptr));
        dlg->exec();
        delete dlg;
    }
}

void AgentConfiguration::restart(int index)
{
    Q_ASSERT(m_runningAgents != nullptr);

    Akonadi::AgentInstance instance = m_runningAgents->data(m_runningAgents->index(index, 0), AgentInstanceModel::InstanceRole).value<AgentInstance>();
    if (instance.isValid()) {
        instance.restart();
    }
}

void AgentConfiguration::remove(int index)
{
    Q_ASSERT(m_runningAgents != nullptr);

    Akonadi::AgentInstance instance = m_runningAgents->data(m_runningAgents->index(index, 0), AgentInstanceModel::InstanceRole).value<AgentInstance>();
    if (instance.isValid()) {
        Akonadi::AgentManager::self()->removeInstance(instance);
    }
}
