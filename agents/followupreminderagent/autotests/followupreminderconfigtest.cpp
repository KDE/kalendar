/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "followupreminderconfigtest.h"
#include "../followupreminderinfo.h"
#include "../followupreminderutil.h"

#include <QStandardPaths>
#include <QTest>

FollowUpReminderConfigTest::FollowUpReminderConfigTest(QObject *parent)
    : QObject(parent)
{
    QStandardPaths::setTestModeEnabled(true);
}

FollowUpReminderConfigTest::~FollowUpReminderConfigTest() = default;

void FollowUpReminderConfigTest::init()
{
    mConfig = KSharedConfig::openConfig(QStringLiteral("test-followupreminder.rc"), KConfig::SimpleConfig);
    mFollowupRegExpFilter = QRegularExpression(QStringLiteral("FollowupReminderItem \\d+"));
    cleanup();
}

void FollowUpReminderConfigTest::cleanup()
{
    const QStringList filterGroups = mConfig->groupList();
    for (const QString &group : filterGroups) {
        mConfig->deleteGroup(group);
    }
    mConfig->sync();
    mConfig->reparseConfiguration();
}

void FollowUpReminderConfigTest::cleanupTestCase()
{
    // Make sure to clean config
    cleanup();
}

void FollowUpReminderConfigTest::shouldConfigBeEmpty()
{
    const QStringList filterGroups = mConfig->groupList();
    QCOMPARE(filterGroups.isEmpty(), true);
}

void FollowUpReminderConfigTest::shouldAddAnItem()
{
    FollowUpReminder::FollowUpReminderInfo info;
    info.setMessageId(QStringLiteral("foo"));
    const QDate date(2014, 1, 1);
    info.setFollowUpReminderDate(QDate(date));
    const QString to = QStringLiteral("kde.org");
    info.setTo(to);
    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &info, false);
    const QStringList itemList = mConfig->groupList().filter(mFollowupRegExpFilter);

    QCOMPARE(itemList.isEmpty(), false);
    QCOMPARE(itemList.count(), 1);
    QCOMPARE(mConfig->hasGroup(QStringLiteral("General")), true);
}

void FollowUpReminderConfigTest::shouldNotAddAnInvalidItem()
{
    FollowUpReminder::FollowUpReminderInfo info;
    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &info, false);
    const QStringList itemList = mConfig->groupList().filter(mFollowupRegExpFilter);
    QCOMPARE(itemList.isEmpty(), true);
}

void FollowUpReminderConfigTest::shouldReplaceItem()
{
    FollowUpReminder::FollowUpReminderInfo info;
    info.setMessageId(QStringLiteral("foo"));
    const QDate date(2014, 1, 1);
    info.setFollowUpReminderDate(QDate(date));
    const QString to = QStringLiteral("kde.org");
    info.setTo(to);
    qint32 uniq = 42;
    info.setUniqueIdentifier(uniq);
    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &info, false);
    QStringList itemList = mConfig->groupList().filter(mFollowupRegExpFilter);

    QCOMPARE(itemList.count(), 1);

    info.setTo(QStringLiteral("kmail.org"));
    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &info, false);
    itemList = mConfig->groupList().filter(mFollowupRegExpFilter);
    QCOMPARE(itemList.count(), 1);
}

void FollowUpReminderConfigTest::shouldAddSeveralItem()
{
    FollowUpReminder::FollowUpReminderInfo info;
    info.setMessageId(QStringLiteral("foo"));
    const QDate date(2014, 1, 1);
    info.setFollowUpReminderDate(QDate(date));
    const QString to = QStringLiteral("kde.org");
    info.setTo(to);
    qint32 uniq = 42;
    info.setUniqueIdentifier(uniq);
    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &info, false);
    QStringList itemList = mConfig->groupList().filter(mFollowupRegExpFilter);

    QCOMPARE(itemList.count(), 1);

    info.setTo(QStringLiteral("kmail.org"));
    uniq = 43;
    info.setUniqueIdentifier(uniq);
    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &info, false);
    itemList = mConfig->groupList().filter(mFollowupRegExpFilter);
    QCOMPARE(itemList.count(), 2);

    uniq = 44;
    info.setUniqueIdentifier(uniq);
    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &info, false);
    itemList = mConfig->groupList().filter(mFollowupRegExpFilter);
    QCOMPARE(itemList.count(), 3);

    // Replace It

    info.setUniqueIdentifier(uniq);
    info.setTo(QStringLiteral("kontact.org"));
    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &info, false);
    itemList = mConfig->groupList().filter(mFollowupRegExpFilter);
    QCOMPARE(itemList.count(), 3);

    // Add item without uniqIdentifier
    FollowUpReminder::FollowUpReminderInfo infoNotHaveUniq;
    infoNotHaveUniq.setMessageId(QStringLiteral("foo"));
    infoNotHaveUniq.setFollowUpReminderDate(QDate(date));
    infoNotHaveUniq.setTo(to);

    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &infoNotHaveUniq, false);
    itemList = mConfig->groupList().filter(mFollowupRegExpFilter);
    QCOMPARE(itemList.count(), 4);
    QCOMPARE(infoNotHaveUniq.uniqueIdentifier(), 4);
}

