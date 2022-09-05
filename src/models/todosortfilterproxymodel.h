// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>
#include <Akonadi/ETMCalendar>
#include <CalendarSupport/KCalPrefs>
#include <Akonadi/CalendarUtils>
#include <Akonadi/IncidenceTreeModel>
#include <EventViews/TodoModel>
#include <KConfigWatcher>
#include <KFormat>
#include <KSharedConfig>
#include <QSortFilterProxyModel>

class Filter;

class TodoSortFilterProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(Akonadi::IncidenceChanger *incidenceChanger READ incidenceChanger WRITE setIncidenceChanger NOTIFY incidenceChangerChanged)
    Q_PROPERTY(Akonadi::ETMCalendar::Ptr calendar READ calendar WRITE setCalendar NOTIFY calendarChanged)
    Q_PROPERTY(Filter *filterMap READ filterMap WRITE setFilterMap NOTIFY filterMapChanged)
    Q_PROPERTY(int showCompleted READ showCompleted WRITE setShowCompleted NOTIFY showCompletedChanged)
    Q_PROPERTY(int sortBy READ sortBy WRITE setSortBy NOTIFY sortByChanged)
    Q_PROPERTY(bool sortAscending READ sortAscending WRITE setSortAscending NOTIFY sortAscendingChanged)
    Q_PROPERTY(bool showCompletedSubtodosInIncomplete READ showCompletedSubtodosInIncomplete WRITE setShowCompletedSubtodosInIncomplete NOTIFY
                   showCompletedSubtodosInIncompleteChanged)

public:
    enum Roles { // Remember to update roles in todosortfilterproxymodel
        StartTimeRole = TodoModel::CalendarRole + 1,
        EndTimeRole,
        LocationRole,
        AllDayRole,
        CompletedRole,
        PriorityRole,
        ColorRole,
        CollectionIdRole,
        DurationStringRole,
        RecursRole,
        IsOverdueRole,
        IncidenceIdRole,
        IncidenceTypeRole,
        IncidenceTypeStrRole,
        IncidenceTypeIconRole,
        IncidencePtrRole,
        TagsRole,
        ItemRole,
        CategoriesRole,
        CategoriesDisplayRole,
        TreeDepthRole,
        TopMostParentSummary, // These three here are used to help us conserve the proper sections
        TopMostParentDueDate, // in the Kirigami TreeListView, which otherwise will create new
        TopMostParentPriority // sections for subtasks
    };
    Q_ENUM(Roles)

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
    Q_ENUM(BaseTodoModelColumns)

    enum ShowComplete {
        ShowAll = 0,
        ShowCompleteOnly,
        ShowIncompleteOnly,
    };
    Q_ENUM(ShowComplete)

    explicit TodoSortFilterProxyModel(QObject *parent = nullptr);
    ~TodoSortFilterProxyModel() override;

    int columnCount(const QModelIndex &parent) const override;
    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    bool filterAcceptsRow(int row, const QModelIndex &sourceParent) const override;
    bool filterAcceptsRowCheck(int row, const QModelIndex &sourceParent) const;
    bool hasAcceptedChildren(int row, const QModelIndex &sourceParent) const;

    Akonadi::ETMCalendar::Ptr calendar();
    void setCalendar(Akonadi::ETMCalendar::Ptr &calendar);
    Akonadi::IncidenceChanger *incidenceChanger();
    void setIncidenceChanger(Akonadi::IncidenceChanger *changer);

    int showCompleted() const;
    void setShowCompleted(int showCompleted);
    Filter *filterMap() const;
    void setFilterMap(Filter *filterMap);

    int sortBy() const;
    void setSortBy(int sortBy);
    bool sortAscending() const;
    void setSortAscending(bool sortAscending);
    bool showCompletedSubtodosInIncomplete() const;
    void setShowCompletedSubtodosInIncomplete(bool showCompletedSubtodosInIncomplete);

    void sortTodoModel();
    Q_INVOKABLE void filterTodoName(QString name, int showCompleted = ShowAll);

Q_SIGNALS:
    void calendarChanged();
    void filterMapAboutToChange();
    void filterMapChanged();
    void showCompletedChanged();
    void sortByChanged();
    void sortAscendingChanged();
    void badData();
    void showCompletedSubtodosInIncompleteChanged();
    void incidenceChangerChanged();

protected:
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;

    QHash<QString, QColor> colorCache();
    void setColorCache(QHash<QString, QColor> colorCache);
    void loadColors();

private:
    int compareStartDates(const QModelIndex &left, const QModelIndex &right) const;
    int compareDueDates(const QModelIndex &left, const QModelIndex &right) const;
    int compareCompletedDates(const QModelIndex &left, const QModelIndex &right) const;
    int comparePriorities(const QModelIndex &left, const QModelIndex &right) const;
    int compareCompletion(const QModelIndex &left, const QModelIndex &right) const;

    Akonadi::ETMCalendar::Ptr m_calendar;
    Akonadi::IncidenceTreeModel *m_todoTreeModel = nullptr;
    TodoModel *m_baseTodoModel = nullptr;
    Akonadi::IncidenceChanger *m_lastSetChanger = nullptr;
    QHash<QString, QColor> m_colors;
    KConfigWatcher::Ptr m_colorWatcher;
    int m_showCompleted = ShowComplete::ShowAll;
    int m_showCompletedStore; // For when searches happen
    Filter *m_filterMap = nullptr;
    int m_sortColumn = DueDateColumn;
    bool m_sortAscending = false;
    bool m_showCompletedSubtodosInIncomplete = true;
    KFormat m_format;
};
