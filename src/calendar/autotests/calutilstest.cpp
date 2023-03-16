// SPDX-FileCopyrightText: 2023 Joshua Goins <josh@redstrate.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "../utils.h"

#include <QSignalSpy>
#include <QTest>

class CalendarUtilsTest : public QObject
{
    Q_OBJECT

public:
    CalendarUtilsTest() = default;
    ~CalendarUtilsTest() override = default;

private:
    Utils utils;

private Q_SLOTS:
    void initTestCase()
    {
    }

    void testRemindersLabel()
    {
        QCOMPARE(utils.secondsToReminderLabel(0), QStringLiteral("On event start"));

        QCOMPARE(utils.secondsToReminderLabel(300), QStringLiteral("5 minutes after start of event"));
        QCOMPARE(utils.secondsToReminderLabel(7200), QStringLiteral("2 hours after start of event"));
        QCOMPARE(utils.secondsToReminderLabel(259200), QStringLiteral("3 days after start of event"));

        QCOMPARE(utils.secondsToReminderLabel(-300), QStringLiteral("5 minutes before start of event"));
        QCOMPARE(utils.secondsToReminderLabel(-7200), QStringLiteral("2 hours before start of event"));
        QCOMPARE(utils.secondsToReminderLabel(-259200), QStringLiteral("3 days before start of event"));
    }
};

QTEST_MAIN(CalendarUtilsTest)
#include "calutilstest.moc"
