/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "followupreminderinfotest.h"
#include "../followupreminderinfo.h"

#include <KConfigGroup>
#include <KSharedConfig>
#include <QStandardPaths>
#include <QTest>

FollowUpReminderInfoTest::FollowUpReminderInfoTest(QObject *parent)
    : QObject(parent)
{
    QStandardPaths::setTestModeEnabled(true);
}

void FollowUpReminderInfoTest::shouldHaveDefaultValue()
{
    FollowUpReminder::FollowUpReminderInfo info;
    QCOMPARE(info.originalMessageItemId(), Akonadi::Item::Id(-1));
    QCOMPARE(info.messageId(), QString());
    QCOMPARE(info.isValid(), false);
    QCOMPARE(info.to(), QString());
    QCOMPARE(info.subject(), QString());
    QCOMPARE(info.uniqueIdentifier(), -1);
}

void FollowUpReminderInfoTest::shoudBeNotValid()
{
    FollowUpReminder::FollowUpReminderInfo info;
    // We need a messageId not empty and a valid date and a "To" not empty
    info.setMessageId(QStringLiteral("foo"));
    QCOMPARE(info.isValid(), false);

    const QDate date(2014, 1, 1);
    info.setFollowUpReminderDate(QDate(date));
    QCOMPARE(info.isValid(), false);

    const QString to = QStringLiteral("kde.org");
    info.setTo(to);
    QCOMPARE(info.isValid(), true);

    info.setOriginalMessageItemId(Akonadi::Item::Id(42));
    QCOMPARE(info.isValid(), true);
}

void FollowUpReminderInfoTest::shoudBeValidEvenIfSubjectIsEmpty()
{
    FollowUpReminder::FollowUpReminderInfo info;
    // We need a Akonadi::Id valid and a messageId not empty and a valid date and a "To" not empty
    info.setMessageId(QStringLiteral("foo"));
    const QDate date(2014, 1, 1);
    info.setFollowUpReminderDate(QDate(date));
    const QString to = QStringLiteral("kde.org");
    info.setTo(to);
    info.setOriginalMessageItemId(Akonadi::Item::Id(42));
    QCOMPARE(info.isValid(), true);
}

void FollowUpReminderInfoTest::shouldRestoreFromSettings()
{
    FollowUpReminder::FollowUpReminderInfo info;
    info.setMessageId(QStringLiteral("foo"));
    const QDate date(2014, 1, 1);
    info.setFollowUpReminderDate(QDate(date));
    const QString to = QStringLiteral("kde.org");
    info.setTo(to);
    info.setOriginalMessageItemId(Akonadi::Item::Id(42));
    info.setSubject(QStringLiteral("Subject"));
    info.setUniqueIdentifier(42);
    info.setTodoId(52);

    KConfigGroup grp(KSharedConfig::openConfig(), "testsettings");
    info.writeConfig(grp, info.uniqueIdentifier());

    FollowUpReminder::FollowUpReminderInfo restoreInfo(grp);
    QCOMPARE(info, restoreInfo);
}

void FollowUpReminderInfoTest::shouldCopyReminderInfo()
{
    FollowUpReminder::FollowUpReminderInfo info;
    info.setMessageId(QStringLiteral("foo"));
    const QDate date(2014, 1, 1);
    info.setFollowUpReminderDate(QDate(date));
    const QString to = QStringLiteral("kde.org");
    info.setTo(to);
    info.setOriginalMessageItemId(Akonadi::Item::Id(42));
    info.setSubject(QStringLiteral("Subject"));
    info.setUniqueIdentifier(42);
    info.setTodoId(52);

    FollowUpReminder::FollowUpReminderInfo copyInfo(info);
    QCOMPARE(info, copyInfo);
}

QTEST_GUILESS_MAIN(FollowUpReminderInfoTest)
