// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "incidenceoccurrencemodel.h"
#include <QAbstractItemModel>
#include <QList>
#include <QSharedPointer>
#include <QTimer>
#include <kalendarconfig.h>

namespace KCalendarCore
{
class Incidence;
}

/**
 * Each toplevel index represents a week.
 * The "incidences" roles provides a list of lists, where each list represents a visual line,
 * containing a number of events to display.
 */
class MultiDayIncidenceModel : public QAbstractListModel
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

    enum Roles {
        Incidences = IncidenceOccurrenceModel::LastRole,
        PeriodStartDate,
    };

    explicit MultiDayIncidenceModel(QObject *parent = nullptr);
    ~MultiDayIncidenceModel() override = default;

    int rowCount(const QModelIndex &parent) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    IncidenceOccurrenceModel *model();
    void setModel(IncidenceOccurrenceModel *model);
    int periodLength() const;
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

private Q_SLOTS:
    void resetLayoutLines();
    void slotSourceDataChanged(const QModelIndex &upperLeft, const QModelIndex &bottomRight);

private:
    QList<QModelIndex> sortedIncidencesFromSourceModel(const QDate &rowStart) const;
    QVariantList layoutLines(const QDate &rowStart) const;

    QTimer mRefreshTimer;
    IncidenceOccurrenceModel *mSourceModel{nullptr};
    QVector<QVariantList> m_laidOutLines;
    int mPeriodLength = 7;
    MultiDayIncidenceModel::Filters m_filters;
    KalendarConfig *m_config = nullptr;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(MultiDayIncidenceModel::Filters)
