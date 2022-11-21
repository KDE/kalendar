// This file is part of Akonadi Contact.
//
// SPDX-FileCopyrightText: 2007-2009 Tobias Koenig <tokoe@kde.org>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
//
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "collectionpickermodel.h"

#include <Akonadi/CollectionFetchScope>
#include <Akonadi/CollectionFilterProxyModel>
#include <Akonadi/CollectionUtils>
#include <Akonadi/EntityRightsFilterModel>
#include <Akonadi/EntityTreeModel>
#include <Akonadi/Monitor>
#include <Akonadi/Session>

#include "colorproxymodel.h"
#include "sortedcollectionproxymodel.h"
#include <QAbstractItemModel>

using namespace Akonadi::Quick;

class Akonadi::Quick::CollectionPickerModelPrivate
{
public:
    CollectionPickerModelPrivate(CollectionPickerModel *parent)
        : mParent(parent)
    {
        mMonitor = new Akonadi::Monitor(mParent);
        mMonitor->setObjectName(QStringLiteral("CollectionPickerMonitor"));
        mMonitor->fetchCollection(true);
        mMonitor->setCollectionMonitored(Akonadi::Collection::root());

        // This ETM will be set to only show collections with the wanted mimetype in setMimeTypeFilter
        mModel = new Akonadi::EntityTreeModel(mMonitor, mParent);
        mModel->setItemPopulationStrategy(Akonadi::EntityTreeModel::NoItemPopulation);
        mModel->setListFilter(Akonadi::CollectionFetchScope::Display);

        mBaseModel = mModel;

        // Display color
        auto colorProxy = new ColorProxyModel(mParent);
        colorProxy->setObjectName(QStringLiteral("Show collection colors"));
        colorProxy->setDynamicSortFilter(true);
        colorProxy->setSourceModel(mBaseModel);

        // Filter by access rights. TODO: maybe this functionality could be provided by CollectionFilterProxyModel, to save one proxy?
        mRightsFilterModel = new Akonadi::EntityRightsFilterModel(parent);
        mRightsFilterModel->setSourceModel(colorProxy);

        mMimeTypeFilterModel = new SortedCollectionProxModel(parent);
        mMimeTypeFilterModel->setSourceModel(mRightsFilterModel);
        mMimeTypeFilterModel->setSortCaseSensitivity(Qt::CaseInsensitive);
        mMimeTypeFilterModel->sort(0, Qt::AscendingOrder);

        mParent->setSourceModel(mMimeTypeFilterModel);
    }

    ~CollectionPickerModelPrivate() = default;

    void activated(int index);
    void activated(const QModelIndex &index);

    CollectionPickerModel *const mParent;

    Akonadi::Monitor *mMonitor = nullptr;
    Akonadi::EntityTreeModel *mModel = nullptr;
    QAbstractItemModel *mBaseModel = nullptr;
    Akonadi::CollectionFilterProxyModel *mMimeTypeFilterModel = nullptr;
    Akonadi::EntityRightsFilterModel *mRightsFilterModel = nullptr;
};

CollectionPickerModel::CollectionPickerModel(QObject *parent)
    : QSortFilterProxyModel(parent)
    , d(new CollectionPickerModelPrivate(this))
{
}

CollectionPickerModel::~CollectionPickerModel() = default;

void CollectionPickerModel::setMimeTypeFilter(const QStringList &contentMimeTypes)
{
    d->mMimeTypeFilterModel->clearFilters();
    d->mMimeTypeFilterModel->addMimeTypeFilters(contentMimeTypes);

    if (d->mMonitor) {
        for (const QString &mimeType : contentMimeTypes) {
            d->mMonitor->setMimeTypeMonitored(mimeType, true);
        }
    }
}

QStringList CollectionPickerModel::mimeTypeFilter() const
{
    return d->mMimeTypeFilterModel->mimeTypeFilters();
}

void CollectionPickerModel::setAccessRightsFilter(Collection::Right rights)
{
    d->mRightsFilterModel->setAccessRights(rights);
    Q_EMIT accessRightsFilterChanged();
}

Akonadi::Collection::Right CollectionPickerModel::accessRightsFilter() const
{
    return (Akonadi::Collection::Right)(int)d->mRightsFilterModel->accessRights();
}

void CollectionPickerModel::setExcludeVirtualCollections(bool b)
{
    d->mMimeTypeFilterModel->setExcludeVirtualCollections(b);
    Q_EMIT excludeVirtualCollectionsChanged();
}

bool CollectionPickerModel::excludeVirtualCollections() const
{
    return d->mMimeTypeFilterModel->excludeVirtualCollections();
}

#include "moc_collectionpickermodel.cpp"