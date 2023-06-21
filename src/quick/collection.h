// SPDX-FileCopyrightText: 2007-2009 Tobias Koenig <tokoe@kde.org>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <Akonadi/EntityTreeModel>
#include <QObject>

namespace Akonadi
{
namespace Quick
{
class Collection : public QObject
{
    Q_OBJECT
public:
    enum Right {
        ReadOnly = 0x0, ///< Can only read items or subcollection of this collection
        CanChangeItem = 0x1, ///< Can change items in this collection
        CanCreateItem = 0x2, ///< Can create new items in this collection
        CanDeleteItem = 0x4, ///< Can delete items in this collection
        CanChangeCollection = 0x8, ///< Can change this collection
        CanCreateCollection = 0x10, ///< Can create new subcollections in this collection
        CanDeleteCollection = 0x20, ///< Can delete this collection
        CanLinkItem = 0x40, ///< Can create links to existing items in this virtual collection @since 4.4
        CanUnlinkItem = 0x80, ///< Can remove links to items in this virtual collection @since 4.4
        AllRights = (CanChangeItem | CanCreateItem | CanDeleteItem | CanChangeCollection | CanCreateCollection
                     | CanDeleteCollection) ///< Has all rights on this storage collection
    };
    Q_ENUM(Right)

    enum Role {
        CollectionRole = Akonadi::EntityTreeModel::CollectionRole,
        CollectionColorRole = Qt::BackgroundRole,
    };
    Q_ENUM(Role)
};
}
}
