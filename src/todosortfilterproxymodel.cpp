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

    auto resetModel = [this] {
        if (!mRefreshTimer.isActive()) {
            mRefreshTimer.start(50);
        }
    };

    connect(&mRefreshTimer, &QTimer::timeout, this, [&]() {
        beginResetModel();
        endResetModel();
        sortTodoModel(m_sortColumn, m_sortAscending);
    });

    connect(m_extraTodoModel, &KExtraColumnsProxyModel::dataChanged, this, resetModel);
    connect(m_extraTodoModel, &KExtraColumnsProxyModel::layoutChanged, this, resetModel);
    connect(m_extraTodoModel, &KExtraColumnsProxyModel::modelReset, this, resetModel);
    connect(m_extraTodoModel, &KExtraColumnsProxyModel::rowsInserted, this, resetModel);
    connect(m_extraTodoModel, &KExtraColumnsProxyModel::rowsMoved, this, resetModel);
    connect(m_extraTodoModel, &KExtraColumnsProxyModel::rowsRemoved, this, resetModel);
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
    auto order = ascending ? Qt::AscendingOrder : Qt::DescendingOrder;
    this->sort(column, order);

    if (column == PriorityIntColumn) { // Priorities go 1 (most) to 9 (least) so reverse order
        order = ascending ? Qt::DescendingOrder : Qt::AscendingOrder;
        this->sort(column, order); // HACK: For some reason, only calling once does not sort (!!!)
    }
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

bool TodoSortFilterProxyModel::lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const
{
    if (source_left.column() == PriorityIntColumn && source_left.data().toInt() == 0) {
        return !(sortOrder() == Qt::AscendingOrder);
    }

    if (source_left.column() == EndTimeColumn && !source_left.data().toDateTime().isValid()) {
        return !(sortOrder() == Qt::AscendingOrder);
    }

    return QSortFilterProxyModel::lessThan(source_left, source_right);
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
