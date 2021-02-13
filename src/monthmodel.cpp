// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "monthmodel.h"
#include <QDate>
#include <QDebug>

MonthModel::MonthModel(QObject *parent)
    : QAbstractItemModel(parent)
    , m_calendar()
{
    connect(this, &MonthModel::shouldRefresh, this, &MonthModel::refreshGridPosition);
}

MonthModel::~MonthModel()
{
}

void MonthModel::refreshGridPosition()
{
    if (!m_coreCalendar) {
        return;
    }
    const QDate begin = data(index(0, 0), Roles::EventDate).toDate(); 
    const QDate end = data(index(41, 0), Roles::EventDate).toDate(); 
    const auto events = Calendar::sortEvents(m_coreCalendar->events(begin, end),
                                             EventSortField::EventSortStartDate,
                                             SortDirection::SortDirectionAscending
                                            ); // get all events
    QHash<int, int> eventInDays;
    
    for (const auto &event : events) {
        const auto dateEnd = event->dtEnd().date();
        const auto dateStart = event->dtStart().date();
        const int index = begin.daysTo(dateStart);
        int position = 0;
        
        if (m_eventPosition.contains(index)) {
            // find the next free slot in the first entry
            while (m_eventPosition[index].contains(position)) {
                position++;
            }
        }
        for (QDate date = dateStart; date.daysTo(dateEnd) != -1; date = date.addDays(1)) {
            const int index = begin.daysTo(date);
            // put the event in the slot
            if (!m_eventPosition.contains(index)) {
                m_eventPosition[index] = {};
            }
            m_eventPosition[index][position] = event;
        }
    }
    Q_EMIT dataChanged(index(0, 0), index(41, 0));
    for (int i = 0; i < 41; i++) {
        beginRemoveRows(index(i, 0), 0, 9999);
        endRemoveRows();
        qDebug() << rowCount(index(i, 0));
        beginInsertRows(index(i, 0), 0, rowCount(index(i, 0)) - 1);
        endInsertRows();
    }
}

int MonthModel::year() const
{
    return m_year;
}

void MonthModel::setYear(int year)
{
    if (m_year == year) {
        return;
    }
    m_year = year;
    Q_EMIT yearChanged();
    Q_EMIT shouldRefresh();
}

int MonthModel::month() const
{
    return m_month;
}

void MonthModel::setMonth(int month)
{
    if (m_month == month) {
        return;
    }
    m_month = month;
    Q_EMIT monthChanged();
    Q_EMIT monthTextChanged();
    Q_EMIT shouldRefresh();
}

void MonthModel::setCalendar(Calendar::Ptr calendar)
{
    if (calendar == m_coreCalendar) {
        return;
    }
    m_coreCalendar = calendar;
    Q_EMIT calendarChanged();
    Q_EMIT shouldRefresh();
}

Calendar::Ptr MonthModel::calendar()
{
    return m_coreCalendar;
}

QString MonthModel::monthText() const
{
    return m_calendar.monthName(QLocale(), m_month);
}

void MonthModel::previous()
{
    if (m_month == 1) {
        setYear(m_year - 1);
        setMonth(m_calendar.monthsInYear(m_year));
    } else {
        setMonth(m_month - 1);
    }
}


void MonthModel::next()
{
    if (m_calendar.monthsInYear(m_year) <= m_month) {
        setMonth(1);
        setYear(m_year + 1);
    } else {
        setMonth(m_month + 1);
    }
}

