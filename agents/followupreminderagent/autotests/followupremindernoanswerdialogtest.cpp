/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "followupremindernoanswerdialogtest.h"
#include "../followupreminderinfo.h"
#include "../followupreminderinfowidget.h"
#include "../followupremindernoanswerdialog.h"

#include <QStandardPaths>
#include <QTest>
#include <QTreeWidget>

FollowupReminderNoAnswerDialogTest::FollowupReminderNoAnswerDialogTest(QObject *parent)
    : QObject(parent)
{
}

FollowupReminderNoAnswerDialogTest::~FollowupReminderNoAnswerDialogTest() = default;

void FollowupReminderNoAnswerDialogTest::initTestCase()
{
    QStandardPaths::setTestModeEnabled(true);
}

void FollowupReminderNoAnswerDialogTest::shouldHaveDefaultValues()
{
    FollowUpReminderNoAnswerDialog dlg;
    auto infowidget = dlg.findChild<FollowUpReminderInfoWidget *>(QStringLiteral("FollowUpReminderInfoWidget"));
    QVERIFY(infowidget);

    auto treeWidget = infowidget->findChild<QTreeWidget *>(QStringLiteral("treewidget"));
    QVERIFY(treeWidget);

    QCOMPARE(treeWidget->topLevelItemCount(), 0);
}

void FollowupReminderNoAnswerDialogTest::shouldAddItemInTreeList()
{
    FollowUpReminderNoAnswerDialog dlg;
    auto infowidget = dlg.findChild<FollowUpReminderInfoWidget *>(QStringLiteral("FollowUpReminderInfoWidget"));
    auto treeWidget = infowidget->findChild<QTreeWidget *>(QStringLiteral("treewidget"));
    QList<FollowUpReminder::FollowUpReminderInfo *> lstInfo;
    lstInfo.reserve(10);
    for (int i = 0; i < 10; ++i) {
        auto info = new FollowUpReminder::FollowUpReminderInfo();
        lstInfo.append(info);
    }
    dlg.setInfo(lstInfo);
    // We load invalid infos.
    QCOMPARE(treeWidget->topLevelItemCount(), 0);
    lstInfo.clear();

    // Load valid infos
    for (int i = 0; i < 10; ++i) {
        auto info = new FollowUpReminder::FollowUpReminderInfo();
        info->setOriginalMessageItemId(42);
        info->setMessageId(QStringLiteral("foo"));
        info->setFollowUpReminderDate(QDate::currentDate());
        info->setTo(QStringLiteral("To"));
        lstInfo.append(info);
    }

    dlg.setInfo(lstInfo);
    QCOMPARE(treeWidget->topLevelItemCount(), 10);
}

void FollowupReminderNoAnswerDialogTest::shouldItemHaveInfo()
{
    FollowUpReminderNoAnswerDialog dlg;
    auto infowidget = dlg.findChild<FollowUpReminderInfoWidget *>(QStringLiteral("FollowUpReminderInfoWidget"));
    auto treeWidget = infowidget->findChild<QTreeWidget *>(QStringLiteral("treewidget"));
    QList<FollowUpReminder::FollowUpReminderInfo *> lstInfo;

    // Load valid infos
    for (int i = 0; i < 10; ++i) {
        auto info = new FollowUpReminder::FollowUpReminderInfo();
        info->setOriginalMessageItemId(42);
        info->setMessageId(QStringLiteral("foo"));
        info->setFollowUpReminderDate(QDate::currentDate());
        info->setTo(QStringLiteral("To"));
        lstInfo.append(info);
    }

    dlg.setInfo(lstInfo);
    for (int i = 0; i < treeWidget->topLevelItemCount(); ++i) {
        auto item = static_cast<FollowUpReminderInfoItem *>(treeWidget->topLevelItem(i));
        QVERIFY(item->info());
        QVERIFY(item->info()->isValid());
    }
}

QTEST_MAIN(FollowupReminderNoAnswerDialogTest)
