// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QAbstractItemModel>
#include <QCalendar>
#include <QDateTime>
#include <QLocale>

class WeekViewModel : public QAbstractListModel
{
    Q_OBJECT
    // Amount of dates to add each time the model adds more dates
    Q_PROPERTY(int weeksToAdd READ weeksToAdd WRITE setWeeksToAdd NOTIFY weeksToAddChanged)

public:
    enum Roles {
        StartDateRole = Qt::UserRole + 1,
        FirstDayOfMonthRole,
        SelectedMonthRole,
        SelectedYearRole
    };
    Q_ENUM(Roles);

    explicit WeekViewModel(QObject *parent = nullptr);
    ~WeekViewModel() = default;

    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;
    Q_INVOKABLE void addDates(bool atEnd, const QDate &startFrom = QDate());

    int weeksToAdd() const;
    void setWeeksToAdd(int weeksToAdd);

Q_SIGNALS:
    void weeksToAddChanged();

private:
    QVector<QDate> m_startDates;
    QLocale m_locale;
    int m_weeksToAdd = 10;
    int m_daysToAdd = 70;
};

