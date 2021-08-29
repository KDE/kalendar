// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QMetaEnum>
#include <QDebug>
#include <monthviewmodel.h>

MonthViewModel::MonthViewModel(QObject* parent)
    : QAbstractListModel(parent)
{
    const QDate today = QDate::currentDate();
    QDate firstDay(today.year(), today.month(), 1);
    // We create dates before and after where our view will start from (which is today)
    firstDay = firstDay.addMonths(-m_datesToAdd / 2);

    addDates(true, firstDay);
}

QVariant MonthViewModel::data(const QModelIndex& idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }

    const QDate startDate = m_startDates[idx.row()];
    const QDate firstDay = m_firstDayOfMonthDates[idx.row()];

    switch(role) {
        case StartDateRole:
            return startDate.startOfDay();
        case FirstDayOfMonthRole:
            return firstDay.startOfDay();
        case SelectedMonthRole:
            return firstDay.month();
        case SelectedYearRole:
            return firstDay.year();
        default:
            qWarning() << "Unknown role for startdate:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return {};
    }
}

int MonthViewModel::rowCount(const QModelIndex& parent) const
{
    return m_startDates.length();
}

QHash<int, QByteArray> MonthViewModel::roleNames() const
{
    return {
        { StartDateRole, QByteArrayLiteral("startDate") },
        { FirstDayOfMonthRole, QByteArrayLiteral("firstDay") },
        { SelectedMonthRole, QByteArrayLiteral("selectedMonth") },
        { SelectedYearRole, QByteArrayLiteral("selectedYear") }
    };
}

void MonthViewModel::addDates(bool atEnd, QDate startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for(int i = 0; i < m_datesToAdd; i++) {
        const QDate firstDay = startFrom.isValid() && i == 0 ? startFrom :
            atEnd ? m_firstDayOfMonthDates[rowCount() - 1].addMonths(1) : m_firstDayOfMonthDates[0].addMonths(-1);
        QDate startDate = firstDay;

        if(startDate.dayOfWeek() == m_locale.firstDayOfWeek()) {
            startDate = startDate.addDays(-7); // We want to slightly center the month in the grid
        } else {
            startDate = startDate.addDays(-startDate.dayOfWeek() + m_locale.firstDayOfWeek());
        }

        if(atEnd) {
            m_firstDayOfMonthDates.append(firstDay);
            m_startDates.append(startDate);
        } else {
            m_firstDayOfMonthDates.insert(0, firstDay);
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

int MonthViewModel::datesToAdd() const
{
    return m_datesToAdd;
}

void MonthViewModel::setDatesToAdd(int datesToAdd)
{
    m_datesToAdd = datesToAdd;
    Q_EMIT datesToAddChanged();
}
