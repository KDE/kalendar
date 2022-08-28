/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <Akonadi/Item>
#include <QObject>
class KJob;
class FollowUpReminderFinishTaskJob : public QObject
{
    Q_OBJECT
public:
    explicit FollowUpReminderFinishTaskJob(Akonadi::Item::Id id, QObject *parent = nullptr);
    ~FollowUpReminderFinishTaskJob() override;

    void start();

Q_SIGNALS:
    void finishTaskDone();
    void finishTaskFailed();

private:
    Q_DISABLE_COPY(FollowUpReminderFinishTaskJob)
    void slotItemFetchJobDone(KJob *job);
    void slotItemModifiedResult(KJob *job);
    void closeTodo();
    const Akonadi::Item::Id mTodoId;
};
