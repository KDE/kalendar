// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QMetaEnum>
#include <QDebug>
#include <weekviewmodel.h>

WeekViewModel::WeekViewModel(QObject* parent)
    : QAbstractListModel(parent)
{
    const QDate today = QDate::currentDate();
    QDate firstDay = today.addDays(-today.dayOfWeek() + m_locale.firstDayOfWeek());
    // We create dates before and after where our view will start from (which is today)
    firstDay = firstDay.addDays(-m_daysToAdd / 2);

    addDates(true, firstDay);
}

QVariant WeekViewModel::data(const QModelIndex& idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }

    const QDate startDate = m_startDates[idx.row()];

    switch(role) {
        case StartDateRole:
            return startDate.startOfDay();
        case SelectedMonthRole:
            return startDate.month();
        case SelectedYearRole:
            return startDate.year();
        default:
            qWarning() << "Unknown role for startdate:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return {};
    }
}

int WeekViewModel::rowCount(const QModelIndex& parent) const
{
    return m_startDates.length();
}

QHash<int, QByteArray> WeekViewModel::roleNames() const
{
    return {
        { StartDateRole, QByteArrayLiteral("startDate") },
        { SelectedMonthRole, QByteArrayLiteral("selectedMonth") },
        { SelectedYearRole, QByteArrayLiteral("selectedYear") }
    };
}

void WeekViewModel::addDates(bool atEnd, const QDate &startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_weeksToAdd - 1);

    for(int i = 0; i < m_weeksToAdd; i++) {
        QDate startDate = startFrom.isValid() && i == 0 ? startFrom :
            atEnd ? m_startDates[rowCount() - 1].addDays(7) : m_startDates[0].addDays(-7);

        if(startDate.dayOfWeek() != m_locale.firstDayOfWeek()) {
            startDate = startDate.addDays(-startDate.dayOfWeek() + m_locale.firstDayOfWeek());
        }

        if(atEnd) {
            m_startDates.append(startDate);
        } else {
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

int WeekViewModel::weeksToAdd() const
{
    return m_weeksToAdd;
}

void WeekViewModel::setWeeksToAdd(int weeksToAdd)
{
    m_weeksToAdd = weeksToAdd;
    m_daysToAdd = weeksToAdd * 7;
    Q_EMIT weeksToAddChanged();
}

