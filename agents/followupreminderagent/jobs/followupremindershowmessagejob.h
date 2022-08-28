/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <Akonadi/Item>
#include <QObject>

class FollowUpReminderShowMessageJob : public QObject
{
    Q_OBJECT
public:
    explicit FollowUpReminderShowMessageJob(Akonadi::Item::Id id, QObject *parent = nullptr);
    ~FollowUpReminderShowMessageJob() override;

    void start();

private:
    Q_DISABLE_COPY(FollowUpReminderShowMessageJob)
    const Akonadi::Item::Id mId;
};
