// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "../src/models/incidenceoccurrencemodel.h"

#include <Akonadi/Calendar/IncidenceChanger>
#include <KCalendarCore/Incidence>
#include <KCheckableProxyModel>
#include <KFormat>
#include <QAbstractItemModelTester>
#include <QSignalSpy>
#include <QTest>
#include <akonadi/qtest_akonadi.h>

class IncidenceOccurrenceModelTest : public QObject
{
    Q_OBJECT

public:
    IncidenceOccurrenceModelTest() = default;
    ~IncidenceOccurrenceModelTest() = default;

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
    IncidenceOccurrenceModel model;
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

        QSignalSpy loaded(this, &IncidenceOccurrenceModelTest::calendarLoaded);
        loaded.wait(10000);
        checkAllItems(calendar->checkableProxyModel());
    }

    void testAddCalendar()
    {
        QVERIFY(calendar->isLoaded());
        QVERIFY(calendar->items().count() > 0);

        QSignalSpy fetchFinished(&model, &QAbstractItemModel::modelReset);

        model.setStart(now.date());
        QCOMPARE(model.start(), now.date());
        model.setLength(7);
        QCOMPARE(model.length(), 7);
        model.setCalendar(calendar);
        QCOMPARE(model.calendar()->id(), calendar->id());

        fetchFinished.wait(10000);
        // Our test calendar file has an event that recurs every day of the week.
        // Since we are checking for 7 days, we should have an instance of this event
        // 7 times.
        QCOMPARE(model.rowCount(), 7);
    }

    void testData()
    {
        // Check everything is still there from the previous test
        QCOMPARE(model.rowCount(), 7);

        // Test that the data function gives us the event info we have in our calendar file
        const auto index = model.index(0, 0);
        QCOMPARE(index.data(IncidenceOccurrenceModel::Summary).toString(), QStringLiteral("Test event"));
        QCOMPARE(index.data(IncidenceOccurrenceModel::Description).toString(), QStringLiteral("Big testing description"));
        QCOMPARE(index.data(IncidenceOccurrenceModel::Location).toString(), QStringLiteral("Testing land"));

        // It's an all day event
        QDateTime eventStartTimeToday(now.date().startOfDay());
        QCOMPARE(index.data(IncidenceOccurrenceModel::StartTime).toDateTime().toMSecsSinceEpoch(), eventStartTimeToday.toMSecsSinceEpoch());
        QCOMPARE(index.data(IncidenceOccurrenceModel::EndTime).toDateTime().toMSecsSinceEpoch(), eventStartTimeToday.addDays(1).toMSecsSinceEpoch());

        const auto duration = index.data(IncidenceOccurrenceModel::Duration).value<KCalendarCore::Duration>();
        QCOMPARE(duration.asDays(), 1);
        KFormat format;
        QCOMPARE(index.data(IncidenceOccurrenceModel::DurationString).toString(), format.formatSpelloutDuration(duration.asSeconds() * 1000));

        QVERIFY(index.data(IncidenceOccurrenceModel::Recurs).toBool());
        QVERIFY(index.data(IncidenceOccurrenceModel::HasReminders).toBool());
        QCOMPARE(index.data(IncidenceOccurrenceModel::Priority).toInt(), 0);
        QVERIFY(index.data(IncidenceOccurrenceModel::AllDay).toBool());

        // CalendarManager generates the colors for different collections so let's skip that check, since it will give invalid

        QVERIFY(index.data(IncidenceOccurrenceModel::CollectionId).canConvert<qlonglong>());

        QVERIFY(!index.data(IncidenceOccurrenceModel::TodoCompleted).toBool()); // An event should always return false for this
        QVERIFY(!index.data(IncidenceOccurrenceModel::IsOverdue).toBool());
        QVERIFY(!index.data(IncidenceOccurrenceModel::IsReadOnly).toBool());

        QVERIFY(!index.data(IncidenceOccurrenceModel::IncidenceId).toString().isNull());
        QCOMPARE(index.data(IncidenceOccurrenceModel::IncidenceType).toInt(), KCalendarCore::Incidence::TypeEvent);
        QCOMPARE(index.data(IncidenceOccurrenceModel::IncidenceTypeStr).toString(), QStringLiteral("Event"));

        QVERIFY(index.data(IncidenceOccurrenceModel::IncidencePtr).canConvert<KCalendarCore::Incidence::Ptr>());
        QVERIFY(index.data(IncidenceOccurrenceModel::IncidenceOccurrence).canConvert<IncidenceOccurrenceModel::Occurrence>());
    }

    void testNewIncidenceAdded()
    {
        // Check everything is still there from the previous test
        QCOMPARE(model.rowCount(), 7);

        const auto collectionId = model.index(0, 0).data(IncidenceOccurrenceModel::CollectionId).toLongLong();
        const auto collection = calendar->collection(collectionId);
        QVERIFY(collection.isValid());

        KCalendarCore::Todo::Ptr todo(new KCalendarCore::Todo);
        todo->setSummary(QStringLiteral("Test todo"));
        todo->setCompleted(true);
        todo->setDtStart(now.addDays(1));
        todo->setDtDue(now.addDays(1));
        todo->setPriority(1);
        todo->setCategories(QStringLiteral("Tag 2"));

        QSignalSpy createFinished(calendar->incidenceChanger(), &Akonadi::IncidenceChanger::createFinished);
        QVERIFY(calendar->incidenceChanger()->createIncidence(todo, collection) != -1);
        QVERIFY(createFinished.wait(5000));

        QSignalSpy loaded(this, &IncidenceOccurrenceModelTest::calendarLoaded);
        loadedCheckTimer.start();
        loaded.wait(10000);

        QCOMPARE(model.rowCount(), 8);
    }

    void testTodoData()
    {
        QCOMPARE(model.rowCount(), 8);

        QModelIndex todoIndex;

        for (int i = 0; i < model.rowCount(); ++i) {
            const auto index = model.index(i, 0);
            if (index.data(IncidenceOccurrenceModel::IncidenceType).toInt() == KCalendarCore::Incidence::TypeTodo) {
                todoIndex = index;
            }
        }

        QVERIFY(todoIndex.data(IncidenceOccurrenceModel::TodoCompleted).toBool());

        bool shouldBeOverDue = todoIndex.data(IncidenceOccurrenceModel::EndTime).toDateTime() > QDateTime::currentDateTime();
        QCOMPARE(todoIndex.data(IncidenceOccurrenceModel::IsOverdue).toBool(), shouldBeOverDue);
        QCOMPARE(todoIndex.data(IncidenceOccurrenceModel::Priority).toInt(), 1);
    }

    void testFilter()
    {
        QVariantMap filter;
        filter[QStringLiteral("tags")] = QStringList(QStringLiteral("Tag 2"));

        QSignalSpy fetchFinished(&model, &QAbstractItemModel::modelReset);
        model.setFilter(filter);
        QCOMPARE(model.filter(), filter);
        fetchFinished.wait(10000);

        QCOMPARE(model.rowCount(), 1);

        model.setFilter({});
        fetchFinished.wait(10000);
        QCOMPARE(model.rowCount(), 8);
    }
};

QTEST_MAIN(IncidenceOccurrenceModelTest)
#include "incidenceoccurrencemodeltest.moc"
