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
#include <QQmlParserStatus>
#include <QSharedPointer>
#include <QTimer>

namespace KCalendarCore
{
class Incidence;
}

/**
 * Each toplevel index represents a week.
 * The "incidences" roles provides a list of lists, where each list represents a visual line,
 * containing a number of events to display.
 */
class MultiDayIncidenceModel : public QAbstractListModel, public QQmlParserStatus
{
    Q_OBJECT
    Q_PROPERTY(int periodLength READ periodLength WRITE setPeriodLength NOTIFY periodLengthChanged)
    Q_PROPERTY(MultiDayIncidenceModel::Filters filters READ filters WRITE setFilters NOTIFY filtersChanged)
    Q_PROPERTY(int incidenceCount READ incidenceCount NOTIFY incidenceCountChanged)
    Q_PROPERTY(IncidenceOccurrenceModel *model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(bool showTodos READ showTodos WRITE setShowTodos NOTIFY showTodosChanged)
    Q_PROPERTY(bool showSubTodos READ showSubTodos WRITE setShowSubTodos NOTIFY showSubTodosChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)

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
        IncidencesRole = IncidenceOccurrenceModel::LastRole,
        PeriodStartDateRole,
    };

    explicit MultiDayIncidenceModel(QObject *parent = nullptr);
    ~MultiDayIncidenceModel() override = default;

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    IncidenceOccurrenceModel *model() const;
    int periodLength() const;
    MultiDayIncidenceModel::Filters filters() const;
    bool showTodos() const;
    bool showSubTodos() const;
    int incidenceCount() const;
    bool incidencePassesFilter(const QModelIndex &idx) const;
    bool active() const;
    void setActive(const bool active);

    void classBegin() override;
    void componentComplete() override;

Q_SIGNALS:
    void periodLengthChanged();
    void filtersChanged();
    void incidenceCountChanged();
    void modelChanged();
    void showTodosChanged();
    void showSubTodosChanged();
    void activeChanged();

public Q_SLOTS:
    void setModel(IncidenceOccurrenceModel *model);
    void setPeriodLength(int periodLength);
    void setFilters(MultiDayIncidenceModel::Filters filters);
    void setShowTodos(const bool showTodos);
    void setShowSubTodos(const bool showSubTodos);

private Q_SLOTS:
    void slotSourceDataChanged(const QModelIndex &upperLeft, const QModelIndex &bottomRight);

private:
    QList<QModelIndex> sortedIncidencesFromSourceModel(const QDate &rowStart) const;
    QVariantList layoutLines(const QDate &rowStart) const;
    void scheduleReset();

    QSet<int> m_linesToUpdate;
    QTimer m_refreshTimer;
    IncidenceOccurrenceModel *mSourceModel{nullptr};
    int mPeriodLength = 7;
    MultiDayIncidenceModel::Filters m_filters;
    bool m_showTodos = true;
    bool m_showSubTodos = true;
    bool m_active = true;
    bool m_initialized = false;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(MultiDayIncidenceModel::Filters)
