// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QAbstractListModel>
#include <QCalendar>
#include <QDate>
#include <QLocale>
#include <memory>

/// Month model exposing month days and events to a QML view.
class MonthModel : public QAbstractListModel
{
    Q_OBJECT
    /// The year number of the month.
    Q_PROPERTY(int year READ year WRITE setYear NOTIFY yearChanged)
    /// The month number of the month.
    Q_PROPERTY(int month READ month WRITE setMonth NOTIFY monthChanged)
    /// The translated week days.
    Q_PROPERTY(QStringList weekDays READ weekDays CONSTANT)
    /// Set the selected date.
    Q_PROPERTY(QDate selected READ selected WRITE setSelected NOTIFY selectedChanged)
public:
    enum Roles {
        // Day roles
        DayNumber = Qt::UserRole, ///< Day numbers, usually from 1 to 31.
        SameMonth, ///< True iff this day is in the same month as the one displayed.
        Date, ///< Date of the day.
        IsSelected, ///< Date is equal the selected date.
        IsToday ///< Date is today.
    };

public:
    explicit MonthModel(QObject *parent = nullptr);
    ~MonthModel() override;

    int year() const;
    void setYear(int year);
    int month() const;
    void setMonth(int month);
    QDate selected() const;
    void setSelected(const QDate &selected);

    QStringList weekDays() const;

    /// Go to the next month.
    Q_INVOKABLE void next();
    /// Go to the previous month.
    Q_INVOKABLE void previous();
    /// Go to the currentDate.
    Q_INVOKABLE void goToday();

    // QAbstractItemModel overrides
    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;
    int rowCount(const QModelIndex &parent) const override;

Q_SIGNALS:
    void yearChanged();
    void monthChanged();
    void selectedChanged();

private:
    class Private;
    QLocale m_locale;
    std::unique_ptr<Private> d;
};
