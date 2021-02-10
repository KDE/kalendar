// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QAbstractItemModel>
#include <QCalendar>
#include <KCalendarCore/Calendar>

using namespace KCalendarCore;

/**
 * Month model for the month view.
 */
class MonthModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int year READ year WRITE setYear NOTIFY yearChanged)
    Q_PROPERTY(int month READ month WRITE setMonth NOTIFY monthChanged)
    Q_PROPERTY(QString monthText READ monthText NOTIFY monthTextChanged)
    /// The calendar we are displaying, this will extract events and other items from the calendar.
    Q_PROPERTY(QSharedPointer<Calendar> calendar READ calendar WRITE setCalendar NOTIFY calendarChanged)

public:
    enum Roles {
        Row = Qt::UserRole,
        Column,
        DayNumber,
        SameMonth,
        Events,
        Date,
        HasChildren,
    };

public:
    explicit MonthModel(QObject *parent = nullptr);
    ~MonthModel();
    
    int year() const;
    void setYear(int year);
    int month() const;
    QString monthText() const;
    void setMonth(int month);
    Calendar::Ptr calendar();
    void setCalendar(Calendar::Ptr calendar);
    
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    
    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;
    int rowCount(const QModelIndex& parent) const override;
    
Q_SIGNALS:
    void yearChanged();
    void monthChanged();
    void calendarChanged();
    void monthTextChanged();
    
private:
    int m_year;
    int m_month;
    QCalendar m_calendar;
    Calendar::Ptr m_coreCalendar;
};
