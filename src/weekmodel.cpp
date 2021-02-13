// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "weekmodel.h"
#include "monthmodel.h"
#include <qmath.h>
#include <QDebug>

QDebug operator<<(QDebug debug, const Position &pos)
{
    QDebugStateSaver saver(debug);
    debug.nospace() << "Position(" << pos.pos << ", " << pos.size << ")";
    return debug;
}


WeekModel::WeekModel(MonthModel *monthModel)
    : QAbstractListModel(monthModel)
    , m_monthModel(monthModel)
{
    connect(this, &WeekModel::startChanged, this, &WeekModel::fetchEvents);
}

WeekModel::~WeekModel()
{
}

void WeekModel::fetchEvents()
{
    if (m_eventsInWeek.empty() && m_monthModel->calendar()) {
        // fetch events for the given week
        const QDate end = m_start.addDays(m_weekLength);
        m_eventsInWeek = Calendar::sortEvents(m_monthModel->calendar()->events(m_start, end),
                                              EventSortField::EventSortStartDate,
                                              SortDirection::SortDirectionAscending
                                             );
        qDebug() << m_monthModel->calendar()->events() << m_start;
        
        // Contains all the event in the specific 2 hour block;
        constexpr const int blockSize = 2.0;
        QList<QList<Event::Ptr>> eventBlocks;
        for (int i = 0; i < 24 * m_weekLength / blockSize; i++) {
            // fill it
            eventBlocks.append(QList<Event::Ptr>());
        }
        // put stuff in eventBlocks
        const QDateTime periodStart = m_start.startOfDay();
        for (const auto &event : qAsConst(m_eventsInWeek)) {
            const QDateTime eventStart = event->dtStart();
            const auto fromStart = qMax(0ll, periodStart.secsTo(eventStart) / 60 / 60 / blockSize); // block of two hours
            const auto length = qCeil(qMax(0.0, eventStart.secsTo(event->dtEnd()) / 60.0 / 60.0 / blockSize));
            Q_ASSERT(length > 0);
            for (int i = 0; i < length; i++) {
                eventBlocks[fromStart + i].append(event);
            }
        }
        
        // Get the position of each event
        QList<QSet<QString>> groups;
        
        for (const auto &block : qAsConst(eventBlocks)) {
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
                                groups.append({ event->uid() });
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
                    groups.append({ event->uid() });
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
    }
    
    qDebug() << m_eventsInWeek << m_positions;
    
}

QVariant WeekModel::data(const QModelIndex &index, int role) const
{
    const auto &event = m_eventsInWeek[index.row()];
    
    switch (role) {
        case Day:
            return m_start.daysTo(event->dtStart().date());
        case Hour:
            return event->dtStart().time().hour();
        case Minute:
            // for anchoring margin we need a percent.
            return event->dtStart().time().minute() / 60; 
        case Lenght:
            return event->dtStart().secsTo(event->dtEnd()) / 60.0 / 60.0;
        case AllDay:
            return event->allDay();
        // TODO handling of event at the same time
    }
    return {};
}

int WeekModel::rowCount(const QModelIndex &parent) const
{
    return m_eventsInWeek.count();
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

void WeekModel::setStart(const QDate& start)
{
    if (m_start == start) {
        return;
    }

    m_start = start;
    Q_EMIT startChanged();
}
