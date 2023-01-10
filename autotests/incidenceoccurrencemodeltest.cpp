// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "../src/models/incidenceoccurrencemodel.h"

#include "../src/filter.h"
#include "../src/utils.h"
#include <Akonadi/IncidenceChanger>
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
    ~IncidenceOccurrenceModelTest() override = default;

    bool standardSetupModel(IncidenceOccurrenceModel &model)
    {
        QSignalSpy loadingChanged(&model, &IncidenceOccurrenceModel::loadingChanged);

        model.setStart(m_now.date());
        model.setLength(m_testModelLength);
        model.setCalendar(m_calendar);

        return loadingChanged.wait(3000) && !model.loading() && model.rowCount() == m_expectedIncidenceCount;
    }

    bool addTestTodo(const IncidenceOccurrenceModel &model)
    {
        const auto modelRowCount = model.rowCount();

        QSignalSpy loadingChanged(&model, &IncidenceOccurrenceModel::loadingChanged);
        QSignalSpy createFinished(m_calendar->incidenceChanger(), &Akonadi::IncidenceChanger::createFinished);

        const auto createResult = m_calendar->incidenceChanger()->createIncidence(m_testTodo, m_testCollection);

        return createResult != -1 && createFinished.wait(3000) && loadingChanged.wait(3000) && !model.loading() && model.rowCount() == modelRowCount + 1;
    }

public Q_SLOTS:
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

    void resetCalendar()
    {
        QSignalSpy deleteFinished(m_calendar.data(), &Akonadi::ETMCalendar::deleteFinished);

        if (const auto todoExists = m_calendar->todo(m_testTodo->uid())) {
            m_calendar->deleteIncidence(m_testTodo);
            deleteFinished.wait(2000);
        }
    }

private:
    Akonadi::ETMCalendar::Ptr m_calendar;
    KCalendarCore::Todo::Ptr m_testTodo;
    Akonadi::Collection m_testCollection;
    Filter m_testFilter;

    const QString m_testTag = QStringLiteral("Tag 2");
    const QDateTime m_now = QDate(2022, 01, 10).startOfDay();
    static constexpr auto m_testModelLength = 7;

    // Our test calendar file has an event that recurs every day.
    // This event is an all-day event that covers two full days.
    //
    // That means we will always have one more occurrence than the model length
    // as we will get overlap from the occurrence that starts a day before the
    // model's start date and ends on the day the model starts.
    static constexpr auto m_expectedIncidenceCount = m_testModelLength + 1;

