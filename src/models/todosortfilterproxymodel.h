// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once
#include "kalendarconfig.h"
#include <Akonadi/Calendar/ETMCalendar>
#include <Akonadi/Calendar/IncidenceChanger>
#include <CalendarSupport/KCalPrefs>
#include <CalendarSupport/Utils>
#include <EventViews/IncidenceTreeModel>
#include <EventViews/TodoModel>
#include <KSharedConfig>
#include <QSortFilterProxyModel>
#include <QTimer>
#include <models/extratodomodel.h>

class TodoSortFilterProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(Akonadi::IncidenceChanger *incidenceChanger READ incidenceChanger WRITE setIncidenceChanger NOTIFY incidenceChangerChanged)
    Q_PROPERTY(Akonadi::ETMCalendar *calendar READ calendar WRITE setCalendar NOTIFY calendarChanged)
    Q_PROPERTY(QVariantMap filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(int showCompleted READ showCompleted WRITE setShowCompleted NOTIFY showCompletedChanged)
    Q_PROPERTY(int sortBy READ sortBy WRITE setSortBy NOTIFY sortByChanged)
    Q_PROPERTY(bool sortAscending READ sortAscending WRITE setSortAscending NOTIFY sortAscendingChanged)

public:
    enum BaseTodoModelColumns {
        SummaryColumn = TodoModel::SummaryColumn,
        PriorityColumn = TodoModel::PriorityColumn,
        PercentColumn = TodoModel::PercentColumn,
        StartDateColumn = TodoModel::StartDateColumn,
        DueDateColumn = TodoModel::DueDateColumn,
        CategoriesColumn = TodoModel::CategoriesColumn,
        DescriptionColumn = TodoModel::DescriptionColumn,
        CalendarColumn = TodoModel::CalendarColumn,
    };
    Q_ENUM(BaseTodoModelColumns);

    enum ExtraTodoModelColumns {
        StartTimeColumn = TodoModel::ColumnCount,
        EndTimeColumn,
        PriorityIntColumn,
    };
    Q_ENUM(ExtraTodoModelColumns);

    enum ShowComplete {
        ShowAll = 0,
        ShowCompleteOnly,
        ShowIncompleteOnly,
    };
    Q_ENUM(ShowComplete);

    TodoSortFilterProxyModel(QObject *parent = nullptr);
    ~TodoSortFilterProxyModel() override = default;

    bool filterAcceptsRow(int row, const QModelIndex &sourceParent) const override;
    bool filterAcceptsRowCheck(int row, const QModelIndex &sourceParent) const;
    bool hasAcceptedChildren(int row, const QModelIndex &sourceParent) const;

    Akonadi::ETMCalendar *calendar();
    void setCalendar(Akonadi::ETMCalendar *calendar);
    Akonadi::IncidenceChanger *incidenceChanger();
    void setIncidenceChanger(Akonadi::IncidenceChanger *changer);
    void setColorCache(QHash<QString, QColor> colorCache);

    int showCompleted();
    void setShowCompleted(int showCompleted);
    QVariantMap filter();
    void setFilter(const QVariantMap &filter);

    int sortBy();
    void setSortBy(int sortBy);
    bool sortAscending();
    void setSortAscending(bool sortAscending);

    Q_INVOKABLE void sortTodoModel(int sort, bool ascending);
    Q_INVOKABLE void filterTodoName(QString name, int showCompleted = ShowAll);

Q_SIGNALS:
    void incidenceChangerChanged();
    void calendarChanged();
    void filterChanged();
    void showCompletedChanged();
    void sortByChanged();
    void sortAscendingChanged();
    void badData();

protected:
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;

private:
    int compareStartDates(const QModelIndex &left, const QModelIndex &right) const;
    int compareDueDates(const QModelIndex &left, const QModelIndex &right) const;
    int compareCompletedDates(const QModelIndex &left, const QModelIndex &right) const;
    int comparePriorities(const QModelIndex &left, const QModelIndex &right) const;
    int compareCompletion(const QModelIndex &left, const QModelIndex &right) const;

    ExtraTodoModel *m_extraTodoModel = nullptr;
    int m_showCompleted = ShowComplete::ShowAll;
    int m_showCompletedStore; // For when searches happen
    QVariantMap m_filter;
    int m_sortColumn = EndTimeColumn;
    bool m_sortAscending = false;
    QTimer mRefreshTimer;
    KalendarConfig *m_config;
};
