/*
  SPDX-FileCopyrightText: 2008 Thomas Thrainer <tom_t@gmx.at>
  SPDX-FileCopyrightText: 2012 Sérgio Martins <iamsergio@gmail.com>

  SPDX-License-Identifier: GPL-2.0-or-later WITH Qt-Commercial-exception-1.0
*/

#pragma once

#include "todomodel.h"

#include <Akonadi/Calendar/ETMCalendar>
#include <Item>

#include <QModelIndex>
#include <QString>

namespace Akonadi
{
class IncidenceChanger;
}

class TodoModel::Private : public QObject
{
    Q_OBJECT
public:
    Private(const EventViews::PrefsPtr &preferences, TodoModel *qq);

    // TODO: O(N) complexity, see if the profiler complains about this
    Akonadi::Item findItemByUid(const QString &uid, const QModelIndex &parent) const;

public:
    Akonadi::ETMCalendar::Ptr m_calendar;
    Akonadi::IncidenceChanger *m_changer = nullptr;

    // For adjusting persistent indexes
    QList<QPersistentModelIndex> m_layoutChangePersistentIndexes;
    QModelIndexList m_persistentIndexes;
    QList<int> m_columns;
    EventViews::PrefsPtr m_preferences;

private Q_SLOTS:
    void onDataChanged(const QModelIndex &begin, const QModelIndex &end);
    void onHeaderDataChanged(Qt::Orientation orientation, int first, int last);

    void onRowsAboutToBeInserted(const QModelIndex &parent, int begin, int end);
    void onRowsInserted(const QModelIndex &parent, int begin, int end);
    void onRowsAboutToBeRemoved(const QModelIndex &parent, int begin, int end);
    void onRowsRemoved(const QModelIndex &parent, int begin, int end);
    void onRowsAboutToBeMoved(const QModelIndex &sourceParent, int sourceStart, int sourceEnd, const QModelIndex &destinationParent, int destinationRow);
    void onRowsMoved(const QModelIndex &, int, int, const QModelIndex &, int);

    void onModelAboutToBeReset();
    void onModelReset();
    void onLayoutAboutToBeChanged();
    void onLayoutChanged();

private:
    TodoModel *const q;
};

