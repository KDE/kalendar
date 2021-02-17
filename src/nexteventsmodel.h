// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

namespace Akonadi {
    class ETMCalendar;
}

class NextEventsModel : public QAbstractItemModel
{
    Q_OBJECT

public:
    enum Roles {
        CustomRole = Qt::UserRole
    };

public:
    explicit NextEventsModel(Akonadi::ETMCallendar QObject *parent);
    ~NextEventsModel();

};
