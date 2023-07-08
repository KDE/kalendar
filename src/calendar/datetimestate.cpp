// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "datetimestate.h"
#include <QTimer>

using namespace std::chrono_literals;

DateTimeState::DateTimeState(QObject *parent)
    : QObject(parent)
    , m_selectedDate(QDate::currentDate())
    , m_currentDate(QDateTime::currentDateTime())
{
    auto timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, [this, timer] {
        m_currentDate = QDateTime::currentDateTime();
        Q_EMIT currentDateChanged();

        // Repeat timer
        timer->start(60 * 1000ms);
    });
    timer->start(60 * 1000ms);
}

void DateTimeState::selectPreviousMonth()
{
    m_selectedDate = m_selectedDate.addMonths(-1);
    Q_EMIT selectedDateChanged();
}

void DateTimeState::selectNextMonth()
{
    m_selectedDate = m_selectedDate.addMonths(1);
    Q_EMIT selectedDateChanged();
}

bool DateTimeState::isToday(const QDate &date) const
{
    return m_currentDate.date() == date;
}

void DateTimeState::addDays(const int days)
{
    m_selectedDate = m_selectedDate.addDays(days);
    Q_EMIT selectedDateChanged();
}

QDate DateTimeState::firstDayOfMonth() const
{
    QDate date = m_selectedDate;
    date.setDate(m_selectedDate.year(), m_selectedDate.month(), 1);
    return date;
}

QDate DateTimeState::firstDayOfWeek() const
{
    int dayOfWeek = m_selectedDate.dayOfWeek();
    return m_selectedDate.addDays(-dayOfWeek + 1);
}

void DateTimeState::resetTime()
{
    m_selectedDate = QDate::currentDate();
    Q_EMIT selectedDateChanged();
}

void DateTimeState::setSelectedYearMonthDay(const int year, const int month, const int day)
{
    m_selectedDate.setDate(year, month, day);
    Q_EMIT selectedDateChanged();
}

void DateTimeState::setSelectedDay(const int day)
{
    setSelectedYearMonthDay(m_selectedDate.year(), m_selectedDate.month(), day);
}

void DateTimeState::setSelectedMonth(const int month)
{
    setSelectedYearMonthDay(m_selectedDate.year(), month, m_selectedDate.day());
}

void DateTimeState::setSelectedYear(const int year)
{
    setSelectedYearMonthDay(year, m_selectedDate.month(), m_selectedDate.day());
}