private Q_SLOTS:
    void initTestCase()
    {
        AkonadiTest::checkTestIsIsolated();

        m_calendar.reset(new Akonadi::ETMCalendar);
        QSignalSpy collectionsAdded(m_calendar.data(), &Akonadi::ETMCalendar::collectionsAdded);
        QVERIFY(collectionsAdded.wait(10000));

        QSignalSpy calendarChanged(m_calendar.data(), &Akonadi::ETMCalendar::calendarChanged);
        QVERIFY(calendarChanged.wait(10000));
        checkAllItems(m_calendar->checkableProxyModel());

        QVERIFY(!m_calendar->isLoading());
        QVERIFY(m_calendar->items().count() > 0);

        // Grab the collection we are using for testing
        const auto firstCollectionAddedEmitted = collectionsAdded.first();
        const auto collectionsList = firstCollectionAddedEmitted.first().value<Akonadi::Collection::List>();
        m_testCollection = collectionsList.first();
        QVERIFY(m_testCollection.isValid());

        m_testTodo.reset(new KCalendarCore::Todo);
        m_testTodo->setSummary(QStringLiteral("Test todo"));
        m_testTodo->setCompleted(true);
        m_testTodo->setDtStart(m_now.addDays(1));
        m_testTodo->setDtDue(m_now.addDays(1));
        m_testTodo->setPriority(1);
        m_testTodo->setCategories(m_testTag);
        m_testTodo->setUid(QStringLiteral("__test_todo__"));

        m_testFilter.setTags({m_testTag});
    }

    void testModelSettableProperties()
    {
        resetCalendar();

        IncidenceOccurrenceModel model;
        QSignalSpy startChanged(&model, &IncidenceOccurrenceModel::startChanged);
        QSignalSpy lengthChanged(&model, &IncidenceOccurrenceModel::lengthChanged);
        QSignalSpy calendarChanged(&model, &IncidenceOccurrenceModel::calendarChanged);
        QSignalSpy filterChanged(&model, &IncidenceOccurrenceModel::filterChanged);
        QSignalSpy resetThrottleIntervalChanged(&model, &IncidenceOccurrenceModel::resetThrottleIntervalChanged);
        static constexpr auto testRefreshIntervalThrottle = 200;

        model.setStart(m_now.date());
        QCOMPARE(model.start(), m_now.date());
        QCOMPARE(startChanged.count(), 1);

        model.setLength(m_testModelLength);
        QCOMPARE(model.length(), m_testModelLength);
        QCOMPARE(lengthChanged.count(), 1);

        model.setCalendar(m_calendar);
        QCOMPARE(model.calendar(), m_calendar);
        QCOMPARE(calendarChanged.count(), 1);

        model.setFilter(&m_testFilter);
        QCOMPARE(model.filter(), &m_testFilter);
        QCOMPARE(filterChanged.count(), 1);

        model.setResetThrottleInterval(testRefreshIntervalThrottle);
        QCOMPARE(model.resetThrottleInterval(), testRefreshIntervalThrottle);
        QCOMPARE(resetThrottleIntervalChanged.count(), 1);
    }

    void testLoadingSignalling()
    {
        resetCalendar();

        IncidenceOccurrenceModel model;
        QAbstractItemModelTester modelTester(&model);

        QSignalSpy loadingChanged(&model, &IncidenceOccurrenceModel::loadingChanged);

        // Setting each of these props triggers a reset to be scheduled,
        // but until a calendar is set nothing should happen. Let's check.
        // Wait for at least the time it takes for the throttler to let a reset happen
        const auto signalWaitTime = model.resetThrottleInterval() + 1; // To be safe
        model.setStart(m_now.date());
        model.setLength(m_testModelLength);
        QVERIFY(!loadingChanged.wait(signalWaitTime));
        QCOMPARE(loadingChanged.count(), 0);
        QVERIFY(!model.loading());

        // We now set the calendar so we expect loading state to change.
        // The model does not do things asynchronously, so by the time we
        // get a signal both the loading start and the loading end change
        // signals have been emitted
        model.setCalendar(m_calendar);
        QVERIFY(loadingChanged.wait(signalWaitTime + 3000));
        QCOMPARE(loadingChanged.count(), 2);
        QVERIFY(!model.loading());
    }

    void testAddCalendar()
    {
        resetCalendar();

        IncidenceOccurrenceModel model;
        QAbstractItemModelTester modelTester(&model);
        QSignalSpy loadingChanged(&model, &IncidenceOccurrenceModel::loadingChanged);

        model.setStart(m_now.date());
        model.setLength(m_testModelLength);
        model.setCalendar(m_calendar);

        // Don't use standardSetupModel -- let's see where exactly things go wrong
        QVERIFY(loadingChanged.wait(3000));
        QCOMPARE(loadingChanged.count(), 2);
        QVERIFY(!model.loading());

        QCOMPARE(model.rowCount(), m_expectedIncidenceCount);
    }

    void testData()
    {
        resetCalendar();

        IncidenceOccurrenceModel model;
        QAbstractItemModelTester modelTester(&model);
        QVERIFY(standardSetupModel(model));
        QCOMPARE(model.rowCount(), m_expectedIncidenceCount);

        // Test that the data function gives us the event info we have in our calendar file
        const auto index = model.index(0, 0);
        QCOMPARE(index.data(IncidenceOccurrenceModel::Summary).toString(), QStringLiteral("Test event"));
        QCOMPARE(index.data(IncidenceOccurrenceModel::Description).toString(), QStringLiteral("Big testing description"));
        QCOMPARE(index.data(IncidenceOccurrenceModel::Location).toString(), QStringLiteral("Testing land"));

        // It's an all day event
        QDateTime eventStartTimeToday(m_now.date().startOfDay());
        QCOMPARE(index.data(IncidenceOccurrenceModel::StartTime).toDateTime().toMSecsSinceEpoch(), eventStartTimeToday.toMSecsSinceEpoch());
        QCOMPARE(index.data(IncidenceOccurrenceModel::EndTime).toDateTime().toMSecsSinceEpoch(), eventStartTimeToday.addDays(1).toMSecsSinceEpoch());

        const auto duration = index.data(IncidenceOccurrenceModel::Duration).value<KCalendarCore::Duration>();
        QCOMPARE(duration.asDays(), 1);
        KFormat format;
        QCOMPARE(index.data(IncidenceOccurrenceModel::DurationString).toString(), Utils::formatSpelloutDuration(duration, format, true));

        QVERIFY(index.data(IncidenceOccurrenceModel::Recurs).toBool());
        QVERIFY(index.data(IncidenceOccurrenceModel::HasReminders).toBool());
        QCOMPARE(index.data(IncidenceOccurrenceModel::Priority).toInt(), 0);
        QVERIFY(index.data(IncidenceOccurrenceModel::AllDay).toBool());

        // CalendarManager generates the colors for different collections so let's skip that check, since it will give invalid

        QVERIFY(index.data(IncidenceOccurrenceModel::CollectionId).canConvert<Akonadi::Collection::Id>());

        QVERIFY(!index.data(IncidenceOccurrenceModel::TodoCompleted).toBool()); // An event should always return false for this
        QVERIFY(!index.data(IncidenceOccurrenceModel::IsOverdue).toBool());
        QVERIFY(!index.data(IncidenceOccurrenceModel::IsReadOnly).toBool());

        QVERIFY(!index.data(IncidenceOccurrenceModel::IncidenceId).toString().isNull());
        QCOMPARE(index.data(IncidenceOccurrenceModel::IncidenceType).toInt(), KCalendarCore::Incidence::TypeEvent);
        QCOMPARE(index.data(IncidenceOccurrenceModel::IncidenceTypeStr).toString(), QStringLiteral("Event"));

        QVERIFY(index.data(IncidenceOccurrenceModel::IncidencePtr).canConvert<KCalendarCore::Incidence::Ptr>());
        QVERIFY(index.data(IncidenceOccurrenceModel::IncidenceOccurrence).canConvert<IncidenceOccurrenceModel::Occurrence>());
    }

    void testIncidenceAdded()
    {
        resetCalendar();

        IncidenceOccurrenceModel model;
        QAbstractItemModelTester modelTester(&model);
        QVERIFY(standardSetupModel(model));
        QCOMPARE(model.rowCount(), m_expectedIncidenceCount);

        // Let's not use the addTestTodo helper so we get information on where exactly things broke
        // We want to make sure that we get both the final loadingChanged signal as well as the model's
        // row inserted signal.
        QSignalSpy createFinished(m_calendar->incidenceChanger(), &Akonadi::IncidenceChanger::createFinished);
        QSignalSpy loadingChanged(&model, &IncidenceOccurrenceModel::loadingChanged);
        QSignalSpy rowsInserted(&model, &IncidenceOccurrenceModel::rowsInserted);

        QVERIFY(m_calendar->incidenceChanger()->createIncidence(m_testTodo, m_testCollection) != -1);
        QVERIFY(createFinished.wait(5000));

        QVERIFY(loadingChanged.wait(3000));
        QVERIFY(!model.loading());

        QCOMPARE(rowsInserted.count(), 1);
        QCOMPARE(model.rowCount(), m_expectedIncidenceCount + 1);
    }

    void testIncidenceRemoved()
    {
        resetCalendar();

        IncidenceOccurrenceModel model;
        QAbstractItemModelTester modelTester(&model);
        QVERIFY(standardSetupModel(model));
        QCOMPARE(model.rowCount(), m_expectedIncidenceCount);

        // First add the test todo...
        QVERIFY(addTestTodo(model));

        // Then remove it and verify the incidence occurrence model reflects the change
        QSignalSpy deleteFinished(m_calendar.data(), &Akonadi::ETMCalendar::deleteFinished);
        QSignalSpy loadingChanged(&model, &IncidenceOccurrenceModel::loadingChanged);

        resetCalendar();

        QVERIFY(loadingChanged.wait(3000));
        // Should only load once, but we are beholden to the sourceModel's behaviour
        loadingChanged.wait(3000);
        QVERIFY(!model.loading());

        QCOMPARE(model.rowCount(), m_expectedIncidenceCount);
    }

    void testIncidenceDataChanged()
    {
        resetCalendar();

        IncidenceOccurrenceModel model;
        QAbstractItemModelTester modelTester(&model);
        QVERIFY(standardSetupModel(model));
        QCOMPARE(model.rowCount(), m_expectedIncidenceCount);

        // First add the test todo...
        QVERIFY(addTestTodo(model));

        // Now let's create a copy and modify it
        const KCalendarCore::Todo::Ptr todoClone(m_testTodo->clone());
        const auto newSummary = QStringLiteral("New summary!");
        todoClone->setSummary(newSummary);

        // Then try modifying it
        QSignalSpy modifyFinished(m_calendar.data(), &Akonadi::ETMCalendar::modifyFinished);
        QSignalSpy loadingChanged(&model, &IncidenceOccurrenceModel::loadingChanged);
        QSignalSpy dataChanged(&model, &IncidenceOccurrenceModel::dataChanged);

        m_calendar->modifyIncidence(todoClone);
        QVERIFY(modifyFinished.wait(3000));

        QVERIFY(loadingChanged.wait(3000));
        QVERIFY(!model.loading());

        // FIXME: Currently the model emits more dataChanged signals than needed
        QVERIFY(dataChanged.count() > 0);
        const auto dataChangedSignalEmitted = dataChanged.first();
        const auto dataChangedIndex = dataChangedSignalEmitted.first().toModelIndex();
        QVERIFY(dataChangedIndex.isValid());
        QCOMPARE(dataChangedIndex.data(IncidenceOccurrenceModel::Summary).toString(), newSummary);
    }

    void testTodoData()
    {
        resetCalendar();

        IncidenceOccurrenceModel model;
        QAbstractItemModelTester modelTester(&model);
        QVERIFY(standardSetupModel(model));
        QCOMPARE(model.rowCount(), m_expectedIncidenceCount);

        QVERIFY(addTestTodo(model));

        const auto todoIndex = model.index(model.rowCount() - 1, 0);
        QVERIFY(todoIndex.data(IncidenceOccurrenceModel::TodoCompleted).toBool());

        const auto shouldBeOverDue = todoIndex.data(IncidenceOccurrenceModel::EndTime).toDateTime() > QDateTime::currentDateTime();
        QCOMPARE(todoIndex.data(IncidenceOccurrenceModel::IsOverdue).toBool(), shouldBeOverDue);
        QCOMPARE(todoIndex.data(IncidenceOccurrenceModel::Priority).toInt(), 1);
    }

    void testFiltering()
    {
        resetCalendar();

        IncidenceOccurrenceModel model;
        QAbstractItemModelTester modelTester(&model);
        QVERIFY(standardSetupModel(model));
        QCOMPARE(model.rowCount(), m_expectedIncidenceCount);

        QVERIFY(addTestTodo(model));

        QSignalSpy loadingChanged(&model, &IncidenceOccurrenceModel::loadingChanged);
        model.setFilter(&m_testFilter);
        QCOMPARE(model.filter(), &m_testFilter);
        QVERIFY(loadingChanged.wait(3000));
        QVERIFY(!model.loading());

        QCOMPARE(model.rowCount(), 1);

        model.setFilter({});
        QVERIFY(loadingChanged.wait(3000));
        QVERIFY(!model.loading());
        QCOMPARE(model.rowCount(), m_expectedIncidenceCount + 1);
    }
};

QTEST_MAIN(IncidenceOccurrenceModelTest)
#include "incidenceoccurrencemodeltest.moc"