QVariant MonthModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return {};
    }
    
    const int row = index.row();
    
    if (!index.parent().isValid()) {
        // Fetch days in month
        const int prefix = m_calendar.dayOfWeek(QDate(m_year, m_month, 1));
        
        // get the number of days in previous month
        const int daysInPreviousMonth = m_calendar.daysInMonth(m_month > 1 ? m_month - 1 : m_calendar.monthsInYear(m_year - 1),
                                                            m_month > 1 ? m_year : m_year - 1);
        
        switch (role) {
            case Qt::DisplayRole:
            case DayNumber:
            case EventDate:
            case Events: {
                int day = -1;
                int month = m_month;
                int year = m_year;
                const int daysInMonth = m_calendar.daysInMonth(m_month, m_year);
                if (row >= prefix && row - prefix < daysInMonth) {
                    // This month
                    day = row - prefix + 1;
                } else if (row - prefix >= daysInMonth) {
                    // Next month
                    day = row - daysInMonth - prefix + 1;
                    month = m_calendar.monthsInYear(m_year) > m_month ? 1 : m_month + 1;
                    year = m_calendar.monthsInYear(m_year) > m_month ? m_year +1 : m_year;
                } else {
                    // Previous month
                    day = daysInPreviousMonth - prefix + row + 1;
                    month = m_month > 1 ? m_month - 1 : m_calendar.monthsInYear(m_year - 1);
                    year =  m_month > 1 ? m_year : m_year - 1;
                }
                
                if (role == DayNumber || role == Qt::DisplayRole) {
                    return day;
                }
                const QDate date(year, month, day);
                if (role == EventDate) {
                    return date;
                }
                // role == Events
                const auto events = m_coreCalendar->events(date, date);
                return QVariant::fromValue(events);
            }
            case SameMonth: {
                const int daysInMonth = m_calendar.daysInMonth(m_month, m_year);
                return row >= prefix && row - prefix < daysInMonth;
            }
        }
    } else {
        // Fetch events in specific day.
        const auto &events = m_eventPosition[index.parent().row()];
        const auto date = data(index.parent(), Roles::EventDate).toDate();
        int counter = 0;
        int i = 0;
        int prefix = 0;
        while (counter <= row) {
            if (counter < row || !events.contains(i)) {
                if (!events.contains(i)) {
                    prefix++;
                }
                i++;
            }
            if (events.contains(i)) {
                counter++;
                if (counter < row) {
                    prefix = 0;
                }
            }
        }
        const auto event = events[i];
        switch (role) {
            case Qt::DisplayRole:
            case Roles::Summary:
                return event->summary();
            case Roles::Location:
                return event->location();
            case Roles::IsBegin:
                return !event->isMultiDay() || date == event->dtStart().date();
            case Roles::IsEnd:
                return !event->isMultiDay() || date == event->dtEnd().date();
            case Roles::Prefix:
                return prefix;
        }
    }
    return {};
}

int MonthModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        const auto events = data(parent, Roles::Events).value<QVector<Event::Ptr>>();
        return events.count();
    }
    return 42; // Display 6 weeks with each 7 days
}

int MonthModel::columnCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return 1;
}


bool MonthModel::hasChildren(const QModelIndex& parent) const
{
    if (parent.isValid()) {
        return false;
    }
    const auto events = data(parent, Roles::Events).value<QVector<Event::Ptr>>();
    return !events.isEmpty();
}


QHash<int, QByteArray> MonthModel::roleNames() const
{
    return {
        {Qt::DisplayRole, QByteArrayLiteral("display")},
        // Day roles
        {Roles::DayNumber, QByteArrayLiteral("dayNumber")},
        {Roles::SameMonth, QByteArrayLiteral("sameMonth")},
        {Roles::Events, QByteArrayLiteral("eventList")},
        {Roles::EventDate, QByteArrayLiteral("eventDate")},
        // Event roles
        {Roles::Summary, QByteArrayLiteral("summary")},
        {Roles::Location, QByteArrayLiteral("location")},
        {Roles::IsBegin, QByteArrayLiteral("isBegin")},
        {Roles::IsEnd, QByteArrayLiteral("isEnd")},
        {Roles::Prefix, QByteArrayLiteral("prefix")}
    };
}

QModelIndex MonthModel::index(int row, int column, const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return createIndex(row, column, (intptr_t)parent.row());
    }
    return createIndex(row, column, nullptr);
}

QModelIndex MonthModel::parent(const QModelIndex &child) const
{
    if (child.internalId()) {
        return createIndex(child.internalId(), 0, nullptr);
    }
    return QModelIndex();
}
