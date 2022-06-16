// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "incidenceoccurrencemodel.h"
#include "kalendar_debug.h"
#include <Akonadi/EntityTreeModel>
#include <QDebug>
#include <QMetaEnum>
#include <cmath>
#include <models/infinitecalendarviewmodel.h>

InfiniteCalendarViewModel::InfiniteCalendarViewModel(QObject *parent)
    : QAbstractListModel(parent)
{
    setup();
}

void InfiniteCalendarViewModel::setup()
{
    const QDate today = QDate::currentDate();
    QTime time;

    if (!m_hourlyViewLocalisedHourLabels.length()) {
        m_hourlyViewLocalisedHourLabels.clear();
        for (int i = 1; i < 24; i++) {
            time.setHMS(i, 0, 0);
            m_hourlyViewLocalisedHourLabels.append(QLocale::system().toString(time, QLocale::NarrowFormat));
        }
    }

    switch (m_scale) {
    case DayScale: {
        QDate firstDay = today;
        firstDay = firstDay.addDays(m_datesToAdd / 2);

        addDayDates(true, firstDay);
        break;
    }
    case ThreeDayScale: {
        QDate firstDay = today;
        firstDay = firstDay.addDays((-m_datesToAdd * 3) / 2);

        addDayDates(true, firstDay, 3);
        break;
    }
    case WeekScale: {
        QDate firstDay = today.addDays(-today.dayOfWeek() + m_locale.firstDayOfWeek());
        // We create dates before and after where our view will start from (which is today)
        firstDay = firstDay.addDays((-m_datesToAdd * 7) / 2);

        addWeekDates(true, firstDay);
        break;
    }
    case MonthScale: {
        QDate firstDay(today.year(), today.month(), 1);
        firstDay = firstDay.addMonths(-m_datesToAdd / 2);

        addMonthDates(true, firstDay);
        break;
    }
    case YearScale: {
        QDate firstDay(today.year(), today.month(), 1);
        firstDay = firstDay.addYears(-m_datesToAdd / 2);

        addYearDates(true, firstDay);
        break;
    }
    case DecadeScale: {
        const int firstYear = ((floor(today.year() / 10)) * 10) - 1; // E.g. For 2020 have view start at 2019...
        QDate firstDay(firstYear, today.month(), 1);
        firstDay = firstDay.addYears(((-m_datesToAdd * 12) / 2) + 10); // 3 * 4 grid so 12 years, end at 2030, and align for mid index to be current decade

        addDecadeDates(true, firstDay);
        break;
    }
    }
}

QVariant InfiniteCalendarViewModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }

    const QDate startDate = m_startDates[idx.row()];

    if (m_scale == MonthScale && role != StartDateRole) {
        const QDate firstDay = m_firstDayOfMonthDates[idx.row()];

        switch (role) {
        case FirstDayOfMonthRole:
            return firstDay.startOfDay();
        case SelectedMonthRole:
            return firstDay.month();
        case SelectedYearRole:
            return firstDay.year();
        default:
            qCWarning(KALENDAR_LOG) << "Unknown role for startdate:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return {};
        }
    }

    switch (role) {
    case StartDateRole:
        return startDate.startOfDay();
    case SelectedMonthRole:
        return startDate.month();
    case SelectedYearRole:
        return startDate.year();
    default:
        qCWarning(KALENDAR_LOG) << "Unknown role for startdate:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return {};
    }
}

int InfiniteCalendarViewModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_startDates.length();
}

QHash<int, QByteArray> InfiniteCalendarViewModel::roleNames() const
{
    return {
        {StartDateRole, QByteArrayLiteral("startDate")},
        {FirstDayOfMonthRole, QByteArrayLiteral("firstDay")},
        {SelectedMonthRole, QByteArrayLiteral("selectedMonth")},
        {SelectedYearRole, QByteArrayLiteral("selectedYear")},
    };
}

void InfiniteCalendarViewModel::addDates(bool atEnd, const QDate startFrom)
{
    switch (m_scale) {
    case DayScale:
        addDayDates(atEnd, startFrom);
        break;
    case ThreeDayScale:
        addDayDates(atEnd, startFrom, 3);
        break;
    case WeekScale:
        addWeekDates(atEnd, startFrom);
        break;
    case MonthScale:
        addMonthDates(atEnd, startFrom);
        break;
    case YearScale:
        addYearDates(atEnd, startFrom);
        break;
    case DecadeScale:
        addDecadeDates(atEnd, startFrom);
        break;
    }
}

void InfiniteCalendarViewModel::addDayDates(bool atEnd, const QDate &startFrom, int amount)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        QDate startDate = startFrom.isValid() && i == 0 ? startFrom : atEnd ? m_startDates[rowCount() - 1].addDays(amount) : m_startDates[0].addDays(-amount);

        if (atEnd) {
            m_startDates.append(startDate);
        } else {
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

void InfiniteCalendarViewModel::addWeekDates(bool atEnd, const QDate &startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        QDate startDate = startFrom.isValid() && i == 0 ? startFrom : atEnd ? m_startDates[rowCount() - 1].addDays(7) : m_startDates[0].addDays(-7);

        if (startDate.dayOfWeek() != m_locale.firstDayOfWeek()) {
            startDate = startDate.addDays(-startDate.dayOfWeek() + m_locale.firstDayOfWeek());
        }

        if (atEnd) {
            m_startDates.append(startDate);
        } else {
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

void InfiniteCalendarViewModel::addMonthDates(bool atEnd, const QDate &startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        const QDate firstDay = startFrom.isValid() && i == 0 ? startFrom
            : atEnd                                          ? m_firstDayOfMonthDates[rowCount() - 1].addMonths(1)
                                                             : m_firstDayOfMonthDates[0].addMonths(-1);
        QDate startDate = firstDay;

        startDate = startDate.addDays(-startDate.dayOfWeek() + m_locale.firstDayOfWeek());
        if (startDate >= firstDay) {
            startDate = startDate.addDays(-7);
        }

        if (atEnd) {
            m_firstDayOfMonthDates.append(firstDay);
            m_startDates.append(startDate);
        } else {
            m_firstDayOfMonthDates.insert(0, firstDay);
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

void InfiniteCalendarViewModel::addYearDates(bool atEnd, const QDate &startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        QDate startDate = startFrom.isValid() && i == 0 ? startFrom : atEnd ? m_startDates[rowCount() - 1].addYears(1) : m_startDates[0].addYears(-1);

        if (atEnd) {
            m_startDates.append(startDate);
        } else {
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

void InfiniteCalendarViewModel::addDecadeDates(bool atEnd, const QDate &startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        QDate startDate = startFrom.isValid() && i == 0 ? startFrom : atEnd ? m_startDates[rowCount() - 1].addYears(10) : m_startDates[0].addYears(-10);

        if (atEnd) {
            m_startDates.append(startDate);
        } else {
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

int InfiniteCalendarViewModel::datesToAdd() const
{
    return m_datesToAdd;
}

void InfiniteCalendarViewModel::setDatesToAdd(int datesToAdd)
{
    m_datesToAdd = datesToAdd;
    Q_EMIT datesToAddChanged();
}

int InfiniteCalendarViewModel::scale()
{
    return m_scale;
}

void InfiniteCalendarViewModel::setScale(int scale)
{
    beginResetModel();

    m_startDates.clear();
    m_firstDayOfMonthDates.clear();

    m_scale = scale;
    setup();
    Q_EMIT scaleChanged();

    endResetModel();
}
