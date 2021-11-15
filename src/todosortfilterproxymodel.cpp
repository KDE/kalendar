// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <todosortfilterproxymodel.h>

TodoSortFilterProxyModel::TodoSortFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    m_extraTodoModel = new ExtraTodoModel;
    setSourceModel(m_extraTodoModel);
    setDynamicSortFilter(true);
    setSortCaseSensitivity(Qt::CaseInsensitive);
    setFilterCaseSensitivity(Qt::CaseInsensitive);

    mRefreshTimer.setSingleShot(true);

    auto sortTimer = [this] {
        if (!mRefreshTimer.isActive()) {
            mRefreshTimer.start(250);
        }
    };

    connect(&mRefreshTimer, &QTimer::timeout, this, [&]() {
        sortTodoModel(m_sortColumn, m_sortAscending);
    });

    connect(m_extraTodoModel, &KExtraColumnsProxyModel::dataChanged, this, sortTimer);
    connect(m_extraTodoModel, &KExtraColumnsProxyModel::rowsInserted, this, sortTimer);
    connect(m_extraTodoModel, &KExtraColumnsProxyModel::rowsRemoved, this, sortTimer);
    connect(m_extraTodoModel, &KExtraColumnsProxyModel::layoutChanged, this, sortTimer);
    connect(m_extraTodoModel, &KExtraColumnsProxyModel::rowsMoved, this, sortTimer);
}

bool TodoSortFilterProxyModel::filterAcceptsRow(int row, const QModelIndex &sourceParent) const
{
    if (filterAcceptsRowCheck(row, sourceParent)) {
        return true;
    }

    // Accept if any parent is accepted itself
    QModelIndex parent = sourceParent;
    while (parent.isValid()) {
        if (filterAcceptsRowCheck(parent.row(), parent.parent()))
            return true;
        parent = parent.parent();
    }

    // Accept if any child is accepted itself
    if (hasAcceptedChildren(row, sourceParent)) {
        return true;
    }

    return false;
}

bool TodoSortFilterProxyModel::filterAcceptsRowCheck(int row, const QModelIndex &sourceParent) const
{
    const QModelIndex sourceIndex = sourceModel()->index(row, 0, sourceParent);
    Q_ASSERT(sourceIndex.isValid());

    if (m_filter.empty()) {
        return QSortFilterProxyModel::filterAcceptsRow(row, sourceParent);
    }

    bool acceptRow = true;

    if (m_filter.contains(QLatin1String("collectionId")) && m_filter[QLatin1String("collectionId")].toInt() > -1) {
        acceptRow = acceptRow && sourceIndex.data(ExtraTodoModel::CollectionIdRole).toInt() == m_filter[QLatin1String("collectionId")].toInt();
    }

    switch (m_showCompleted) {
    case ShowComplete::ShowCompleteOnly:
        acceptRow = acceptRow && sourceIndex.data(ExtraTodoModel::CompletedRole).toBool();
        break;
    case ShowComplete::ShowIncompleteOnly:
        acceptRow = acceptRow && !sourceIndex.data(ExtraTodoModel::CompletedRole).toBool();
    case ShowComplete::ShowAll:
    default:
        break;
    }

    if (m_filter.contains(QLatin1String("tags")) && !m_filter[QLatin1String("tags")].toStringList().isEmpty()) {
        auto tags = m_filter[QLatin1String("tags")].toStringList();
        bool containsTag = false;
        for (const auto &tag : tags) {
            if (sourceIndex.data(ExtraTodoModel::CategoriesRole).toStringList().contains(tag)) {
                containsTag = true;
                break;
            }
        }
        acceptRow = acceptRow && containsTag;
    }

    return acceptRow ? QSortFilterProxyModel::filterAcceptsRow(row, sourceParent) : acceptRow;
}

bool TodoSortFilterProxyModel::hasAcceptedChildren(int row, const QModelIndex &sourceParent) const
{
    QModelIndex index = sourceModel()->index(row, 0, sourceParent);
    if (!index.isValid()) {
        return false;
    }

    int childCount = index.model()->rowCount(index);
    if (childCount == 0)
        return false;

    for (int i = 0; i < childCount; ++i) {
        if (filterAcceptsRowCheck(i, index))
            return true;

        if (hasAcceptedChildren(i, index))
            return true;
    }

    return false;
}

