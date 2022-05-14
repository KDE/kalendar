// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "agentconfiguration.h"
#include "kalendarapplication.h"

#include <Akonadi/AgentConfigurationDialog>
#include <Akonadi/AgentInstanceCreateJob>
#include <Akonadi/AgentInstanceModel>
#include <Akonadi/AgentManager>
#include <Akonadi/AgentTypeModel>
#include <KContacts/Addressee>
#include <KContacts/ContactGroup>

#include <KWindowSystem>
#include <QDebug>
#include <QPointer>
#include <qobjectdefs.h>

using namespace Akonadi;

AgentConfiguration::AgentConfiguration(QObject *parent)
    : QObject(parent)
    , m_mode(KalendarApplication::Event)
{
    connect(Akonadi::AgentManager::self(), &Akonadi::AgentManager::instanceProgressChanged, this, &AgentConfiguration::processInstanceProgressChanged);
    connect(Akonadi::AgentManager::self(), &Akonadi::AgentManager::instanceStatusChanged, this, &AgentConfiguration::processInstanceProgressChanged);
}

AgentConfiguration::~AgentConfiguration() = default;

Akonadi::AgentFilterProxyModel *AgentConfiguration::availableAgents()
{
    if (m_availableAgents) {
        return m_availableAgents;
    }

    auto agentInstanceModel = new AgentTypeModel(this);
    m_availableAgents = new AgentFilterProxyModel(this);
    if (m_mode == KalendarApplication::Contact) {
        m_availableAgents->addMimeTypeFilter(KContacts::Addressee::mimeType());
        m_availableAgents->addMimeTypeFilter(KContacts::ContactGroup::mimeType());
    } else {
        m_availableAgents->addMimeTypeFilter(QStringLiteral("text/calendar"));
    }
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
    if (m_mode == KalendarApplication::Contact) {
        m_runningAgents->addMimeTypeFilter(KContacts::Addressee::mimeType());
        m_runningAgents->addMimeTypeFilter(KContacts::ContactGroup::mimeType());
    } else {
        m_runningAgents->addMimeTypeFilter(QStringLiteral("text/calendar"));
    }
    m_runningAgents->setSourceModel(agentInstanceModel);
    m_runningAgents->addCapabilityFilter(QStringLiteral("Resource")); // show only resources, no agents
    return m_runningAgents;
}

void AgentConfiguration::createNew(int index)
{
    Q_ASSERT(m_availableAgents != nullptr);

    const auto agentType = m_availableAgents->data(m_availableAgents->index(index, 0), AgentTypeModel::TypeRole).value<AgentType>();

    if (agentType.isValid()) {
        auto job = new Akonadi::AgentInstanceCreateJob(agentType, this);
        job->configure(nullptr);
        job->start();
    }
}

void AgentConfiguration::edit(int index)
{
    Q_ASSERT(m_runningAgents != nullptr);

    auto instance = m_runningAgents->data(m_runningAgents->index(index, 0), AgentInstanceModel::InstanceRole).value<AgentInstance>();
    setupEdit(instance);
}

void AgentConfiguration::editIdentifier(const QString &resourceIdentifier)
{
    auto instance = Akonadi::AgentManager::self()->instance(resourceIdentifier);
    setupEdit(instance);
}

void AgentConfiguration::setupEdit(Akonadi::AgentInstance instance)
{
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

    auto instance = m_runningAgents->data(m_runningAgents->index(index, 0), AgentInstanceModel::InstanceRole).value<AgentInstance>();
    setupRestart(instance);
}

void AgentConfiguration::restartIdentifier(const QString &resourceIdentifier)
{
    auto instance = Akonadi::AgentManager::self()->instance(resourceIdentifier);
    setupRestart(instance);
}

void AgentConfiguration::setupRestart(Akonadi::AgentInstance instance)
{
    if (instance.isValid()) {
        instance.restart();
    }
}

void AgentConfiguration::remove(int index)
{
    Q_ASSERT(m_runningAgents != nullptr);

    auto instance = m_runningAgents->data(m_runningAgents->index(index, 0), AgentInstanceModel::InstanceRole).value<AgentInstance>();
    setupRemove(instance);
}

void AgentConfiguration::removeIdentifier(const QString &resourceIdentifier)
{
    auto instance = Akonadi::AgentManager::self()->instance(resourceIdentifier);
    setupRemove(instance);
}

void AgentConfiguration::setupRemove(const Akonadi::AgentInstance &instance)
{
    if (instance.isValid()) {
        Akonadi::AgentManager::self()->removeInstance(instance);
    }
}

void AgentConfiguration::processInstanceProgressChanged(const Akonadi::AgentInstance &instance)
{
    const QVariantMap instanceData = {
        {QStringLiteral("instanceId"), instance.identifier()},
        {QStringLiteral("progress"), instance.progress()}, // Not very reliable so beware
        {QStringLiteral("status"), instance.status()},
    };

    Q_EMIT agentProgressChanged(instanceData);
}

KalendarApplication::Mode AgentConfiguration::mode() const
{
    return m_mode;
}

void AgentConfiguration::setMode(KalendarApplication::Mode mode)
{
    if (mode == m_mode) {
        return;
    }
    m_mode = mode;
    Q_EMIT modeChanged();

    if (m_runningAgents) {
        delete m_runningAgents;
        m_runningAgents = nullptr;
        Q_EMIT runningAgentsChanged();
    }

    if (m_availableAgents) {
        delete m_availableAgents;
        m_availableAgents = nullptr;
        Q_EMIT availableAgentsChanged();
    }
}
