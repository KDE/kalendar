// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "incidenceoccurrencemodel.h"
#include "qbitarray.h"
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

    enum Roles {
        Incidences = IncidenceOccurrenceModel::LastRole,
        PeriodStartDate,
    };

    explicit MultiDayIncidenceModel(QObject *parent = nullptr);
    ~MultiDayIncidenceModel() override = default;

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
    enum LayoutIncidenceProcessResult { Proceed, Delay, Skip };

    struct ProcessedIncidenceLayout {
        LayoutIncidenceProcessResult result;
        int start;
        int duration;
        int end;
    };

    void updateShownDays();
    QList<QModelIndex> sortedIncidencesFromSourceModel(const QDate &rowStart) const;
    ProcessedIncidenceLayout layoutIncidenceProcess(const QModelIndex &index, const QBitArray takenSpaces, const QDate &rowStart) const;

    QTimer mRefreshTimer;
    QVariantList layoutLines(const QDate &rowStart) const;
    IncidenceOccurrenceModel *mSourceModel{nullptr};
    int mPeriodLength{7};
    QBitArray m_hiddenSpaces = QBitArray(7); // TODO: Use a more flexible way of doing this
    int m_numHiddenSpaces = 0;
    MultiDayIncidenceModel::Filters m_filters;
    KalendarConfig *m_config = nullptr;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(MultiDayIncidenceModel::Filters)