Akonadi::ETMCalendar *TodoSortFilterProxyModel::calendar()
{
    return m_extraTodoModel->calendar().get();
}

void TodoSortFilterProxyModel::setCalendar(Akonadi::ETMCalendar *calendar)
{
    Akonadi::ETMCalendar::Ptr calendarPtr(calendar);
    m_extraTodoModel->setCalendar(calendarPtr);
    Q_EMIT calendarChanged();
}

Akonadi::IncidenceChanger *TodoSortFilterProxyModel::incidenceChanger()
{
    return m_extraTodoModel->incidenceChanger();
}

void TodoSortFilterProxyModel::setIncidenceChanger(Akonadi::IncidenceChanger *changer)
{
    m_extraTodoModel->setIncidenceChanger(changer);
    Q_EMIT incidenceChangerChanged();
}

void TodoSortFilterProxyModel::setColorCache(QHash<QString, QColor> colorCache)
{
    m_extraTodoModel->setColorCache(colorCache);
}

int TodoSortFilterProxyModel::showCompleted()
{
    return m_showCompleted;
}

void TodoSortFilterProxyModel::setShowCompleted(int showCompleted)
{
    m_showCompleted = showCompleted;
    m_showCompletedStore = showCompleted; // For when we search
    invalidateFilter();
    Q_EMIT showCompletedChanged();
}

QVariantMap TodoSortFilterProxyModel::filter()
{
    return m_filter;
}

void TodoSortFilterProxyModel::setFilter(const QVariantMap &filter)
{
    Q_EMIT layoutAboutToBeChanged();

    m_filter = filter;

    invalidateFilter();

    Q_EMIT filterChanged();
    Q_EMIT layoutChanged();

    if (m_filter.contains(QLatin1String("name"))) {
        Q_EMIT layoutAboutToBeChanged();
        auto name = m_filter[QLatin1String("name")].toString();
        setFilterFixedString(name);
        invalidateFilter();
        Q_EMIT layoutChanged();
    }
}

void TodoSortFilterProxyModel::sortTodoModel(int column, bool ascending)
{
    Q_EMIT layoutAboutToBeChanged();

    auto order = ascending ? Qt::AscendingOrder : Qt::DescendingOrder;
    this->sort(column, order);

    Q_EMIT layoutChanged();
}

void TodoSortFilterProxyModel::filterTodoName(QString name, int showCompleted)
{
    Q_EMIT layoutAboutToBeChanged();
    setFilterFixedString(name);
    if (name.length() > 0) {
        m_showCompleted = showCompleted;
    } else {
        setShowCompleted(m_showCompletedStore);
    }
    invalidateFilter();
    Q_EMIT layoutChanged();
}

int TodoSortFilterProxyModel::compareStartDates(const QModelIndex &left, const QModelIndex &right) const
{
    Q_ASSERT(left.column() == TodoModel::StartDateColumn);
    Q_ASSERT(right.column() == TodoModel::StartDateColumn);

    // The start date column is a QString, so fetch the to-do.
    // We can't compare QStrings because it won't work if the format is MM/DD/YYYY
    const auto leftTodo = left.data(TodoModel::TodoPtrRole).value<KCalendarCore::Todo::Ptr>();
    const auto rightTodo = right.data(TodoModel::TodoPtrRole).value<KCalendarCore::Todo::Ptr>();

    if (!leftTodo || !rightTodo) {
        return 0;
    }

    const bool leftIsEmpty = !leftTodo->hasStartDate();
    const bool rightIsEmpty = !rightTodo->hasStartDate();

    if (leftIsEmpty != rightIsEmpty) { // One of them doesn't have a start date
        // For sorting, no date is considered a very big date
        return rightIsEmpty ? -1 : 1;
    } else if (!leftIsEmpty) { // Both have start dates
        const auto leftDateTime = leftTodo->dtStart();
        const auto rightDateTime = rightTodo->dtStart();

        if (leftDateTime == rightDateTime) {
            return 0;
        } else {
            return leftDateTime < rightDateTime ? -1 : 1;
        }
    } else { // Neither has a start date
        return 0;
    }
}

