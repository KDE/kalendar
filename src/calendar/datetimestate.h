// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QDateTime>
#include <QObject>
#include <qdatetime.h>

class DateTimeState : public QObject
{
    Q_OBJECT

    /// This property holds the current selected date by the user
    Q_PROPERTY(QDate selectedDate MEMBER m_selectedDate NOTIFY selectedDateChanged)

    /// This property holds the first day of the month selected by the user
    Q_PROPERTY(QDate firstDayOfMonth READ firstDayOfMonth NOTIFY selectedDateChanged)

    /// This property holds the first day of the week selected by the user
    Q_PROPERTY(QDate firstDayOfWeek READ firstDayOfWeek NOTIFY selectedDateChanged)

    Q_PROPERTY(QDate currentDate MEMBER m_currentDate NOTIFY currentDateChanged)

public:
    explicit DateTimeState(QObject *parent = nullptr);

    QDate firstDayOfMonth() const;
    QDate firstDayOfWeek() const;

    Q_INVOKABLE void setSelectedDay(int day);
    Q_INVOKABLE void setSelectedMonth(int month);
    Q_INVOKABLE void setSelectedYear(int year);
    Q_INVOKABLE void selectPreviousMonth();
    Q_INVOKABLE void selectNextMonth();

    /// Reset to current time
    Q_INVOKABLE void resetTime();

Q_SIGNALS:
    void selectedDateChanged();
    void currentDateChanged();

private:
    QDate m_selectedDate;
    QDate m_currentDate;
};
