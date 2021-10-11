// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "incidenceoccurrencemodel.h"
#include <QAbstractItemModel>
#include <QDateTime>
#include <QList>
#include <QSet>
#include <QSharedPointer>
#include <QTimer>

namespace KCalendarCore
{
class MemoryCalendar;
class Incidence;
}

/**
 * Each toplevel index represents a week.
 * The "incidences" roles provides a list of lists, where each list represents a visual line,
 * containing a number of events to display.
 */
class MultiDayIncidenceModel : public QAbstractItemModel
{
    Q_OBJECT
    Q_PROPERTY(int periodLength READ periodLength WRITE setPeriodLength NOTIFY periodLengthChanged)
    Q_PROPERTY(MultiDayIncidenceModel::Filters filters READ filters WRITE setFilters NOTIFY filtersChanged)
    Q_PROPERTY(int incidenceCount READ incidenceCount NOTIFY incidenceCountChanged)
    Q_PROPERTY(IncidenceOccurrenceModel *model READ model WRITE setModel NOTIFY modelChanged)

public:
    enum Filter {
        AllDayOnly = 0x1,
        NoStartDateOnly = 0x2,
        MultiDayOnly = 0x3,
    };
    Q_DECLARE_FLAGS(Filters, Filter)
    Q_FLAGS(Filters)
    Q_ENUM(Filter)

    MultiDayIncidenceModel(QObject *parent = nullptr);
    ~MultiDayIncidenceModel() = default;

    QModelIndex index(int row, int column, const QModelIndex &parent = {}) const override;
    QModelIndex parent(const QModelIndex &index) const override;

    int rowCount(const QModelIndex &parent) const override;
    int columnCount(const QModelIndex &parent) const override;

    QVariant data(const QModelIndex &index, int role) const override;

    QHash<int, QByteArray> roleNames() const override;

    IncidenceOccurrenceModel *model();
    void setModel(IncidenceOccurrenceModel *model);
    int periodLength();
    void setPeriodLength(int periodLength);
    MultiDayIncidenceModel::Filters filters();
    void setFilters(MultiDayIncidenceModel::Filters filters);
    bool incidencePassesFilter(const QModelIndex &idx) const;
    Q_INVOKABLE int incidenceCount();

Q_SIGNALS:
    void periodLengthChanged();
    void filtersChanged();
    void incidenceCountChanged();
    void modelChanged();

protected:
    void setIncidenceCount(int incidenceCount);

private:
    QTimer mRefreshTimer;
    QList<QModelIndex> sortedIncidencesFromSourceModel(const QDate &rowStart) const;
    QVariantList layoutLines(const QDate &rowStart) const;
    IncidenceOccurrenceModel *mSourceModel{nullptr};
    int mPeriodLength{7};
    MultiDayIncidenceModel::Filters m_filters;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(MultiDayIncidenceModel::Filters)