int TodoSortFilterProxyModel::compareCompletedDates(const QModelIndex &left, const QModelIndex &right) const
{
    Q_ASSERT(left.column() == TodoModel::CompletedDateColumn);
    Q_ASSERT(right.column() == TodoModel::CompletedDateColumn);

    const auto leftTodo = left.data(TodoModel::TodoPtrRole).value<KCalendarCore::Todo::Ptr>();
    const auto rightTodo = right.data(TodoModel::TodoPtrRole).value<KCalendarCore::Todo::Ptr>();

    if (!leftTodo || !rightTodo) {
        return 0;
    }

    const bool leftIsEmpty = !leftTodo->hasCompletedDate();
    const bool rightIsEmpty = !rightTodo->hasCompletedDate();

    if (leftIsEmpty != rightIsEmpty) { // One of them doesn't have a completed date.
        // For sorting, no date is considered a very big date.
        return rightIsEmpty ? -1 : 1;
    } else if (!leftIsEmpty) { // Both have completed dates.
        const auto leftDateTime = leftTodo->completed();
        const auto rightDateTime = rightTodo->completed();

        if (leftDateTime == rightDateTime) {
            return 0;
        } else {
            return leftDateTime < rightDateTime ? -1 : 1;
        }
    } else { // Neither has a completed date.
        return 0;
    }
}

/* -1 - less than
 *  0 - equal
 *  1 - bigger than
 */
int TodoSortFilterProxyModel::compareDueDates(const QModelIndex &left, const QModelIndex &right) const
{
    Q_ASSERT(left.column() == TodoModel::DueDateColumn);
    Q_ASSERT(right.column() == TodoModel::DueDateColumn);

    // The due date column is a QString, so fetch the to-do.
    // We can't compare QStrings because it won't work if the format is MM/DD/YYYY
    const auto leftTodo = left.data(TodoModel::TodoPtrRole).value<KCalendarCore::Todo::Ptr>();
    const auto rightTodo = right.data(TodoModel::TodoPtrRole).value<KCalendarCore::Todo::Ptr>();
    Q_ASSERT(leftTodo);
    Q_ASSERT(rightTodo);

    if (!leftTodo || !rightTodo) {
        return 0;
    }

    const bool leftIsEmpty = !leftTodo->hasDueDate();
    const bool rightIsEmpty = !rightTodo->hasDueDate();

    if (leftIsEmpty != rightIsEmpty) { // One of them doesn't have a due date
        // For sorting, no date is considered a very big date
        return rightIsEmpty ? -1 : 1;
    } else if (!leftIsEmpty) { // Both have due dates
        const auto leftDateTime = leftTodo->dtDue();
        const auto rightDateTime = rightTodo->dtDue();

        if (leftDateTime == rightDateTime) {
            return 0;
        } else {
            return leftDateTime < rightDateTime ? -1 : 1;
        }
    } else { // Neither has a due date
        return 0;
    }
}

/* -1 - less than
 *  0 - equal
 *  1 - bigger than
 */
int TodoSortFilterProxyModel::compareCompletion(const QModelIndex &left, const QModelIndex &right) const
{
    Q_ASSERT(left.column() == TodoModel::PercentColumn);
    Q_ASSERT(right.column() == TodoModel::PercentColumn);

    const int leftValue = sourceModel()->data(left).toInt();
    const int rightValue = sourceModel()->data(right).toInt();

    if (leftValue == 100 && rightValue == 100) {
        // Break ties with the completion date.
        const auto leftTodo = left.data(TodoModel::TodoPtrRole).value<KCalendarCore::Todo::Ptr>();
        const auto rightTodo = right.data(TodoModel::TodoPtrRole).value<KCalendarCore::Todo::Ptr>();
        Q_ASSERT(leftTodo);
        Q_ASSERT(rightTodo);
        if (!leftTodo || !rightTodo) {
            return 0;
        } else {
            return (leftTodo->completed() > rightTodo->completed()) ? -1 : 1;
        }
    } else {
        return (leftValue < rightValue) ? -1 : 1;
    }
}

/* -1 - less than
 *  0 - equal
 *  1 - bigger than
 * Sort in numeric order (1 < 9) rather than priority order (lowest 9 < highest 1).
 * There are arguments either way, but this is consistent with KCalendarCore.
 */
