/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QObject>

class FollowupReminderNoAnswerDialogTest : public QObject
{
    Q_OBJECT
public:
    explicit FollowupReminderNoAnswerDialogTest(QObject *parent = nullptr);
    ~FollowupReminderNoAnswerDialogTest() override;
private Q_SLOTS:
    void shouldHaveDefaultValues();
    void shouldAddItemInTreeList();
    void shouldItemHaveInfo();
    void initTestCase();
};
