// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QAbstractListModel>
#include <QObject>

#include <Akonadi/AgentFilterProxyModel>
#include <Akonadi/AgentInstance>
#include <Akonadi/AgentManager>

class MailAccounts : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Akonadi::AgentFilterProxyModel *runningMailAgents READ runningMailAgents NOTIFY runningMailAgentsChanged)

public:
    MailAccounts(QObject *parent = nullptr);

    Akonadi::AgentFilterProxyModel *runningMailAgents();

    Q_INVOKABLE void remove(int index);
    Q_INVOKABLE void openConfigWindow(int index);

Q_SIGNALS:
    void runningMailAgentsChanged();

private:
    Akonadi::AgentInstance instanceFromIndex(int index);

    Akonadi::AgentFilterProxyModel *m_runningMailAgents = nullptr;
};
