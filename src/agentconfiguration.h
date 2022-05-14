// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "kalendarapplication.h"
#include <Akonadi/AgentFilterProxyModel>
#include <Akonadi/AgentInstance>
#include <QObject>
#include <QTimer>

class AgentConfiguration : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Akonadi::AgentFilterProxyModel *availableAgents READ availableAgents NOTIFY availableAgentsChanged)
    Q_PROPERTY(Akonadi::AgentFilterProxyModel *runningAgents READ runningAgents NOTIFY runningAgentsChanged)
    Q_PROPERTY(KalendarApplication::Mode mode READ mode WRITE setMode NOTIFY modeChanged)
public:
    enum AgentStatuses {
        Idle = Akonadi::AgentInstance::Idle,
        Running = Akonadi::AgentInstance::Running,
        Broken = Akonadi::AgentInstance::Broken,
        NotConfigured = Akonadi::AgentInstance::NotConfigured,
    };
    Q_ENUM(AgentStatuses);

    explicit AgentConfiguration(QObject *parent = nullptr);
    ~AgentConfiguration() override;

    Akonadi::AgentFilterProxyModel *availableAgents();
    Akonadi::AgentFilterProxyModel *runningAgents();
    KalendarApplication::Mode mode() const;
    void setMode(KalendarApplication::Mode mode);

    Q_INVOKABLE void createNew(int index);
    Q_INVOKABLE void edit(int index);
    Q_INVOKABLE void editIdentifier(const QString &resourceIdentifier);
    Q_INVOKABLE void remove(int index);
    Q_INVOKABLE void removeIdentifier(const QString &resourceIdentifier);
    Q_INVOKABLE void restart(int index);
    Q_INVOKABLE void restartIdentifier(const QString &resourceIdentifier);

public Q_SLOTS:
    void processInstanceProgressChanged(const Akonadi::AgentInstance &instance);

Q_SIGNALS:
    void agentProgressChanged(const QVariantMap agentData);
    void modeChanged();
    void runningAgentsChanged();
    void availableAgentsChanged();

private:
    void setupEdit(Akonadi::AgentInstance instance);
    void setupRemove(const Akonadi::AgentInstance &instance);
    void setupRestart(Akonadi::AgentInstance instance);

    Akonadi::AgentFilterProxyModel *m_runningAgents = nullptr;
    Akonadi::AgentFilterProxyModel *m_availableAgents = nullptr;
    KalendarApplication::Mode m_mode;
};
