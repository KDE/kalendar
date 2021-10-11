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
 * Each toplevel index represents a day.
 * The "incidences" roles provides a list of lists, where each list represents a visual line,
 * containing a number of events to display.
 */
class HourlyIncidenceModel : public QAbstractItemModel
{
    Q_OBJECT
    Q_PROPERTY(int periodLength READ periodLength WRITE setPeriodLength NOTIFY periodLengthChanged)
    Q_PROPERTY(HourlyIncidenceModel::Filters filters READ filters WRITE setFilters NOTIFY filtersChanged)
    Q_PROPERTY(IncidenceOccurrenceModel *model READ model WRITE setModel NOTIFY modelChanged)

public:
    enum Filter {
        NoAllDay = 0x1,
        NoMultiDay = 0x2,
    };
    Q_DECLARE_FLAGS(Filters, Filter)
    Q_FLAGS(Filters)
    Q_ENUM(Filter)

    HourlyIncidenceModel(QObject *parent = nullptr);
    ~HourlyIncidenceModel() = default;

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
    HourlyIncidenceModel::Filters filters();
    void setFilters(HourlyIncidenceModel::Filters filters);

Q_SIGNALS:
    void periodLengthChanged();
    void filtersChanged();
    void modelChanged();

private:
    QTimer mRefreshTimer;
    QList<QModelIndex> sortedIncidencesFromSourceModel(const QDateTime &rowStart) const;
    QVariantList layoutLines(const QDateTime &rowStart) const;
    IncidenceOccurrenceModel *mSourceModel{nullptr};
    int mPeriodLength{15};
    HourlyIncidenceModel::Filters m_filters;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(HourlyIncidenceModel::Filters)
