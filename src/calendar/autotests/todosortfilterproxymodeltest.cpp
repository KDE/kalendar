// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include <filter.h>
#include <models/todosortfilterproxymodel.h>

#include <Akonadi/IncidenceChanger>

#include <KCalendarCore/Incidence>
#include <KCheckableProxyModel>
#include <QAbstractItemModelTester>
#include <QSignalSpy>
#include <QTest>
#include <akonadi/qtest_akonadi.h>

class TodoSortFilterProxyModelTest : public QObject
{
    Q_OBJECT

public:
    TodoSortFilterProxyModelTest() = default;
    ~TodoSortFilterProxyModelTest() override = default;

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

    // Our test calendar file has two todos, with sub-todos
    static constexpr auto m_expectedTopLevelTodoCount = 2;

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

        qRegisterMetaType<QList<QPersistentModelIndex>>();
        qRegisterMetaType<QAbstractItemModel::LayoutChangeHint>();
    }

    void testAddCalendar()
    {
        resetCalendar();

        TodoSortFilterProxyModel model;
        QAbstractItemModelTester modelTester(&model);
        QSignalSpy modelReset(&model, &QAbstractItemModel::modelReset);

        model.setCalendar(m_calendar);
        QCOMPARE(modelReset.count(), 1);

        QCOMPARE(model.rowCount(), m_expectedTopLevelTodoCount);
    }
};

QTEST_MAIN(TodoSortFilterProxyModelTest)
#include "todosortfilterproxymodeltest.moc"
