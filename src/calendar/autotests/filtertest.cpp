// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include <filter.h>

#include <QSignalSpy>
#include <QTest>

class FilterTest : public QObject
{
    Q_OBJECT

public:
    FilterTest() = default;
    ~FilterTest() override = default;

private:
    static constexpr qint64 m_testCollectionId = 1;
    const QString m_testName = QStringLiteral("name");
    const QStringList m_testTags{QStringLiteral("tag-1"), QStringLiteral("tag-2"), QStringLiteral("tag-3")};

private Q_SLOTS:
    void initTestCase()
    {
    }

    void testProperties()
    {
        Filter filter;
        QSignalSpy collectionIdChanged(&filter, &Filter::collectionIdChanged);
        QSignalSpy tagsChanged(&filter, &Filter::tagsChanged);
        QSignalSpy nameChanged(&filter, &Filter::nameChanged);

        filter.setCollectionId(m_testCollectionId);
        QCOMPARE(collectionIdChanged.count(), 1);
        QCOMPARE(filter.collectionId(), m_testCollectionId);

        filter.setTags(m_testTags);
        QCOMPARE(tagsChanged.count(), 1);
        QCOMPARE(filter.tags(), m_testTags);

        filter.setName(m_testName);
        QCOMPARE(nameChanged.count(), 1);
        QCOMPARE(filter.name(), m_testName);
    }
};

QTEST_MAIN(FilterTest)
#include "filtertest.moc"
