/*
     This file is part of Akonadi Contact.

     SPDX-FileCopyrightText: 2007-2009 Tobias Koenig <tokoe@kde.org>

     SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "collectioncomboboxmodel.h"

#include <Akonadi/CollectionFetchScope>
#include <Akonadi/CollectionFilterProxyModel>
#include <Akonadi/CollectionUtils>
#include <Akonadi/EntityRightsFilterModel>
#include <Akonadi/EntityTreeModel>
#include <Akonadi/Monitor>
#include <Akonadi/Session>

#include <KDescendantsProxyModel>

#include "colorproxymodel.h"
#include <QAbstractItemModel>

using namespace Akonadi::Quick;

class Akonadi::Quick::CollectionComboBoxModelPrivate
{
public:
    CollectionComboBoxModelPrivate(CollectionComboBoxModel *parent)
        : mParent(parent)
    {
        mMonitor = new Akonadi::Monitor(mParent);
        mMonitor->setObjectName(QStringLiteral("CollectionComboBoxMonitor"));
        mMonitor->fetchCollection(true);
        mMonitor->setCollectionMonitored(Akonadi::Collection::root());

        // This ETM will be set to only show collections with the wanted mimetype in setMimeTypeFilter
        auto entityModel = new Akonadi::EntityTreeModel(mMonitor, mParent);
        entityModel->setItemPopulationStrategy(Akonadi::EntityTreeModel::NoItemPopulation);
        entityModel->setListFilter(Akonadi::CollectionFetchScope::Display);

        // Display color
        auto colorProxy = new ColorProxyModel(mParent);
        colorProxy->setObjectName(QStringLiteral("Show collection colors"));
        colorProxy->setDynamicSortFilter(true);
        colorProxy->setSourceModel(entityModel);

        // Flatten the tree, e.g.
        // Kolab
        // Kolab / Inbox
        // Kolab / Inbox / Calendar
        auto proxyModel = new KDescendantsProxyModel(parent);
        proxyModel->setDisplayAncestorData(true);
        proxyModel->setSourceModel(colorProxy);

        // Filter it by mimetype again, to only keep
        // Kolab / Inbox / Calendar
        mMimeTypeFilterModel = new Akonadi::CollectionFilterProxyModel(parent);
        mMimeTypeFilterModel->setSourceModel(proxyModel);

        // Filter by access rights. TODO: maybe this functionality could be provided by CollectionFilterProxyModel, to save one proxy?
        mRightsFilterModel = new Akonadi::EntityRightsFilterModel(parent);
        mRightsFilterModel->setSourceModel(mMimeTypeFilterModel);

        mParent->setSourceModel(mRightsFilterModel);
        // mRightsFilterModel->sort(mParent->modelColumn());

        mParent->connect(mRightsFilterModel, &QAbstractItemModel::rowsInserted, mParent, [this](const QModelIndex &parent, int start, int end) {
            Q_UNUSED(parent)
            Q_UNUSED(start)
            Q_UNUSED(end)
            scanSubTree();
        });
    }

    ~CollectionComboBoxModelPrivate() = default;

    bool scanSubTree();

    CollectionComboBoxModel *const mParent;

    Akonadi::Monitor *mMonitor = nullptr;
    Akonadi::CollectionFilterProxyModel *mMimeTypeFilterModel = nullptr;
    Akonadi::EntityRightsFilterModel *mRightsFilterModel = nullptr;
    qint64 mDefaultCollectionId = -1;
    int mCurrentIndex = -1;
};

bool CollectionComboBoxModelPrivate::scanSubTree()
{
    for (int row = 0; row < mRightsFilterModel->rowCount(); ++row) {
        const Akonadi::Collection::Id id = mRightsFilterModel->data(mRightsFilterModel->index(row, 0), EntityTreeModel::CollectionIdRole).toLongLong();

        if (mDefaultCollectionId == id && id > 0) {
            mParent->setCurrentIndex(row);
            return true;
        }
    }

    return false;
}

CollectionComboBoxModel::CollectionComboBoxModel(QObject *parent)
    : QSortFilterProxyModel(parent)
    , d(new CollectionComboBoxModelPrivate(this))
{
}

CollectionComboBoxModel::~CollectionComboBoxModel() = default;

void CollectionComboBoxModel::setMimeTypeFilter(const QStringList &contentMimeTypes)
{
    d->mMimeTypeFilterModel->clearFilters();
    d->mMimeTypeFilterModel->addMimeTypeFilters(contentMimeTypes);

    if (d->mMonitor) {
        for (const QString &mimeType : contentMimeTypes) {
            d->mMonitor->setMimeTypeMonitored(mimeType, true);
        }
    }
}

QStringList CollectionComboBoxModel::mimeTypeFilter() const
{
    return d->mMimeTypeFilterModel->mimeTypeFilters();
}

void CollectionComboBoxModel::setAccessRightsFilter(int rights)
{
    d->mRightsFilterModel->setAccessRights((Collection::Right)rights);
    Q_EMIT accessRightsFilterChanged();
}

int CollectionComboBoxModel::accessRightsFilter() const
{
    return (int)d->mRightsFilterModel->accessRights();
}

qint64 CollectionComboBoxModel::defaultCollectionId() const
{
    return d->mDefaultCollectionId;
}

void CollectionComboBoxModel::setDefaultCollectionId(qint64 collectionId)
{
    if (d->mDefaultCollectionId == collectionId) {
        return;
    }
    d->mDefaultCollectionId = collectionId;
    d->scanSubTree();
    Q_EMIT defaultCollectionIdChanged();
}

void CollectionComboBoxModel::setExcludeVirtualCollections(bool b)
{
    d->mMimeTypeFilterModel->setExcludeVirtualCollections(b);
}

bool CollectionComboBoxModel::excludeVirtualCollections() const
{
    return d->mMimeTypeFilterModel->excludeVirtualCollections();
}

int CollectionComboBoxModel::currentIndex() const
{
    return d->mCurrentIndex;
}

void CollectionComboBoxModel::setCurrentIndex(int currentIndex)
{
    if (d->mCurrentIndex == currentIndex) {
        return;
    }
    d->mCurrentIndex = currentIndex;
    Q_EMIT currentIndexChanged();
}

#include "moc_collectioncomboboxmodel.cpp"
