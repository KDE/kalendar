// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QAbstractItemModel>
#include <QCalendar>
#include <KCalendarCore/Calendar>
#include <QDebugStateSaver> 
#include <QDebug>

class MonthModel;

using namespace KCalendarCore;

struct Position
{
    int pos;
    int size;
};

QDebug operator<<(QDebug debug, const Position &pos);

/**
 * Model for viewing a week or a single day view.
 */
class WeekModel : public QAbstractItemModel
{
    Q_OBJECT
    Q_PROPERTY(int weekLength READ weekLength WRITE setWeekLength NOTIFY weekLengthChanged)
    Q_PROPERTY(QDate start READ start WRITE setStart NOTIFY startChanged)

public:
    enum Roles {
        Day = Qt::UserRole,
        Hour, /// Used for anchoring, 0 to 24
        Minute, /// anchor margin
        Lenght,
        AllDay,
        Summary,
        TableIndex
    };

public:
    explicit WeekModel(MonthModel *monthModel = nullptr);
    ~WeekModel();
    
    int weekLength() const;
    void setWeekLength(int weekLength);
    QDate start() const;
    void setStart(const QDate& start);

    // QAbstractListModel overrides
    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;
    int rowCount(const QModelIndex &parent) const override;
    int columnCount(const QModelIndex &parent) const override;
    QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const override;
    QModelIndex parent(const QModelIndex &index) const override;
    bool hasChildren(const QModelIndex &parent = QModelIndex()) const override;
    
Q_SIGNALS:
    void weekLengthChanged();
    void startChanged();

private:
    void fetchEvents();
    
    int m_weekLength;
    QDate m_start;
    MonthModel *m_monthModel;
    QVector<Event::Ptr> m_eventsInWeek;
    QHash<QString, Position> m_positions;
    QList<QList<Event::Ptr>> m_eventBlocks;
};
