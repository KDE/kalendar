/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <KSharedConfig>
#include <QObject>
#include <QRegularExpression>

class FollowUpReminderConfigTest : public QObject
{
    Q_OBJECT
public:
    explicit FollowUpReminderConfigTest(QObject *parent = nullptr);
    ~FollowUpReminderConfigTest() override;
private Q_SLOTS:
    void init();
    void cleanup();
    void cleanupTestCase();
    void shouldConfigBeEmpty();
    void shouldAddAnItem();
    void shouldNotAddAnInvalidItem();
    void shouldReplaceItem();
    void shouldAddSeveralItem();
    void shouldRemoveItems();
    void shouldNotRemoveItemWhenListIsEmpty();
    void shouldNotRemoveItemWhenItemDoesntExist();

private:
    KSharedConfig::Ptr mConfig;
    QRegularExpression mFollowupRegExpFilter;
};
