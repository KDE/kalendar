// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "tagmanager.h"
#include "akonadi_quick_debug.h"

#include <Akonadi/TagCreateJob>
#include <Akonadi/TagDeleteJob>
#include <Akonadi/TagModifyJob>
#include <KDescendantsProxyModel>

class FlatTagModel : public QSortFilterProxyModel
{
public:
    explicit FlatTagModel(QObject *parent = nullptr)
        : QSortFilterProxyModel(parent)
    {
        auto monitor = new Akonadi::Monitor(this);
        monitor->setObjectName(QStringLiteral("TagModelMonitor"));
        monitor->setTypeMonitored(Akonadi::Monitor::Tags);

        auto flatTagModel = new KDescendantsProxyModel;
        flatTagModel->setSourceModel(new Akonadi::TagModel(monitor));
        setSourceModel(flatTagModel);

        setDynamicSortFilter(true);
        sort(0);
    }

    QHash<int, QByteArray> roleNames() const override
    {
        auto rolenames = QSortFilterProxyModel::roleNames();
        rolenames[Akonadi::TagModel::Roles::NameRole] = QByteArrayLiteral("name");
        rolenames[Akonadi::TagModel::Roles::IdRole] = QByteArrayLiteral("id");
        rolenames[Akonadi::TagModel::Roles::GIDRole] = QByteArrayLiteral("gid");
        rolenames[Akonadi::TagModel::Roles::TypeRole] = QByteArrayLiteral("type");
        rolenames[Akonadi::TagModel::Roles::ParentRole] = QByteArrayLiteral("parent");
        rolenames[Akonadi::TagModel::Roles::TagRole] = QByteArrayLiteral("tag");

        return rolenames;
    }

protected:
    bool filterAcceptsRow(int row, const QModelIndex &sourceParent) const override
    {
        // Eliminate duplicate tag names
        const QModelIndex sourceIndex = sourceModel()->index(row, 0, sourceParent);
        Q_ASSERT(sourceIndex.isValid());

        auto data = sourceIndex.data(Akonadi::TagModel::NameRole);
        auto matches = match(index(0, 0), Akonadi::TagModel::NameRole, data, 2, Qt::MatchExactly | Qt::MatchWrap | Qt::MatchRecursive);

        return matches.length() < 2;
    }
};

TagManager::TagManager(QObject *parent)
    : QObject(parent)
{
    m_tagModel = new FlatTagModel(this);

    QObject::connect(m_tagModel, &QSortFilterProxyModel::dataChanged, this, &TagManager::tagModelChanged);
    QObject::connect(m_tagModel, &QSortFilterProxyModel::layoutChanged, this, &TagManager::tagModelChanged);
    QObject::connect(m_tagModel, &QSortFilterProxyModel::modelReset, this, &TagManager::tagModelChanged);
    QObject::connect(m_tagModel, &QSortFilterProxyModel::rowsInserted, this, &TagManager::tagModelChanged);
    QObject::connect(m_tagModel, &QSortFilterProxyModel::rowsMoved, this, &TagManager::tagModelChanged);
    QObject::connect(m_tagModel, &QSortFilterProxyModel::rowsRemoved, this, &TagManager::tagModelChanged);
}

QSortFilterProxyModel *TagManager::tagModel()
{
    return m_tagModel;
}

void TagManager::createTag(const QString &name)
{
    Akonadi::Tag tag(name);
    auto job = new Akonadi::TagCreateJob(tag, this);
    connect(job, &Akonadi::TagCreateJob::finished, this, [=](KJob *job) {
        if (job->error())
            qCDebug(AKONADI_QUICK_LOG) << "Error occurred creating tag";
    });
}

void TagManager::deleteTag(Akonadi::Tag tag)
{
    auto job = new Akonadi::TagDeleteJob(tag);
    connect(job, &Akonadi::TagDeleteJob::result, this, [=](KJob *job) {
        if (job->error())
            qCDebug(AKONADI_QUICK_LOG) << "Error occurred renaming tag";
    });
}

void TagManager::renameTag(Akonadi::Tag tag, const QString &newName)
{
    tag.setName(newName);
    auto job = new Akonadi::TagModifyJob(tag);
    connect(job, &Akonadi::TagModifyJob::result, this, [=](KJob *job) {
        if (job->error())
            qCDebug(AKONADI_QUICK_LOG) << "Error occurred renaming tag";
    });
}
