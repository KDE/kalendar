// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <AkonadiCore/TagCreateJob>
#include <AkonadiCore/TagDeleteJob>
#include <AkonadiCore/TagModifyJob>
#include <tagmanager.h>

class FlatTagModel : public QSortFilterProxyModel
{
public:
    explicit FlatTagModel(QObject *parent = nullptr)
        : QSortFilterProxyModel(parent)
    {
        Akonadi::Monitor *monitor = new Akonadi::Monitor(this);
        monitor->setObjectName(QStringLiteral("TagModelMonitor"));
        monitor->setTypeMonitored(Akonadi::Monitor::Tags);

        auto flatTagModel = new KDescendantsProxyModel;
        flatTagModel->setSourceModel(new Akonadi::TagModel(monitor));
        setSourceModel(flatTagModel);

        setDynamicSortFilter(true);
        sort(0);
    };

    QHash<int, QByteArray> roleNames() const override {
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
        auto matches = match(index(0,0), Akonadi::TagModel::NameRole, data, 2, Qt::MatchExactly | Qt::MatchWrap | Qt::MatchRecursive);

        return matches.length() < 2;
    }
};

TagManager::TagManager(QObject* parent)
{
    m_tagModel = new FlatTagModel;
}

QSortFilterProxyModel * TagManager::tagModel()
{
    return m_tagModel;
}

void TagManager::createTag(const QString &name)
{
    Akonadi::Tag tag(name);
    Akonadi::TagCreateJob *job = new Akonadi::TagCreateJob(tag, this);
    connect(job, &Akonadi::TagCreateJob::finished, this, [=](KJob *job) {
        if (job->error())
            qDebug() << "Error occurred creating tag";
    });
}

void TagManager::deleteTag(Akonadi::Tag tag)
{
    Akonadi::TagDeleteJob *job = new Akonadi::TagDeleteJob(tag);
    connect(job, &Akonadi::TagDeleteJob::result, this, [=](KJob *job) {
        if (job->error())
            qDebug() << "Error occurred renaming tag";
    });
}

void TagManager::renameTag(Akonadi::Tag tag, const QString &newName)
{
    tag.setName(newName);
    Akonadi::TagModifyJob *job = new Akonadi::TagModifyJob(tag);
    connect(job, &Akonadi::TagModifyJob::result, this, [=](KJob *job) {
        if (job->error())
            qDebug() << "Error occurred renaming tag";
    });
}
