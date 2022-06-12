// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "incidenceoccurrencemodel.h"
#include "qbitarray.h"
#include <QAbstractItemModel>
#include <QDateTime>
#include <QList>
#include <QSharedPointer>
#include <QTimer>
#include <kalendarconfig.h>

namespace KCalendarCore
{
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
    Q_PROPERTY(QVector<int> dateRepresentativeIndices READ dateRepresentativeIndices NOTIFY dateRepresentativeIndicesChanged)
    Q_PROPERTY(int numHiddenDays READ numHiddenDays NOTIFY numHiddenDaysChanged)

public:
    enum Filter {
        NoAllDay = 0x1,
        NoMultiDay = 0x2,
    };
    Q_DECLARE_FLAGS(Filters, Filter)
    Q_FLAGS(Filters)
    Q_ENUM(Filter)

    enum Roles {
        Incidences = IncidenceOccurrenceModel::LastRole,
        PeriodStartDateTime,
    };

    explicit HourlyIncidenceModel(QObject *parent = nullptr);
    ~HourlyIncidenceModel() override = default;

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

    // We often use indexes in the QML HourlyView to decide things such as dates in the delegates.
    // When we have hidden dates, we need to provide an adjusted index that takes into account what
    // the index would have naturally been if certain dates weren't hidden.
    Q_INVOKABLE int dateAdjustedIndex(int index, const QDateTime &rowStartDate = {}) const;
    QVector<int> dateRepresentativeIndices() const;
    int numHiddenDays() const;

Q_SIGNALS:
    void periodLengthChanged();
    void filtersChanged();
    void modelChanged();
    void dateRepresentativeIndicesChanged();
    void numHiddenDaysChanged();

private:
    void updateShownDays();
    QList<QModelIndex> sortedIncidencesFromSourceModel(const QDateTime &rowStart) const;
    QVariantList layoutLines(const QDateTime &rowStart) const;

    QLocale m_locale;
    QVector<int> m_dateRepresentativeIndices;
    QTimer mRefreshTimer;
    IncidenceOccurrenceModel *mSourceModel{nullptr};
    int mPeriodLength{15}; // In minutes
    QBitArray m_hiddenSpaces = QBitArray(7); // TODO: Use a more flexible way of doing this
    int m_numHiddenSpaces = 0;
    HourlyIncidenceModel::Filters m_filters;
    KalendarConfig *m_config = nullptr;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(HourlyIncidenceModel::Filters)
