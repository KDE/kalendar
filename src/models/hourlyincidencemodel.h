// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "incidenceoccurrencemodel.h"
#include <QAbstractItemModel>
#include <QDateTime>
#include <QList>
#include <QSharedPointer>
#include <QTimer>

namespace KCalendarCore
{
class Incidence;
}

/**
 * Each toplevel index represents a day.
 * The "incidences" roles provides a list of lists, where each list represents a visual line,
 * containing a number of events to display.
 */
class HourlyIncidenceModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int periodLength READ periodLength WRITE setPeriodLength NOTIFY periodLengthChanged)
    Q_PROPERTY(HourlyIncidenceModel::Filters filters READ filters WRITE setFilters NOTIFY filtersChanged)
    Q_PROPERTY(IncidenceOccurrenceModel *model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(bool showTodos READ showTodos WRITE setShowTodos NOTIFY showTodosChanged)
    Q_PROPERTY(bool showSubTodos READ showSubTodos WRITE setShowSubTodos NOTIFY showSubTodosChanged)

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
    int rowCount(const QModelIndex &parent) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    IncidenceOccurrenceModel *model() const;
    int periodLength() const;
    HourlyIncidenceModel::Filters filters() const;
    bool showTodos() const;
    bool showSubTodos() const;

Q_SIGNALS:
    void periodLengthChanged();
    void filtersChanged();
    void modelChanged();
    void showTodosChanged();
    void showSubTodosChanged();

public Q_SLOTS:
    void setModel(IncidenceOccurrenceModel *model);
    void setPeriodLength(int periodLength);
    void setFilters(HourlyIncidenceModel::Filters filters);
    void setShowTodos(const bool showTodos);
    void setShowSubTodos(const bool showSubTodos);

private Q_SLOTS:
    void resetLayoutLines();
    void slotSourceDataChanged(const QModelIndex &upperLeft, const QModelIndex &bottomRight);
    void scheduleLayoutLinesUpdates(const QModelIndex &sourceIndexParent, const int sourceFirstRow, const int sourceLastRow);
    void updateScheduledLayoutLines();

private:
    QList<QModelIndex> sortedIncidencesFromSourceModel(const QDateTime &rowStart) const;
    QVariantList layoutLines(const QDateTime &rowStart) const;

    QSet<int> m_linesToUpdate;
    QTimer mRefreshTimer;
    QTimer m_updateLinesTimer;
    IncidenceOccurrenceModel *mSourceModel{nullptr};
    QVector<QVariantList> m_laidOutLines;
    int mPeriodLength{15}; // In minutes
    HourlyIncidenceModel::Filters m_filters;
    bool m_showTodos = true;
    bool m_showSubTodos = true;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(HourlyIncidenceModel::Filters)
