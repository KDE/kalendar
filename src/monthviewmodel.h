// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QAbstractItemModel>
#include <QCalendar>
#include <QDateTime>
#include <QLocale>


class MonthViewModel : public QAbstractListModel
{
    Q_OBJECT
    // Amount of dates to add each time the model adds more dates
    Q_PROPERTY(int datesToAdd READ datesToAdd WRITE setDatesToAdd NOTIFY datesToAddChanged)

public:
    enum Roles {
        StartDateRole = Qt::UserRole + 1,
        FirstDayOfMonthRole,
        SelectedMonthRole,
        SelectedYearRole
    };
    Q_ENUM(Roles);

    explicit MonthViewModel(QObject *parent = nullptr);
    ~MonthViewModel() = default;

    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;
    Q_INVOKABLE void addDates(bool atEnd, QDate startFrom = QDate());

    int datesToAdd() const;
    void setDatesToAdd(int datesToAdd);

Q_SIGNALS:
    void datesToAddChanged();

private:
    QVector<QDate> m_startDates;
    QVector<QDate> m_firstDayOfMonthDates;
    QLocale m_locale;
    int m_datesToAdd = 10;
};
