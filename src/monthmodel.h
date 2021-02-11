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
class MonthModel : public QAbstractItemModel
{
    Q_OBJECT
    Q_PROPERTY(int year READ year WRITE setYear NOTIFY yearChanged)
    Q_PROPERTY(int month READ month WRITE setMonth NOTIFY monthChanged)
    Q_PROPERTY(QString monthText READ monthText NOTIFY monthTextChanged)
    /// The calendar we are displaying, this will extract events and other items from the calendar.
    Q_PROPERTY(QSharedPointer<Calendar> calendar READ calendar WRITE setCalendar NOTIFY calendarChanged)

public:
    enum Roles {
        // Day roles
        Row = Qt::UserRole,
        Column,
        DayNumber,
        SameMonth,
        Events,
        EventDate,
        HasChildren,
        
        // Event roles
        Summary,
        Location,
        IsEnd,
        IsBegin,
        IsVisible,
        Prefix
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
    
    // QAbstractItemModel overrides
    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;
    int rowCount(const QModelIndex& parent) const override;
    int columnCount(const QModelIndex& parent) const override;
    QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const override;
    QModelIndex parent(const QModelIndex &index) const override;
    bool hasChildren(const QModelIndex &parent = QModelIndex()) const override;
    
private Q_SLOTS:
    void refreshGridPosition();
    
Q_SIGNALS:
    void yearChanged();
    void monthChanged();
    void calendarChanged();
    void monthTextChanged();
    void eventPositionChanged();
    void shouldRefresh();
    
private:
    int m_year;
    int m_month;
    QCalendar m_calendar;
    Calendar::Ptr m_coreCalendar;
    QHash<int, QHash<int, Event::Ptr>> m_eventPosition; // list from days to position to event
};
