// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "weekmodel.h"
#include "monthmodel.h"
#include <QDebug>
#include <qmath.h>

QDebug operator<<(QDebug debug, const Position &pos)
{
    QDebugStateSaver saver(debug);
    debug.nospace() << "Position(" << pos.pos << ", " << pos.size << ")";
    return debug;
}

WeekModel::WeekModel(MonthModel *monthModel)
    : QAbstractItemModel(monthModel)
    , m_monthModel(monthModel)
{
    connect(this, &WeekModel::startChanged, this, &WeekModel::fetchEvents);
}

WeekModel::~WeekModel()
{
}

constexpr const int blockSize = 4.0;

void WeekModel::fetchEvents()
{
    if (m_eventsInWeek.empty() && m_monthModel->calendar()) {
        // fetch events for the given week
        const QDate end = m_start.addDays(m_weekLength);
        m_eventsInWeek =
            Calendar::sortEvents(m_monthModel->calendar()->events(m_start, end), EventSortField::EventSortStartDate, SortDirection::SortDirectionAscending);
        qDebug() << m_monthModel->calendar()->events() << m_start;

        // Contains all the event in the specific 'blockSize' hour block;
        for (int i = 0; i < 24 * m_weekLength / (int)blockSize; i++) {
            // fill it
            m_eventBlocks.append(QList<Event::Ptr>());
        }
        qDebug() << "add Stuff";
        // put stuff in eventBlocks
        const QDateTime periodStart = m_start.startOfDay();
        for (const auto &event : qAsConst(m_eventsInWeek)) {
            const QDateTime eventStart = event->dtStart();
            const auto fromStart = qMax(0ll, periodStart.secsTo(eventStart) / 60 / 60 / blockSize); // block of two hours
            const auto length = qCeil(qMax(0.0, eventStart.secsTo(event->dtEnd()) / 60.0 / 60.0 / blockSize));
            Q_ASSERT(length > 0);
            for (int i = 0; i < length; i++) {
                const auto position = fromStart + i;
                m_eventBlocks[position].append(event);
            }
        }

        // Get the position of each event
        QList<QSet<QString>> groups;

        for (const auto &block : qAsConst(m_eventBlocks)) {
            for (const auto &event : qAsConst(block)) {
                if (event->allDay()) {
                    continue;
                }

                if (m_positions.contains(event->uid())) {
                    continue;
                }

                bool collided = false;
                for (const auto &otherEvent : qAsConst(block)) {
                    if (event == otherEvent) {
                        continue;
                    }
                    auto differenceStart = event->dtStart().secsTo(otherEvent->dtStart());
                    auto duration = event->dtStart().secsTo(event->dtEnd());
                    if (differenceStart < duration) {
                        // The two events collide
                        if (m_positions.contains(otherEvent->uid())) {
                            auto position = m_positions.value(otherEvent->uid());
                            position.pos++;
                            m_positions[event->uid()] = position;
                            bool groupFound = false;
                            for (auto &group : groups) {
                                if (group.contains(otherEvent->uid())) {
                                    group.insert(event->uid());
                                    groupFound = true;
                                }
                            }
                            if (!groupFound) {
                                groups.append({event->uid()});
                            }
                            collided = true;
                            break;
                        }
                    }
                }
                if (!collided) {
                    Position pos;
                    pos.pos = 0;
                    pos.size = 0;
                    m_positions[event->uid()] = pos;
                    groups.append({event->uid()});
                }
            }
        }

        // Update size now
        for (const auto &group : qAsConst(groups)) {
            for (const auto &event : group) {
                qDebug() << "size" << event << group.count();
                m_positions[event].size = group.count();
            }
        }

        for (int i = 0; i < (24 / blockSize) * m_weekLength; i++) {
            const auto row = i % (24 / blockSize);
            const auto column = i / (24 / blockSize);
            qDebug() << "Add" << i << row << column << m_eventBlocks[i].count();
            beginInsertRows(index(row, column), m_eventBlocks[i].count(), m_eventBlocks[i].count() + 1);
            endInsertRows();
            dataChanged(index(row, column), index(row, column), {Roles::Summary});
            for (auto j = 0; j < rowCount(index(row, column)); j++) {
                qDebug() << "summary" << data(index(row, column), Roles::Summary) << this;
            }
        }
    }

    qDebug() << m_eventsInWeek << m_positions;
}

QVariant WeekModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return {};
    }
    if (!index.parent().isValid()) {
        // Show grid of blockSize
        switch (role) {
        case TableIndex:
            return index;
        default:
            qDebug() << m_eventBlocks << index.column() * (24 / blockSize) + index.row();
            return m_eventBlocks[index.column() * (24 / blockSize) + index.row()].count();
        }
    } else {
        // Show events in block
        const auto parentRow = index.parent().row();
        const auto parentColumn = index.parent().column();

        qDebug() << parentRow << parentColumn << index.row() << m_eventBlocks << parentColumn * (24 / blockSize) + parentRow;
        const auto &events = m_eventBlocks[parentColumn * (24 / blockSize) + parentRow];
        if (events.count() <= index.row()) {
            qDebug() << rowCount(index) << " is buggy";
            return {};
        }
        qDebug() << rowCount(index);
        const auto event = events[index.row()];
        const auto secSinceStart = parentColumn * 24 * 60 * 60 + parentRow * 60 * 60 / blockSize;

        const auto blockStart = m_start.startOfDay().addSecs(secSinceStart);

        switch (role) {
        case Summary:
            return event->summary();
        case Minute:
            return (double)qMax(0ll, blockStart.secsTo(event->dtStart())) / 60.0 / 60.0 / (double)blockSize;
        case Lenght:
            return event->dtStart().secsTo(event->dtEnd()) / 60.0 / 60.0 / blockSize;
        case AllDay:
            return event->allDay();
            // TODO handling of event at the same time
        }
    }
    return {};
}

int WeekModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        qDebug() << "rowCount" << m_eventBlocks[parent.column() * (24 / blockSize) + parent.row()].count();
        return m_eventBlocks[parent.column() * (24 / blockSize) + parent.row()].count();
    }
    return 24 / blockSize;
}

int WeekModel::columnCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 1;
    }
    return m_weekLength;
}

int WeekModel::weekLength() const
{
    return m_weekLength;
}

void WeekModel::setWeekLength(int weekLength)
{
    if (m_weekLength == weekLength) {
        return;
    }

    m_weekLength = weekLength;
    Q_EMIT weekLengthChanged();
}

QDate WeekModel::start() const
{
    return m_start;
}

void WeekModel::setStart(const QDate &start)
{
    if (m_start == start) {
        return;
    }

    m_start = start;
    Q_EMIT startChanged();
}

QHash<int, QByteArray> WeekModel::roleNames() const
{
    return {
        {Qt::DisplayRole, QByteArrayLiteral("display")},
        {Roles::Summary, QByteArrayLiteral("summary")},
        {Roles::Day, QByteArrayLiteral("day")},
        {Roles::Hour, QByteArrayLiteral("hour")},
        {Roles::TableIndex, QByteArrayLiteral("tableIndex")},
    };
}

QModelIndex WeekModel::index(int row, int column, const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return createIndex(row, column, (intptr_t)parent.row());
    }
    return createIndex(row, column, nullptr);
}

QModelIndex WeekModel::parent(const QModelIndex &child) const
{
    if (child.internalId()) {
        return createIndex(child.internalId(), 0, nullptr);
    }
    return QModelIndex();
}

bool WeekModel::hasChildren(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return false;
    }
    return m_eventBlocks[parent.column() * (24 / blockSize) + parent.row()].count();
}
