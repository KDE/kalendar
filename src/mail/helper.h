// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include <Akonadi/Collection>
#include <QObject>

class MailCollectionHelper : public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE qint64 unreadCount(const Akonadi::Collection &collection);
};