void FollowUpReminderConfigTest::shouldRemoveItems()
{
    FollowUpReminder::FollowUpReminderInfo info;
    info.setMessageId(QStringLiteral("foo"));
    const QDate date(2014, 1, 1);
    info.setFollowUpReminderDate(QDate(date));
    const QString to = QStringLiteral("kde.org");
    info.setTo(to);
    qint32 uniq = 42;
    info.setUniqueIdentifier(uniq);
    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &info, false);
    QStringList itemList = mConfig->groupList().filter(mFollowupRegExpFilter);
    QCOMPARE(itemList.count(), 1);

    info.setTo(QStringLiteral("kmail.org"));
    uniq = 43;
    info.setUniqueIdentifier(uniq);
    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &info, false);
    itemList = mConfig->groupList().filter(mFollowupRegExpFilter);
    QCOMPARE(itemList.count(), 2);

    uniq = 44;
    info.setUniqueIdentifier(uniq);
    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &info, false);
    itemList = mConfig->groupList().filter(mFollowupRegExpFilter);
    QCOMPARE(itemList.count(), 3);

    // Add item without uniqIdentifier
    FollowUpReminder::FollowUpReminderInfo infoNotHaveUniq;
    infoNotHaveUniq.setMessageId(QStringLiteral("foo"));
    infoNotHaveUniq.setFollowUpReminderDate(QDate(date));
    infoNotHaveUniq.setTo(to);

    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &infoNotHaveUniq, false);
    itemList = mConfig->groupList().filter(mFollowupRegExpFilter);
    QCOMPARE(itemList.count(), 4);
    QCOMPARE(infoNotHaveUniq.uniqueIdentifier(), 3);

    QList<qint32> listRemove;
    listRemove << 43 << 42;

    const bool elementRemoved = FollowUpReminder::FollowUpReminderUtil::removeFollowupReminderInfo(mConfig, listRemove);
    itemList = mConfig->groupList().filter(mFollowupRegExpFilter);
    QCOMPARE(itemList.count(), 2);
    QVERIFY(elementRemoved);
}

void FollowUpReminderConfigTest::shouldNotRemoveItemWhenListIsEmpty()
{
    QList<qint32> listRemove;
    const bool elementRemoved = FollowUpReminder::FollowUpReminderUtil::removeFollowupReminderInfo(mConfig, listRemove);
    QVERIFY(!elementRemoved);
}

void FollowUpReminderConfigTest::shouldNotRemoveItemWhenItemDoesntExist()
{
    FollowUpReminder::FollowUpReminderInfo info;
    info.setMessageId(QStringLiteral("foo"));
    const QDate date(2014, 1, 1);
    info.setFollowUpReminderDate(QDate(date));
    const QString to = QStringLiteral("kde.org");
    info.setTo(to);
    qint32 uniq = 42;
    info.setUniqueIdentifier(uniq);
    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &info, false);
    QStringList itemList = mConfig->groupList().filter(mFollowupRegExpFilter);

    info.setTo(QStringLiteral("kmail.org"));
    uniq = 43;
    info.setUniqueIdentifier(uniq);
    QCOMPARE(itemList.count(), 1);
    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &info, false);
    itemList = mConfig->groupList().filter(mFollowupRegExpFilter);
    QCOMPARE(itemList.count(), 2);

    uniq = 44;
    info.setUniqueIdentifier(uniq);
    FollowUpReminder::FollowUpReminderUtil::writeFollowupReminderInfo(mConfig, &info, false);

    QList<qint32> listRemove;
    listRemove << 55 << 75;
    const bool elementRemoved = FollowUpReminder::FollowUpReminderUtil::removeFollowupReminderInfo(mConfig, listRemove);
    QVERIFY(!elementRemoved);
}

QTEST_MAIN(FollowUpReminderConfigTest)
