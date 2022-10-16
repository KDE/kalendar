// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "todosortfilterproxymodel.h"
#include "../filter.h"

TodoSortFilterProxyModel::TodoSortFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    const QString todoMimeType = QStringLiteral("application/x-vnd.akonadi.calendar.todo");
    m_todoTreeModel.reset(new Akonadi::IncidenceTreeModel(QStringList() << todoMimeType, this));

    const auto pref = EventViews::PrefsPtr(new EventViews::Prefs);
    m_baseTodoModel.reset(new TodoModel(pref, this));
    m_baseTodoModel->setSourceModel(m_todoTreeModel.data());
    setSourceModel(m_baseTodoModel.data());

    setDynamicSortFilter(true);
    setSortCaseSensitivity(Qt::CaseInsensitive);
    setFilterCaseSensitivity(Qt::CaseInsensitive);

    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup rColorsConfig(config, "Resources Colors");
    m_colorWatcher = KConfigWatcher::create(config);
    QObject::connect(m_colorWatcher.data(), &KConfigWatcher::configChanged, this, &TodoSortFilterProxyModel::loadColors);

    loadColors();

    m_dateRefreshTimer.setInterval(m_dateRefreshTimerInterval);
    m_dateRefreshTimer.callOnTimeout(this, &TodoSortFilterProxyModel::updateDateLabels);
    m_dateRefreshTimer.start();
}

int TodoSortFilterProxyModel::columnCount(const QModelIndex &) const
{
    return 1;
}

QHash<int, QByteArray> TodoSortFilterProxyModel::roleNames() const
{
    QHash<int, QByteArray> roleNames = QSortFilterProxyModel::roleNames();
    roleNames[TodoModel::SummaryRole] = "text";
    roleNames[Roles::StartTimeRole] = "startTime";
    roleNames[Roles::EndTimeRole] = "endTime";
    roleNames[Roles::DisplayDueDateRole] = "displayDueDate";
    roleNames[Roles::LocationRole] = "location";
    roleNames[Roles::AllDayRole] = "allDay";
    roleNames[Roles::ColorRole] = "color";
    roleNames[Roles::CompletedRole] = "todoCompleted";
    roleNames[Roles::PriorityRole] = "priority";
    roleNames[Roles::CollectionIdRole] = "collectionId";
    roleNames[Roles::DurationStringRole] = "durationString";
    roleNames[Roles::RecursRole] = "recurs";
    roleNames[Roles::IsOverdueRole] = "isOverdue";
    roleNames[Roles::IncidenceIdRole] = "incidenceId";
    roleNames[Roles::IncidenceTypeRole] = "incidenceType";
    roleNames[Roles::IncidenceTypeStrRole] = "incidenceTypeStr";
    roleNames[Roles::IncidenceTypeIconRole] = "incidenceTypeIcon";
    roleNames[Roles::IncidencePtrRole] = "incidencePtr";
    roleNames[Roles::TagsRole] = "tags";
    roleNames[Roles::ItemRole] = "item";
    roleNames[Roles::CategoriesRole] = "todoCategories"; // Simply 'categories' causes issues
    roleNames[Roles::CategoriesDisplayRole] = "categoriesDisplay";
    roleNames[Roles::TreeDepthRole] = "treeDepth";
    roleNames[Roles::TopMostParentDueDateRole] = "topMostParentDueDate";
    roleNames[Roles::TopMostParentSummaryRole] = "topMostParentSummary";
    roleNames[Roles::TopMostParentPriorityRole] = "topMostParentPriority";

    return roleNames;
}

