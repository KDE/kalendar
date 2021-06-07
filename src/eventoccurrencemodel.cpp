// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "eventoccurrencemodel.h"

#include <QMetaEnum>

#include <KCalendarCore/OccurrenceIterator>
#include <KCalendarCore/MemoryCalendar>
#include <etmcalendar.h>
#include <AkonadiCore/CollectionColorAttribute>
#include <QRandomGenerator>

EventOccurrenceModel::EventOccurrenceModel(QObject *parent)
    : QAbstractItemModel(parent)
{
    mRefreshTimer.setSingleShot(true);
    QObject::connect(&mRefreshTimer, &QTimer::timeout, this, &EventOccurrenceModel::updateFromSource);
}

void EventOccurrenceModel::setStart(const QDate &start)
{
    if (start != mStart) {
        mStart = start;
        updateQuery();
        Q_EMIT startChanged();
    }
}

QDate EventOccurrenceModel::start() const
{
    return mStart;
}

void EventOccurrenceModel::setLength(int length)
{
    if (mLength == length) {
        return;
    }
    mLength = length;
    updateQuery();
    Q_EMIT lengthChanged();
}

int EventOccurrenceModel::length() const
{
    return mLength;
}

void EventOccurrenceModel::setFilter(const QVariantMap &filter)
{
    mFilter = filter;
    updateQuery();
    Q_EMIT filterChanged();
}

void EventOccurrenceModel::updateQuery()
{
    if (!m_coreCalendar) {
        return;
    }

    if (!mLength || !mStart.isValid()) {
        refreshView();
        return;
    }
    mEnd = mStart.addDays(mLength);

    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::dataChanged, this, &EventOccurrenceModel::refreshView);
    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::layoutChanged, this, &EventOccurrenceModel::refreshView);
    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::modelReset, this, &EventOccurrenceModel::refreshView);
    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::rowsInserted, this, &EventOccurrenceModel::refreshView);
    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::rowsMoved, this, &EventOccurrenceModel::refreshView);
    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::rowsRemoved, this, &EventOccurrenceModel::refreshView);

    refreshView();
}

void EventOccurrenceModel::refreshView()
{
    if (!mRefreshTimer.isActive()) {
        // Instant update, but then only refresh every 50ms max.
        updateFromSource();
        mRefreshTimer.start(50);
    }
}

void EventOccurrenceModel::updateFromSource()
{
    beginResetModel();

    m_events.clear();

    if (m_coreCalendar) {
        QMap<QByteArray, KCalendarCore::Event::Ptr> recurringEvents;
        QMultiMap<QByteArray, KCalendarCore::Event::Ptr> exceptions;

        const auto allEvents = Calendar::sortEvents(
            m_coreCalendar->events(mStart, mEnd),
            EventSortField::EventSortStartDate,
            SortDirection::SortDirectionAscending
        ); // get all events

        QMap<QByteArray, KCalendarCore::Event::Ptr> events;
        for (int i = 0; i < allEvents.count(); ++i) {
            auto &event = allEvents[i];
            //const bool skip = [&] {
            //    for (auto it = mFilter.constBegin(); it!= mFilter.constEnd(); it++) {
            //        if (event->getProperty(it.key().toLatin1()) != it.value()) {
            //            return true;
            //        }
            //    }
            //    return false;
            //}();
            //if (skip) {
            //    continue;
            //}
            //
            // Collect recurring events and add the rest immediately
            //if (event->recurs()) {
            //    recurringEvents.insert(event->uid().toLatin1(), event);
            //    events.insert(event->instanceIdentifier().toLatin1(), event);
            //} else if(event->recurrenceId().isValid()) {
            //    exceptions.insert(event->uid().toLatin1(), event);
            //    events.insert(event->instanceIdentifier().toLatin1(), event);
            //} else {
                if (event->dtStart().date() < mEnd && event->dtEnd().date() >= mStart) {
                    m_events.append(Occurrence {
                        event->dtStart(),
                        event->dtEnd(),
                        event,
                        getColor(event),
                        event->allDay()
                    });
                }
            //}

            auto item = m_coreCalendar->item(event);
            if (!item.isValid()) {
                continue;
            }
            auto collection = item.parentCollection();
            if (!collection.isValid()) {
                continue;
            }
            const QString id = QString::number(collection.id());
            if (m_colors.contains(id)) {
                continue;
            }
        }
        /*
        // process all recurring events and their exceptions.
        for (const auto &uid : recurringEvents.keys()) {
            KCalendarCore::MemoryCalendar calendar{QTimeZone::systemTimeZone()};
            calendar.addIncidence(recurringEvents.value(uid));
            for (const auto &event : exceptions.values(uid)) {
                calendar.addIncidence(event);
            }
            KCalendarCore::OccurrenceIterator occurrenceIterator{calendar, QDateTime{mStart, {0, 0, 0}}, QDateTime{mEnd, {12, 59, 59}}};
            while (occurrenceIterator.hasNext()) {
                occurrenceIterator.next();
                const auto incidence = occurrenceIterator.incidence();
                const auto event = events.value(incidence->instanceIdentifier().toLatin1());
                const auto start = occurrenceIterator.occurrenceStartDate();
                const auto end = incidence->endDateForStart(start);
                if (start.date() < mEnd && end.date() >= mStart) {
                    m_events.append(Occurrence {start, end, incidence, getColor(event), event->allDay() });
                }
            }
        }*/
    }

    endResetModel();
}

QModelIndex EventOccurrenceModel::index(int row, int column, const QModelIndex &parent) const
{
    if (!hasIndex(row, column, parent)) {
        return {};
    }

    if (!parent.isValid()) {
        return createIndex(row, column);
    }
    return {};
}

QModelIndex EventOccurrenceModel::parent(const QModelIndex &) const
{
    return {};
}

int EventOccurrenceModel::rowCount(const QModelIndex &parent) const
{
    if (!parent.isValid()) {
        return m_events.size();
    }
    return 0;
}

int EventOccurrenceModel::columnCount(const QModelIndex &) const
{
    return 1;
}

QColor EventOccurrenceModel::getColor(const KCalendarCore::Event::Ptr &event) const
{
    auto item = m_coreCalendar->item(event);
    if (!item.isValid()) {
        return {};
    }
    auto collection = item.parentCollection();
    if (!collection.isValid()) {
        return {};
    }
    const QString id = QString::number(collection.id());
    if (m_colors.contains(id)) {
        return m_colors[id];
    }
    if (collection.hasAttribute<Akonadi::CollectionColorAttribute>()) {
        const auto *colorAttr = collection.attribute<Akonadi::CollectionColorAttribute>();
        if (colorAttr && colorAttr->color().isValid()) {
            return colorAttr->color();
        }

    }
    return {}; // should not happen
}

QVariant EventOccurrenceModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }
    auto event = m_events.at(idx.row());
    auto icalEvent = event.event;
    switch (role) {
        case Summary:
            return icalEvent->summary();
        case Description:
            return icalEvent->description();
        case StartTime:
            return event.start;
        case EndTime:
            return event.end;
        case Color:
            return event.color;
        case AllDay:
            return event.allDay;
        case EventOccurrence:
            return QVariant::fromValue(event);
        default:
            qWarning() << "Unknown role for event:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return {};
    }
}
