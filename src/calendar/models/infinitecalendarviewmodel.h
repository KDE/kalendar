// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "hourlyincidencemodel.h"
#include "multidayincidencemodel.h"
#include <Akonadi/ETMCalendar>
#include <QLocale>

class InfiniteCalendarViewModel : public QAbstractListModel
{
    Q_OBJECT
    // Amount of dates to add each time the model adds more dates
    Q_PROPERTY(int datesToAdd READ datesToAdd WRITE setDatesToAdd NOTIFY datesToAddChanged)
    Q_PROPERTY(int scale READ scale WRITE setScale NOTIFY scaleChanged)
    Q_PROPERTY(QStringList hourlyViewLocalisedHourLabels MEMBER m_hourlyViewLocalisedHourLabels CONSTANT)

public:
    // The decade scale is designed to be used in a 4x3 grid, so shows 12 years at a time
    enum Scale { DayScale, ThreeDayScale, WeekScale, MonthScale, YearScale, DecadeScale };
    Q_ENUM(Scale)

    enum Roles {
        StartDateRole = Qt::UserRole + 1,
        FirstDayOfMonthRole,
        SelectedMonthRole,
        SelectedYearRole,
    };
    Q_ENUM(Roles)

    explicit InfiniteCalendarViewModel(QObject *parent = nullptr);
    ~InfiniteCalendarViewModel() override = default;

    void setup();
    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    Q_INVOKABLE int moveToDate(const QDate &selectedDate, const QDate &currentDate, const int currentIndex);
    Q_INVOKABLE void addDates(bool atEnd, const QDate startFrom = QDate());
    void addDayDates(bool atEnd, const QDate &startFrom, int amount = 1);
    void addWeekDates(bool atEnd, const QDate &startFrom);
    void addMonthDates(bool atEnd, const QDate &startFrom);
    void addYearDates(bool atEnd, const QDate &startFrom);
    void addDecadeDates(bool atEnd, const QDate &startFrom);

    int datesToAdd() const;
    void setDatesToAdd(int datesToAdd);

    int scale() const;
    void setScale(int scale);

Q_SIGNALS:
    void datesToAddChanged();
    void scaleChanged();

private:
    QVector<QDate> m_startDates;
    QVector<QDate> m_firstDayOfMonthDates;
    QStringList m_hourlyViewLocalisedHourLabels;
    QLocale m_locale;
    int m_datesToAdd = 10;
    int m_scale = MonthScale;
};
