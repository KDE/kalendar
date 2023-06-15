// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "datetimestate.h"
#include <QDebug>

DateTimeState::DateTimeState(QObject *parent)
    : QObject(parent)
    , m_selectedDate(QDate::currentDate())
    , m_currentDate(QDate::currentDate())
{
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

void DateTimeState::addDays(int days)
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

void DateTimeState::setSelectedDay(int day)
{
    m_selectedDate.setDate(m_currentDate.year(), m_currentDate.month(), day);
    Q_EMIT selectedDateChanged();
}

void DateTimeState::setSelectedMonth(int month)
{
    m_selectedDate.setDate(m_currentDate.year(), month, m_currentDate.day());
    Q_EMIT selectedDateChanged();
}

void DateTimeState::setSelectedYear(int year)
{
    m_selectedDate.setDate(year, m_currentDate.month(), m_currentDate.day());
    Q_EMIT selectedDateChanged();
}
