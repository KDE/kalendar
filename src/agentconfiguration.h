// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <Akonadi/AgentFilterProxyModel>
#include <Akonadi/AgentInstance>
#include <QObject>
#include <akonadi_version.h>

class AgentConfiguration : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Akonadi::AgentFilterProxyModel *availableAgents READ availableAgents CONSTANT)
    Q_PROPERTY(Akonadi::AgentFilterProxyModel *runningAgents READ runningAgents CONSTANT)
public:
    AgentConfiguration(QObject *parent = nullptr);
    ~AgentConfiguration() override;

    Akonadi::AgentFilterProxyModel *availableAgents();
    Akonadi::AgentFilterProxyModel *runningAgents();

    Q_INVOKABLE void createNew(int index);
    Q_INVOKABLE void edit(int index);
    Q_INVOKABLE void editIdentifier(QString resourceIdentifier);
    Q_INVOKABLE void remove(int index);
    Q_INVOKABLE void removeIdentifier(QString resourceIdentifier);
    Q_INVOKABLE void restart(int index);
    Q_INVOKABLE void restartIdentifier(QString resourceIdentifier);

private:
    void setupEdit(Akonadi::AgentInstance instance);
    void setupRemove(Akonadi::AgentInstance instance);
    void setupRestart(Akonadi::AgentInstance instance);

    Akonadi::AgentFilterProxyModel *m_runningAgents;
    Akonadi::AgentFilterProxyModel *m_availableAgents;
};
