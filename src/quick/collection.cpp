// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "collection.h"

using namespace Akonadi::Quick;

qint64 Collection::id(Akonadi::Collection collection) const
{
    return collection.id();
}

Akonadi::Collection Collection::fromId(qint64 collectionId) const
{
    return Akonadi::Collection(collectionId);
}
