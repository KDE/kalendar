// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "eventsmodel.h"
#include <QDebug>

EventsModel::EventsModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

EventsModel::~EventsModel()
{
}

QVariantList EventsModel::events() const
{
    return m_events;
}

void EventsModel::setEvents(const QVariantList& events)
{
    if (events == m_events) {
        return;
    }
    m_events = events;
    Q_EMIT eventsChanged();
}

QDate EventsModel::date() const
{
    return m_date;
}

void EventsModel::setDate(const QDate& date)
{
    if (date == m_date) {
        return;
    }
    m_date = date;
    Q_EMIT dateChanged();
}



QVariant EventsModel::data(const QModelIndex &index, int role) const
{
    const auto event = m_events[index.row()].value<Event::Ptr>();
    switch (role) {
        case Qt::DisplayRole:
        case Roles::Summary:
            return event->summary();
        case Roles::Location:
            return event->location();
        default:
            return {};
    }
}

int EventsModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_events.count();
}


QHash<int, QByteArray> EventsModel::roleNames() const
{
    return {
        {Qt::DisplayRole, QByteArrayLiteral("display")},
        {Roles::Summary, QByteArrayLiteral("summary")},
        {Roles::Location, QByteArrayLiteral("location")},
    };
}
