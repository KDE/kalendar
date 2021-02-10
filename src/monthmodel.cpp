// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "monthmodel.h"
#include <QDate>
#include <QDebug>

MonthModel::MonthModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_calendar()
{
}

MonthModel::~MonthModel()
{
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
    Q_EMIT dataChanged(createIndex(0, 0, nullptr), createIndex(41, 0, nullptr));
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
    Q_EMIT dataChanged(createIndex(0, 0, nullptr), createIndex(41, 0, nullptr));
}

void MonthModel::setCalendar(Calendar::Ptr calendar)
{
    if (calendar == m_coreCalendar) {
        return;
    }
    m_coreCalendar = calendar;
    Q_EMIT calendarChanged();
    Q_EMIT dataChanged(createIndex(0, 0, nullptr), createIndex(41, 0, nullptr));
}

Calendar::Ptr MonthModel::calendar()
{
    return m_coreCalendar;
}

QString MonthModel::monthText() const
{
    qDebug() << m_calendar.monthName(QLocale(), m_month);
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
    const int row = index.row();
    // Fetch days in month
    
    const int prefix = m_calendar.dayOfWeek(QDate(m_year, m_month, 1));
    
    // get the number of days in previous month
    const int daysInPreviousMonth = m_calendar.daysInMonth(m_month > 1 ? m_month - 1 : m_calendar.monthsInYear(m_year - 1),
                                                        m_month > 1 ? m_year : m_year - 1);
    
    switch (role) {
        case Qt::DisplayRole:
        case Roles::DayNumber:
        case Roles::Date:
        case Roles::Events: {
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
            if (role == Date) {
                return date;
            }
            // role == Events
            const auto events = m_coreCalendar->events(date, date);
            qDebug() << "fetching events" << events;
            QVariantList e;
            for (const auto &event : events) {
                e.append(QVariant::fromValue(event));
            }
            return e;
        }
        case Roles::SameMonth: {
            const int daysInMonth = m_calendar.daysInMonth(m_month, m_year);
            return row >= prefix && row - prefix < daysInMonth;
        }
        default:
            return QVariant{};
    }
    return {};
}

int MonthModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return 42; // Display 6 weeks with each 7 days
}

QHash<int, QByteArray> MonthModel::roleNames() const
{
    return {
        {Qt::DisplayRole, QByteArrayLiteral("display")},
        {Roles::DayNumber, QByteArrayLiteral("dayNumber")},
        {Roles::SameMonth, QByteArrayLiteral("sameMonth")},
        {Roles::Events, QByteArrayLiteral("eventList")}
    };
}
