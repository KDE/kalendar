// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <todosortfilterproxymodel.h>

TodoSortFilterProxyModel::TodoSortFilterProxyModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    m_extraTodoModel = new ExtraTodoModel;
    setSourceModel(m_extraTodoModel);
    setDynamicSortFilter(true);
    setSortCaseSensitivity(Qt::CaseInsensitive);
    setFilterCaseSensitivity(Qt::CaseInsensitive);
}

bool TodoSortFilterProxyModel::filterAcceptsRow(int row, const QModelIndex &sourceParent) const
{
    if(filterAcceptsRowCheck(row, sourceParent)) {
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

bool TodoSortFilterProxyModel::filterAcceptsRowCheck(int row, const QModelIndex& sourceParent) const
{
    const QModelIndex sourceIndex = sourceModel()->index(row, 0, sourceParent);
    Q_ASSERT(sourceIndex.isValid());

    bool acceptRow = true;

    if(m_filterCollectionId > -1) {
        acceptRow = acceptRow && sourceIndex.data(ExtraTodoModel::CollectionIdRole).toInt() == m_filterCollectionId;
    }

    switch(m_showCompleted) {
        case ShowComplete::ShowCompleteOnly:
            acceptRow = acceptRow && sourceIndex.data(ExtraTodoModel::CompletedRole).toBool();
            break;
        case ShowComplete::ShowIncompleteOnly:
            acceptRow = acceptRow && !sourceIndex.data(ExtraTodoModel::CompletedRole).toBool();
        case ShowComplete::ShowAll:
        default:
            break;
    }

    if(!m_filterCategoryString.isEmpty()) {
        acceptRow = acceptRow && sourceIndex.data(ExtraTodoModel::CategoriesRole).toStringList().contains(m_filterCategoryString);
    }

    return acceptRow ? QSortFilterProxyModel::filterAcceptsRow(row, sourceParent) : acceptRow;
}

bool TodoSortFilterProxyModel::hasAcceptedChildren(int row, const QModelIndex& sourceParent) const
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

void TodoSortFilterProxyModel::setCalendar(Akonadi::ETMCalendar *calendar)
{
    Akonadi::ETMCalendar::Ptr calendarPtr(calendar);
    m_extraTodoModel->setCalendar(calendarPtr);
    Q_EMIT calendarChanged();
}

void TodoSortFilterProxyModel::setIncidenceChanger(Akonadi::IncidenceChanger* changer)
{
    m_extraTodoModel->setIncidenceChanger(changer);
    Q_EMIT incidenceChangerChanged();
}

void TodoSortFilterProxyModel::setColorCache(QHash<QString, QColor> colorCache)
{
    m_extraTodoModel->setColorCache(colorCache);
}

qint64 TodoSortFilterProxyModel::filterCollectionId()
{
    return m_filterCollectionId;
}

void TodoSortFilterProxyModel::setFilterCollectionId(qint64 filterCollectionId)
{
    Q_EMIT layoutAboutToBeChanged();
    m_filterCollectionId = filterCollectionId;
    invalidateFilter();
    Q_EMIT filterCollectionIdChanged();
    Q_EMIT layoutChanged();
}

QString TodoSortFilterProxyModel::filterCategoryString()
{
    return m_filterCategoryString;
}

void TodoSortFilterProxyModel::setFilterCategoryString(QString filterCategoryString)
{
    Q_EMIT layoutAboutToBeChanged();
    m_filterCategoryString = filterCategoryString;
    Q_EMIT filterCategoryStringChanged();
    invalidateFilter();
    Q_EMIT layoutChanged();
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

void TodoSortFilterProxyModel::sortTodoModel(int column, bool ascending)
{
    auto order = ascending ? Qt::AscendingOrder : Qt::DescendingOrder;
    this->sort(column, order);
}

void TodoSortFilterProxyModel::filterTodoName(QString name, int showCompleted)
{
    Q_EMIT layoutAboutToBeChanged();
    setFilterFixedString(name);
    if(name.length() > 0) {
        m_showCompleted = showCompleted;
    } else {
        setShowCompleted(m_showCompletedStore);
    }
    invalidateFilter();
    Q_EMIT layoutChanged();
}
