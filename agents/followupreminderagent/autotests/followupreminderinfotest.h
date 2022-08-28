/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QObject>

class FollowUpReminderInfoTest : public QObject
{
    Q_OBJECT
public:
    explicit FollowUpReminderInfoTest(QObject *parent = nullptr);

private Q_SLOTS:
    void shouldHaveDefaultValue();
    void shoudBeNotValid();
    void shoudBeValidEvenIfSubjectIsEmpty();
    void shouldRestoreFromSettings();
    void shouldCopyReminderInfo();
};