QVariant TodoSortFilterProxyModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || m_calendar.isNull()) {
        return {};
    }

    const QModelIndex sourceIndex = mapToSource(index.sibling(index.row(), 0));
    if (!sourceIndex.isValid()) {
        return {};
    }
    Q_ASSERT(sourceIndex.isValid());

    auto todoItem = sourceIndex.data(TodoModel::TodoRole).value<Akonadi::Item>();

    if (!todoItem.isValid()) {
        return {};
    }

    auto collectionId = todoItem.parentCollection().id();
    auto todoPtr = Akonadi::CalendarUtils::todo(todoItem);

    if (!todoPtr) {
        return {};
    }

    if (role == Roles::StartTimeRole) {
        return todoPtr->dtStart();
    } else if (role == Roles::EndTimeRole) {
        return todoPtr->dtDue();
    } else if (role == Roles::DisplayDueDateRole) {
        return todoDueDateDisplayString(todoPtr, DisplayDateTimeAndIfOverdue);
    } else if (role == Roles::LocationRole) {
        return todoPtr->location();
    } else if (role == Roles::AllDayRole) {
        return todoPtr->allDay();
    } else if (role == Roles::ColorRole) {
        QColor nullcolor;
        return m_colors.contains(QString::number(collectionId)) ? m_colors[QString::number(collectionId)] : nullcolor;
    } else if (role == Roles::CompletedRole) {
        return todoPtr->isCompleted();
    } else if (role == Roles::PriorityRole) {
        return todoPtr->priority();
    } else if (role == Roles::CollectionIdRole) {
        return collectionId;
    } else if (role == DurationStringRole) {
        const auto duration = KCalendarCore::Duration(todoPtr->dtStart(), todoPtr->dtDue());

        if (todoPtr->allDay() && !todoPtr->dtStart().isValid()) {
            return m_format.formatSpelloutDuration(24 * 60 * 60 * 1000); // format milliseconds in 1 day
        } else if (!todoPtr->dtStart().isValid() || duration.asSeconds() == 0) {
            return QString();
        }

        return m_format.formatSpelloutDuration(duration.asSeconds() * 1000);
    } else if (role == Roles::RecursRole) {
        return todoPtr->recurs();
    } else if (role == Roles::IsOverdueRole) {
        return todoPtr->isOverdue();
    } else if (role == Roles::IncidenceIdRole) {
        return todoPtr->uid();
    } else if (role == Roles::IncidenceTypeRole) {
        return todoPtr->type();
    } else if (role == Roles::IncidenceTypeStrRole) {
        return todoPtr->type() == KCalendarCore::Incidence::TypeTodo ? i18n("Task") : i18n(todoPtr->typeStr().constData());
    } else if (role == Roles::IncidenceTypeIconRole) {
        return todoPtr->iconName();
    } else if (role == Roles::IncidencePtrRole) {
        return QVariant::fromValue(Akonadi::CalendarUtils::incidence(todoItem));
    } else if (role == Roles::TagsRole) {
        return QVariant::fromValue(todoItem.tags());
    } else if (role == Roles::ItemRole) {
        return QVariant::fromValue(todoItem);
    } else if (role == Roles::CategoriesRole) {
        return todoPtr->categories();
    } else if (role == Roles::CategoriesDisplayRole) {
        return todoPtr->categories().join(i18nc("List separator", ", "));
    } else if (role == Roles::TreeDepthRole || role == TopMostParentSummaryRole || role == TopMostParentDueDateRole || role == TopMostParentPriorityRole) {
        int depth = 0;
        auto idx = index;
        while (idx.parent().isValid()) {
            idx = idx.parent();
            depth++;
        }

        auto todo = idx.data(TodoModel::TodoPtrRole).value<KCalendarCore::Todo::Ptr>();

        switch (role) {
        case Roles::TreeDepthRole:
            return depth;
        case TopMostParentSummaryRole:
            return todo->summary();
        case TopMostParentDueDateRole: {
            if (!todo->hasDueDate()) {
                return i18n("No set date");
            }

            if (todo->isOverdue()) {
                return i18n("Overdue");
            }

            const auto dateInCurrentTZ = todo->dtDue().toLocalTime().date();
            const auto isToday = dateInCurrentTZ == QDate::currentDate();

            return isToday ? i18n("Today") : todoDueDateDisplayString(todo, DisplayDateOnly);
        }
        case TopMostParentPriorityRole:
            return todo->priority();
        }
    }
    return QSortFilterProxyModel::data(index, role);
}

