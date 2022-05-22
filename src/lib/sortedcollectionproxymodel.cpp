// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
//
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "sortedcollectionproxymodel.h"

SortedCollectionProxModel::SortedCollectionProxModel(QObject *parent)
    : Akonadi::CollectionFilterProxyModel(parent)
{
}

bool SortedCollectionProxModel::lessThan(const QModelIndex &sourceLeft, const QModelIndex &sourceRight) const
{
    const auto leftHasChildren = sourceModel()->hasChildren(sourceLeft);
    const auto rightHasChildren = sourceModel()->hasChildren(sourceRight);
    if (leftHasChildren && !rightHasChildren) {
        return false;
    } else if (!leftHasChildren && rightHasChildren) {
        return true;
    }

    return Akonadi::CollectionFilterProxyModel::lessThan(sourceLeft, sourceRight);
}
