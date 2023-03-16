// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#include "../remindersmodel.h"
#include <QObject>
#include <QtTest/QtTest>

class RemindersModelTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase()
    {
    }

    void testReading()
    {
        KCalendarCore::Incidence::Ptr incidence(new KCalendarCore::Event());
        incidence->setSummary(QLatin1String("LOREM"));

        RemindersModel model;
        model.setIncidence(incidence);

        model.addAlarm();
        model.addAlarm();
        QCOMPARE(model.rowCount(), 2);

        model.deleteAlarm(0);
        QCOMPARE(model.rowCount(), 1);

        QCOMPARE(model.data(model.index(0), RemindersModel::TypeRole).toInt(), KCalendarCore::Alarm::Display);

        QCOMPARE(model.data(model.index(0), RemindersModel::SummaryRole).toString(), QStringLiteral("LOREM"));

        QCOMPARE(model.data(model.index(0), RemindersModel::StartOffsetRole).toInt(), 0);

        model.setData(model.index(0), 20, RemindersModel::StartOffsetRole);

        QCOMPARE(model.data(model.index(0), RemindersModel::StartOffsetRole).toInt(), 20);
    }
};

QTEST_MAIN(RemindersModelTest)
#include "remindersmodeltest.moc"
