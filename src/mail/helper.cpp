// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "helper.h"

#include <Akonadi/CollectionStatistics>

qint64 MailCollectionHelper::unreadCount(const Akonadi::Collection &collection)
{
    return collection.statistics().unreadCount();
}