int TodoSortFilterProxyModel::comparePriorities(const QModelIndex &left, const QModelIndex &right) const
{
    Q_ASSERT(left.isValid());
    Q_ASSERT(right.isValid());

    const auto leftTodo = left.data(TodoModel::TodoPtrRole).value<KCalendarCore::Todo::Ptr>();
    const auto rightTodo = right.data(TodoModel::TodoPtrRole).value<KCalendarCore::Todo::Ptr>();
    Q_ASSERT(leftTodo);
    Q_ASSERT(rightTodo);
    if (!leftTodo || !rightTodo || leftTodo->priority() == rightTodo->priority()) {
        return 0;
    } else if (leftTodo->priority() < rightTodo->priority()) {
        return -1;
    } else {
        return 1;
    }
}

bool TodoSortFilterProxyModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    // To-dos without due date should appear last when sorting ascending,
    // so you can see the most urgent tasks first. (bug #174763)
    if (right.column() == TodoModel::DueDateColumn) {
        const int comparison = compareDueDates(left, right);

        if (comparison != 0) {
            return comparison == -1;
        } else {
            // Due dates are equal, but the user still expects sorting by importance
            // Fallback to the PriorityColumn
            QModelIndex leftPriorityIndex = left.sibling(left.row(), TodoModel::PriorityColumn);
            QModelIndex rightPriorityIndex = right.sibling(right.row(), TodoModel::PriorityColumn);
            const int fallbackComparison = comparePriorities(leftPriorityIndex, rightPriorityIndex);

            if (fallbackComparison != 0) {
                return fallbackComparison == 1;
            }
        }
    } else if (right.column() == TodoModel::StartDateColumn) {
        return compareStartDates(left, right) == -1;
    } else if (right.column() == TodoModel::CompletedDateColumn) {
        return compareCompletedDates(left, right) == -1;
    } else if (right.column() == TodoModel::PriorityColumn) {
        const int comparison = comparePriorities(left, right);

        if (comparison != 0) {
            return comparison == -1;
        } else {
            // Priorities are equal, but the user still expects sorting by importance
            // Fallback to the DueDateColumn
            QModelIndex leftDueDateIndex = left.sibling(left.row(), TodoModel::DueDateColumn);
            QModelIndex rightDueDateIndex = right.sibling(right.row(), TodoModel::DueDateColumn);
            const int fallbackComparison = compareDueDates(leftDueDateIndex, rightDueDateIndex);

            if (fallbackComparison != 0) {
                return fallbackComparison == 1;
            }
        }
    } else if (right.column() == TodoModel::PercentColumn) {
        const int comparison = compareCompletion(left, right);
        if (comparison != 0) {
            return comparison == -1;
        }
    }

    if (left.data() == right.data()) {
        // If both are equal, lets choose an order, otherwise Qt will display them randomly.
        // Fixes to-dos jumping around when you have calendar A selected, and then check/uncheck
        // a calendar B with no to-dos. No to-do is added/removed because calendar B is empty,
        // but you see the existing to-dos switching places.
        QModelIndex leftSummaryIndex = left.sibling(left.row(), TodoModel::SummaryColumn);
        QModelIndex rightSummaryIndex = right.sibling(right.row(), TodoModel::SummaryColumn);

        // This patch is not about fallingback to the SummaryColumn for sorting.
        // It's about avoiding jumping due to random reasons.
        // That's why we ignore the sort direction...
        return m_sortAscending ? QSortFilterProxyModel::lessThan(leftSummaryIndex, rightSummaryIndex)
                               : QSortFilterProxyModel::lessThan(rightSummaryIndex, leftSummaryIndex);

        // ...so, if you have 4 to-dos, all with CompletionColumn = "55%",
        // and click the header multiple times, nothing will happen because
        // it is already sorted by Completion.
    } else {
        return QSortFilterProxyModel::lessThan(left, right);
    }
}

int TodoSortFilterProxyModel::sortBy()
{
    return m_sortColumn;
}

void TodoSortFilterProxyModel::setSortBy(int sortBy)
{
    m_sortColumn = sortBy;
    Q_EMIT sortByChanged();
    sortTodoModel(m_sortColumn, m_sortAscending);
}

bool TodoSortFilterProxyModel::sortAscending()
{
    return m_sortAscending;
}

void TodoSortFilterProxyModel::setSortAscending(bool sortAscending)
{
    m_sortAscending = sortAscending;
    Q_EMIT sortAscendingChanged();
    sortTodoModel(m_sortColumn, m_sortAscending);
}
