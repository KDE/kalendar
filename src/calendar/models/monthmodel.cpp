// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "monthmodel.h"
#include <QCalendar>

struct MonthModel::Private {
    int year;
    int month;
    QCalendar calendar = QCalendar();
    QDate selected;
};

MonthModel::MonthModel(QObject *parent)
    : QAbstractListModel(parent)
    , d(new MonthModel::Private())
{
    goToday();
    d->selected = QDate::currentDate();
}

MonthModel::~MonthModel() = default;

int MonthModel::year() const
{
    return d->year;
}

void MonthModel::setYear(int year)
{
    if (d->year == year) {
        return;
    }
    d->year = year;
    Q_EMIT yearChanged();
    Q_EMIT dataChanged(index(0, 0), index(41, 0));
    setSelected(QDate(year, d->selected.month(), qMin(d->selected.day(), d->calendar.daysInMonth(d->selected.month(), year))));
}

int MonthModel::month() const
{
    return d->month;
}

void MonthModel::setMonth(int month)
{
    if (d->month == month) {
        return;
    }
    d->month = month;
    Q_EMIT monthChanged();
    Q_EMIT dataChanged(index(0, 0), index(41, 0));
    setSelected(QDate(d->selected.year(), d->month, qMin(d->selected.day(), d->calendar.daysInMonth(d->month, d->selected.year()))));
}

QDate MonthModel::selected() const
{
    return d->selected;
}

void MonthModel::setSelected(const QDate &selected)
{
    if (d->selected == selected) {
        return;
    }
    d->selected = selected;
    Q_EMIT selectedChanged();
    Q_EMIT dataChanged(index(0, 0), index(41, 0), {Roles::IsSelected});
}

QStringList MonthModel::weekDays() const
{
    QLocale locale;
    QStringList daysName;
    for (int i = 0; i < 7; i++) {
        int day = locale.firstDayOfWeek() + i;
        if (day > 7) {
            day -= 7;
        }
        if (day == 7) {
            day = 0;
        }
        daysName.append(locale.standaloneDayName(day == 0 ? Qt::Sunday : day, QLocale::NarrowFormat));
    }
    return daysName;
}

void MonthModel::previous()
{
    if (d->month == 1) {
        setYear(d->year - 1);
        setMonth(d->calendar.monthsInYear(d->year) - 1);
    } else {
        setMonth(d->month - 1);
    }
}

void MonthModel::next()
{
    if (d->calendar.monthsInYear(d->year) == d->month) {
        setMonth(1);
        setYear(d->year + 1);
    } else {
        setMonth(d->month + 1);
    }
}

void MonthModel::goToday()
{
    const auto today = QDate::currentDate();
    setMonth(today.month());
    setYear(today.year());
}

QVariant MonthModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return {};
    }

    const int row = index.row();

    if (!index.parent().isValid()) {
        // Fetch days in month
        int prefix = d->calendar.dayOfWeek(QDate(d->year, d->month, 1)) - m_locale.firstDayOfWeek();

        if (prefix <= 1) {
            prefix += 7;
        } else if (prefix > 7) {
            prefix -= 7;
        }

        switch (role) {
        case Qt::DisplayRole:
        case DayNumber:
        case IsSelected:
        case IsToday:
        case Date: {
            int day = -1;
            int month = d->month;
            int year = d->year;
            const int daysInMonth = d->calendar.daysInMonth(d->month, d->year);
            if (row >= prefix && row - prefix < daysInMonth) {
                // This month
                day = row - prefix + 1;
            } else if (row - prefix >= daysInMonth) {
                // Next month
                month = d->calendar.monthsInYear(d->year) == d->month ? 1 : d->month + 1;
                year = d->calendar.monthsInYear(d->year) == d->month ? d->year + 1 : d->year;
                day = row - daysInMonth - prefix + 1;
            } else {
                // Previous month
                year = d->month > 1 ? d->year : d->year - 1;
                month = d->month > 1 ? d->month - 1 : d->calendar.monthsInYear(year);
                int daysInPreviousMonth = d->calendar.daysInMonth(month, year);
                day = daysInPreviousMonth - prefix + row + 1;
            }

            if (role == DayNumber || role == Qt::DisplayRole) {
                return day;
            }
            const QDate date(year, month, day);
            if (role == Date) {
                return date.startOfDay();
                // Ensure the date doesn't get mangled into a different date by QML date conversion
            }

            if (role == IsSelected) {
                return d->selected == date;
            }
            if (role == IsToday) {
                return date == QDate::currentDate();
            }
            return {};
        }
        case SameMonth: {
            const int daysInMonth = d->calendar.daysInMonth(d->month, d->year);
            return row >= prefix && row - prefix < daysInMonth;
        }
        }
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
        {Roles::Date, QByteArrayLiteral("date")},
        {Roles::IsSelected, QByteArrayLiteral("isSelected")},
        {Roles::IsToday, QByteArrayLiteral("isToday")},
    };
}