QString TodoSortFilterProxyModel::todoDueDateDisplayString(const KCalendarCore::Todo::Ptr todo,
                                                           const TodoSortFilterProxyModel::DueDateDisplayFormat format) const
{
    if (!todo || !todo->hasDueDate()) {
        return {};
    }

    const auto systemLocale = QLocale::system();
    const auto includeTime = !todo->allDay() && format != DisplayDateOnly;
    const auto includeOverdue = todo->isOverdue() && format == DisplayDateTimeAndIfOverdue;

    const auto todoDateTimeDue = todo->dtDue().toLocalTime();
    const auto todoDateDue = todoDateTimeDue.date();
    const auto todoTimeDueString =
        includeTime ? i18nc("Please retain space", " at %1", systemLocale.toString(todoDateTimeDue.time(), QLocale::NarrowFormat)) : QStringLiteral(" ");
    const auto todoOverdueString = includeOverdue ? i18nc("Please retain parenthesis and space", " (overdue)") : QString();

    const auto currentDate = QDate::currentDate();
    const auto dateFormat = todoDateDue.year() == currentDate.year() ? QStringLiteral("dddd dd MMMM") : QStringLiteral("dddd dd MMMM yyyy");

    static constexpr char translationExplainer[] =
        "No spaces -- the (optional) %1 string, which includes the time, includes this space"
        " as does the %2 string which is the overdue string (also optional!)";

    if (currentDate == todoDateDue) {
        return i18nc(translationExplainer, "Today%1%2", todoTimeDueString, todoOverdueString);
    } else if (currentDate.daysTo(todoDateDue) == 1) {
        return i18nc(translationExplainer, "Tomorrow%1%2", todoTimeDueString, todoOverdueString);
    } else if (currentDate.daysTo(todoDateDue) == -1) {
        return i18nc(translationExplainer, "Yesterday%1%2", todoTimeDueString, todoOverdueString);
    }

    const auto dateDueString = systemLocale.toString(todoDateDue, dateFormat);
    return dateDueString + todoTimeDueString + todoOverdueString;
}

void TodoSortFilterProxyModel::updateDateLabels()
{
    if (rowCount() == 0 || !sourceModel()) {
        return;
    }

    emitDateDataChanged({});
    sortTodoModel();
    m_lastDateRefreshDate = QDate::currentDate();
}

void TodoSortFilterProxyModel::emitDateDataChanged(const QModelIndex &idx)
{
    const auto idxRowCount = rowCount(idx);
    const auto srcModel = sourceModel();

    if (idxRowCount == 0) {
        return;
    }

    const auto bottomRow = idxRowCount - 1;
    const auto currentDate = QDate::currentDate();
    const auto currentDateTime = QDateTime::currentDateTime();

    const auto iterateOverChildren = [this, &idx, &srcModel, &currentDate, &currentDateTime](const int row) {
        const auto childIdx = index(row, 0, idx);

        const auto todo = childIdx.data(TodoModel::TodoPtrRole).value<KCalendarCore::Todo::Ptr>();
        const auto isOverdue = todo->isOverdue();
        const auto dtDue = todo->dtDue();
        const auto isRecentlyOverdue = isOverdue && currentDateTime.msecsTo(dtDue) >= -m_dateRefreshTimerInterval;

        if (isRecentlyOverdue || m_lastDateRefreshDate != currentDate) {
            Q_EMIT dataChanged(childIdx, childIdx, {DisplayDueDateRole, TopMostParentDueDateRole});

            // For the proxy model to re-sort items into their correct section we also need to emit a
            // dataChanged() signal for the column we are sorting by in the source model
            const auto srcChildIdx = mapToSource(childIdx).siblingAtColumn(TodoModel::DueDateColumn);
            Q_EMIT srcModel->dataChanged(srcChildIdx, srcChildIdx, {TodoModel::DueDateRole});
        }

        // We recursively do the same for children
        emitDateDataChanged(childIdx);
    };

    // This is a workaround for weird sorting behaviour. If one of the items changes because it becomes
    // overdue, for example, the way in which we emit dataChanged() signals of the sourceModel will
    // dictate how the model gets sorted.
    //
    // Example: In a case where the sort is ascending (i.e. overdue at top), a 0 to rowCount() -1 sort
    // will move the overdue item up by only one row due to how the QSortFilterProxyModel uses lessThan().
    // If we go the opposite way then the QSFPM calls lessThan() on the overdue item more than once, moving
    // it upwards.

    if (m_sortAscending) {
        for (auto i = bottomRow; i >= 0; --i) {
            iterateOverChildren(i);
        }
    } else {
        for (auto i = 0; i < idxRowCount; ++i) {
            iterateOverChildren(i);
        }
    }
}

