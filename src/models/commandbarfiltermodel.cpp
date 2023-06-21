// SPDX-FileCopyrightText: 2021 Waqar Ahmed <waqar.17a@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "commandbarfiltermodel.h"
#include "actionsmodel.h"
#include <KFuzzyMatcher>
#include <QAction>

CommandBarFilterModel::CommandBarFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
}

QString CommandBarFilterModel::filterString() const
{
    return m_pattern;
}

void CommandBarFilterModel::setFilterString(const QString &string)
{
    if (m_pattern == string) {
        return;
    }
    // MUST reset the model here, we want to repopulate
    // invalidateFilter() will not work here
    beginResetModel();
    m_pattern = string;
    endResetModel();
    Q_EMIT filterStringChanged();
}

bool CommandBarFilterModel::lessThan(const QModelIndex &sourceLeft, const QModelIndex &sourceRight) const
{
    const int l = sourceLeft.data(KalCommandBarModel::Score).toInt();
    const int r = sourceRight.data(KalCommandBarModel::Score).toInt();
    return l < r;
}

bool CommandBarFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (m_pattern.isEmpty()) {
        return true;
    }

    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!(qvariant_cast<QAction *>(idx.data(Qt::UserRole))->isEnabled())) {
        return false;
    }

    const QString actionName = idx.data(Qt::DisplayRole).toString();
    KFuzzyMatcher::Result res = KFuzzyMatcher::match(m_pattern, actionName);
    sourceModel()->setData(idx, res.score, KalCommandBarModel::Score);
    return res.matched;
}

#include "moc_commandbarfiltermodel.cpp"
