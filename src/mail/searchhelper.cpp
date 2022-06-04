// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "searchhelper.h"
#include "mailconfig.h"
#include "mailmodel.h"
#include <Akonadi/CollectionFetchJob>
#include <Akonadi/CollectionFetchScope>
#include <Akonadi/CollectionModifyJob>
#include <Akonadi/CollectionStatistics>
#include <Akonadi/MessageModel>
#include <Akonadi/Monitor>
#include <Akonadi/PersistentSearchAttribute>
#include <Akonadi/SearchCreateJob>
#include <KLocalizedString>
#include <QSortFilterProxyModel>

SearchHelper::SearchHelper(QObject *parent)
    : QObject(parent)
    , m_mailModel(new MailModel(this))
{
}

QString SearchHelper::searchString() const
{
    return m_searchString;
}

void SearchHelper::setSearchString(const QString searchString)
{
    if (searchString == m_searchString) {
        return;
    }
    m_searchString = searchString;

    if (m_searchJob) {
        m_searchJob->kill(KJob::Quietly);
        m_searchJob->deleteLater();
        m_searchJob = nullptr;
    }

    // TODO expose only searching in some collection and sub-collection in the UI
    QVector<Akonadi::Collection> searchCollections;
    bool recursive = false;

    if (!m_folder.isValid()) {
        auto searchJob = new Akonadi::SearchCreateJob(searchString, m_query, this);
        searchJob->setSearchMimeTypes(QStringList() << QStringLiteral("message/rfc822"));
        searchJob->setSearchCollections(searchCollections);
        searchJob->setRecursive(recursive);
        searchJob->setRemoteSearchEnabled(false);
        m_searchJob = searchJob;
    } else {
        auto attribute = new Akonadi::PersistentSearchAttribute();
        m_folder.setContentMimeTypes(QStringList() << QStringLiteral("message/rfc822"));
        attribute->setQueryString(QString::fromLatin1(m_query.toJSON()));
        attribute->setQueryCollections(searchCollections);
        attribute->setRecursive(recursive);
        attribute->setRemoteSearchEnabled(false);
        m_folder.addAttribute(attribute);
        m_searchJob = new Akonadi::CollectionModifyJob(m_folder, this);
    }

    connect(m_searchJob, &Akonadi::CollectionModifyJob::result, this, [this](KJob *job) {
        Q_ASSERT(job == m_searchJob);
        m_searchJob = nullptr;

        if (job->error()) {
            qDebug() << job->errorString();
            Q_EMIT errorOccured(i18n("Cannot get search result. %1", job->errorString()));
            return;
        }

        MailConfig::self()->setLastSearchCollectionId(m_folder.id());
        MailConfig::self()->save();

        if (const auto searchJob = qobject_cast<Akonadi::SearchCreateJob *>(job)) {
            m_folder = searchJob->createdCollection();
        } else if (const auto modifyJob = qobject_cast<Akonadi::CollectionModifyJob *>(job)) {
            m_folder = modifyJob->collection();
        }
        /// TODO: cope better with cases where this fails
        Q_ASSERT(m_folder.isValid());
        Q_ASSERT(m_folder.hasAttribute<Akonadi::PersistentSearchAttribute>());

        new Akonadi::CollectionModifyJob(m_folder, this);
        auto fetch = new Akonadi::CollectionFetchJob(m_folder, Akonadi::CollectionFetchJob::Base, this);
        fetch->fetchScope().setIncludeStatistics(true);
        connect(fetch, &KJob::result, this, [this](KJob *job) {
            auto fetch = qobject_cast<Akonadi::CollectionFetchJob *>(job);
            if (!fetch || fetch->error()) {
                return;
            }

            const Akonadi::Collection::List cols = fetch->collections();
            if (cols.isEmpty()) {
                return;
            }

            const Akonadi::Collection col = cols.at(0);

            m_matches = i18np("%1 match", "%1 matches", col.statistics().count());
        });

        if (m_resultModel) {
            m_resultModel->deleteLater();
        }
        auto monitor = new Akonadi::Monitor(this);
        monitor->setCollectionMonitored(m_folder);
        m_resultModel = new Akonadi::MessageModel(monitor, this);
        m_resultModel->setCollectionMonitored(m_folder);
        monitor->setParent(m_resultModel);
        auto sortproxy = new QSortFilterProxyModel(m_resultModel);
        sortproxy->setDynamicSortFilter(true);
        sortproxy->setSortRole(Qt::EditRole);
        sortproxy->setFilterCaseSensitivity(Qt::CaseInsensitive);
        sortproxy->setSourceModel(m_resultModel);
        m_mailModel = new MailModel(this);
        m_mailModel->setSourceModel(sortproxy);
        Q_EMIT mailModelChanged();
    });

    Q_EMIT searchStringChanged();
}

MailModel *SearchHelper::mailModel() const
{
    return m_mailModel;
}

QString SearchHelper::matches() const
{
    return m_matches;
}