bool TodoSortFilterProxyModel::filterAcceptsRow(int row, const QModelIndex &sourceParent) const
{
    if (filterAcceptsRowCheck(row, sourceParent)) {
        return true;
    }

    // Accept if any parent is accepted itself, and if we are the model for the incomplete tasks view, only do this if the config says to show all
    // of a tasks' incomplete subtasks. By default we include all of a tasks' subtasks, regardless of if they are complete or not, as long as the parent
    // passes the filter check. If this is not the case, we only include subtasks that pass the filter themselves.

    if ((m_showCompletedSubtodosInIncomplete && m_showCompleted == ShowComplete::ShowIncompleteOnly) || m_showCompleted != ShowComplete::ShowIncompleteOnly) {
        QModelIndex parent = sourceParent;
        while (parent.isValid()) {
            if (filterAcceptsRowCheck(parent.row(), parent.parent()))
                return true;
            parent = parent.parent();
        }
    }

    // Accept if any child is accepted itself
    return hasAcceptedChildren(row, sourceParent);
}

bool TodoSortFilterProxyModel::filterAcceptsRowCheck(int row, const QModelIndex &sourceParent) const
{
    const QModelIndex sourceIndex = sourceModel()->index(row, 0, sourceParent);
    Q_ASSERT(sourceIndex.isValid());

    if (m_filterObject == nullptr) {
        return QSortFilterProxyModel::filterAcceptsRow(row, sourceParent);
    }

    bool acceptRow = true;

    if (m_filterObject->collectionId() > -1) {
        const auto collectionId = sourceIndex.data(TodoModel::TodoRole).value<Akonadi::Item>().parentCollection().id();
        acceptRow = acceptRow && collectionId == m_filterObject->collectionId();
    }

    switch (m_showCompleted) {
    case ShowComplete::ShowCompleteOnly:
        acceptRow = acceptRow && sourceIndex.data(TodoModel::PercentRole).toInt() == 100;
        break;
    case ShowComplete::ShowIncompleteOnly:
        acceptRow = acceptRow && sourceIndex.data(TodoModel::PercentRole).toInt() < 100;
    case ShowComplete::ShowAll:
    default:
        break;
    }

    if (!m_filterObject->tags().isEmpty()) {
        const auto tags = m_filterObject->tags();
        bool containsTag = false;
        for (const auto &tag : tags) {
            const auto todoPtr = sourceIndex.data(TodoModel::TodoPtrRole).value<KCalendarCore::Todo::Ptr>();
            if (todoPtr->categories().contains(tag)) {
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

Akonadi::ETMCalendar::Ptr TodoSortFilterProxyModel::calendar()
{
    return m_calendar;
}

void TodoSortFilterProxyModel::setCalendar(Akonadi::ETMCalendar::Ptr &calendar)
{
    beginResetModel();
    m_calendar = calendar;
    m_todoTreeModel->setSourceModel(calendar->model());
    m_baseTodoModel->setCalendar(m_calendar);
    Q_EMIT calendarChanged();
    endResetModel();
}

Akonadi::IncidenceChanger *TodoSortFilterProxyModel::incidenceChanger()
{
    return m_lastSetChanger;
}

void TodoSortFilterProxyModel::setIncidenceChanger(Akonadi::IncidenceChanger *changer)
{
    m_baseTodoModel->setIncidenceChanger(changer);
    m_lastSetChanger = changer;

    Q_EMIT incidenceChangerChanged();
}

void TodoSortFilterProxyModel::setColorCache(QHash<QString, QColor> colorCache)
{
    m_colors = colorCache;
}

void TodoSortFilterProxyModel::loadColors()
{
    Q_EMIT layoutAboutToBeChanged();
    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup rColorsConfig(config, "Resources Colors");
    const QStringList colorKeyList = rColorsConfig.keyList();

    for (const QString &key : colorKeyList) {
        QColor color = rColorsConfig.readEntry(key, QColor("blue"));
        m_colors[key] = color;
    }
    Q_EMIT layoutChanged();
}

int TodoSortFilterProxyModel::showCompleted() const
{
    return m_showCompleted;
}

void TodoSortFilterProxyModel::setShowCompleted(int showCompleted)
{
    Q_EMIT layoutAboutToBeChanged();
    m_showCompleted = showCompleted;
    m_showCompletedStore = showCompleted; // For when we search
    invalidateFilter();
    Q_EMIT showCompletedChanged();
    Q_EMIT layoutChanged();

    sortTodoModel();
}

Filter *TodoSortFilterProxyModel::filterObject() const
{
    return m_filterObject;
}

void TodoSortFilterProxyModel::setFilterObject(Filter *filterObject)
{
    if (m_filterObject == filterObject) {
        return;
    }

    if (m_filterObject) {
        disconnect(m_filterObject, nullptr, this, nullptr);
    }

    Q_EMIT filterObjectAboutToChange();
    Q_EMIT layoutAboutToBeChanged();
    m_filterObject = filterObject;
    Q_EMIT filterObjectChanged();

    const auto nameFilter = m_filterObject->name();
    const auto handleFilterNameChange = [this] {
        Q_EMIT filterObjectAboutToChange();
        setFilterFixedString(m_filterObject->name());
        Q_EMIT layoutChanged();
        Q_EMIT filterObjectChanged();
    };
    const auto handleFilterObjectChange = [this] {
        Q_EMIT filterObjectAboutToChange();
        invalidateFilter();
        Q_EMIT layoutChanged();
        Q_EMIT filterObjectChanged();
    };

    connect(m_filterObject, &Filter::nameChanged, this, handleFilterNameChange);
    connect(m_filterObject, &Filter::tagsChanged, this, handleFilterObjectChange);
    connect(m_filterObject, &Filter::collectionIdChanged, this, handleFilterObjectChange);

    if (!nameFilter.isEmpty()) {
        setFilterFixedString(nameFilter);
    }

    invalidateFilter();

    Q_EMIT layoutChanged();

    sortTodoModel();
}

void TodoSortFilterProxyModel::sortTodoModel()
{
    const auto order = m_sortAscending ? Qt::AscendingOrder : Qt::DescendingOrder;
    QSortFilterProxyModel::sort(m_sortColumn, order);
}

void TodoSortFilterProxyModel::filterTodoName(const QString &name, const int showCompleted)
{
    Q_EMIT layoutAboutToBeChanged();
    setFilterFixedString(name);
    if (!name.isEmpty()) {
        m_showCompleted = showCompleted;
    } else {
        setShowCompleted(m_showCompletedStore);
    }
    invalidateFilter();
    Q_EMIT layoutChanged();

    sortTodoModel();
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

    const auto leftOverdue = leftTodo->isOverdue();
    const auto rightOverdue = rightTodo->isOverdue();

    if (leftOverdue != rightOverdue) {
        return leftOverdue ? -1 : 1;
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
    // Workaround for cases where lessThan will receive invalid left index
    if (!left.isValid()) {
        return true;
    }

    // To-dos without due date should appear last when sorting ascending,
    // so you can see the most urgent tasks first. (bug #174763)
    if (right.column() == TodoModel::DueDateColumn) {
        QModelIndex leftDueDateIndex = left.sibling(left.row(), TodoModel::DueDateColumn); // Prevent possible assert fail

        const int comparison = compareDueDates(leftDueDateIndex, right);

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

int TodoSortFilterProxyModel::sortBy() const
{
    return m_sortColumn;
}

void TodoSortFilterProxyModel::setSortBy(int sortBy)
{
    m_sortColumn = sortBy;
    Q_EMIT sortByChanged();
    sortTodoModel();
}

bool TodoSortFilterProxyModel::sortAscending() const
{
    return m_sortAscending;
}

void TodoSortFilterProxyModel::setSortAscending(bool sortAscending)
{
    m_sortAscending = sortAscending;
    Q_EMIT sortAscendingChanged();
    sortTodoModel();
}

bool TodoSortFilterProxyModel::showCompletedSubtodosInIncomplete() const
{
    return m_showCompletedSubtodosInIncomplete;
}

void TodoSortFilterProxyModel::setShowCompletedSubtodosInIncomplete(bool showCompletedSubtodosInIncomplete)
{
    m_showCompletedSubtodosInIncomplete = showCompletedSubtodosInIncomplete;
    Q_EMIT showCompletedSubtodosInIncompleteChanged();

    invalidateFilter();
}

Q_DECLARE_METATYPE(KCalendarCore::Incidence::Ptr)
