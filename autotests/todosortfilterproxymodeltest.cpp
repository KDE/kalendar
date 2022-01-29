// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "../src/models/todosortfilterproxymodel.h"

#include <Akonadi/Calendar/IncidenceChanger>
#include <KCalendarCore/Incidence>
#include <KCheckableProxyModel>
#include <KFormat>
#include <QAbstractItemModelTester>
#include <QSignalSpy>
#include <QTest>
#include <akonadi/qtest_akonadi.h>

class TodoSortFilterProxyModelTest : public QObject
{
    Q_OBJECT

public:
    TodoSortFilterProxyModelTest() = default;
    ~TodoSortFilterProxyModelTest() = default;

    void checkAllItems(KCheckableProxyModel *model, const QModelIndex &parent = QModelIndex())
    {
        const int rowCount = model->rowCount(parent);
        for (int row = 0; row < rowCount; ++row) {
            QModelIndex index = model->index(row, 0, parent);
            model->setData(index, Qt::Checked, Qt::CheckStateRole);

            if (model->rowCount(index) > 0) {
                checkAllItems(model, index);
            }
        }
    }

signals:
    void calendarLoaded();

private:
    Akonadi::ETMCalendar::Ptr calendar;
    TodoSortFilterProxyModel model;
    QAbstractItemModelTester modelTester = QAbstractItemModelTester(&model);
    QTimer loadedCheckTimer;
    QDateTime now = QDate(2022, 01, 10).startOfDay();

private slots:
    void initTestCase()
    {
        AkonadiTest::checkTestIsIsolated();

        calendar.reset(new Akonadi::ETMCalendar);
        QSignalSpy collectionsAdded(calendar.data(), &Akonadi::ETMCalendar::collectionsAdded);
        QVERIFY(collectionsAdded.wait(10000));

        loadedCheckTimer.setInterval(300);
        loadedCheckTimer.setSingleShot(true);
        connect(&loadedCheckTimer, &QTimer::timeout, this, [&]() {
            if (calendar->isLoaded()) {
                Q_EMIT calendarLoaded();
            } else {
                loadedCheckTimer.start();
            }
        });

        QSignalSpy loaded(this, &TodoSortFilterProxyModelTest::calendarLoaded);
        loaded.wait(10000);
        checkAllItems(calendar->checkableProxyModel());
    }

    void testAddCalendar()
    {
        QVERIFY(calendar->isLoaded());
        QVERIFY(calendar->items().count() > 0);

        QSignalSpy fetchFinished(&model, &QAbstractItemModel::modelReset);

        model.setCalendar(calendar);
        QCOMPARE(model.calendar()->id(), calendar->id());

        fetchFinished.wait(10000);
        // Our test calendar file has an event that recurs every day of the week.
        // Since we are checking for 7 days, we should have an instance of this event
        // 7 times.
        // QCOMPARE(model.rowCount(), 2);
    }
};

QTEST_MAIN(TodoSortFilterProxyModelTest)
#include "todosortfilterproxymodeltest.moc"
