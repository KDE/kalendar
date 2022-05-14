// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: LGPL-2.0-or-later

#include "contactmanager.h"

#include <Akonadi/AgentManager>
#include <Akonadi/Collection>
#include <Akonadi/ContactsTreeModel>
#include <Akonadi/ETMViewStateSaver>
#include <Akonadi/EntityMimeTypeFilterModel>
#include <Akonadi/Item>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/Monitor>
#include <kdescendantsproxymodel.h>
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
#include <akonadi_version.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 19, 40)
#include <Akonadi/ContactsFilterProxyModel>
#include <Akonadi/ContactsTreeModel>
#include <Akonadi/EmailAddressSelectionModel>
#else
#include <Akonadi/Contact/ContactsFilterProxyModel>
#include <Akonadi/Contact/ContactsTreeModel>
#include <Akonadi/Contact/EmailAddressSelectionModel>
#endif
#else
#include <Akonadi/ContactsFilterProxyModel>
#include <Akonadi/ContactsTreeModel>
#include <Akonadi/EmailAddressSelectionModel>
#endif
#include "contactcollectionmodel.h"
#include "globalcontactmodel.h"
#include <Akonadi/CollectionFilterProxyModel>
#include <Akonadi/EntityMimeTypeFilterModel>
#include <Akonadi/EntityRightsFilterModel>
#include <KCheckableProxyModel>
#include <KConfigGroup>
#include <KContacts/Addressee>
#include <KContacts/ContactGroup>
#include <KDescendantsProxyModel>
#include <KSelectionProxyModel>
#include <KSharedConfig>
#include <QBuffer>
#include <QItemSelectionModel>
#include <QSortFilterProxyModel>
#include <colorproxymodel.h>

namespace
{
class ContactsModel : public QSortFilterProxyModel
{
public:
    explicit ContactsModel(QAbstractItemModel *model, QObject *parent = nullptr)
        : QSortFilterProxyModel(parent)
    {
        auto flatModel = new KDescendantsProxyModel(this);
        flatModel->setSourceModel(model);

        auto addresseeOnlyModel = new Akonadi::EntityMimeTypeFilterModel(this);
        addresseeOnlyModel->setSourceModel(flatModel);
        addresseeOnlyModel->addMimeTypeInclusionFilter(KContacts::Addressee::mimeType());

        setSourceModel(addresseeOnlyModel);
        setDynamicSortFilter(true);
        sort(0);
    }

protected:
    bool filterAcceptsRow(int row, const QModelIndex &sourceParent) const override
    {
        // Eliminate duplicate Akonadi items
        const QModelIndex sourceIndex = sourceModel()->index(row, 0, sourceParent);
        Q_ASSERT(sourceIndex.isValid());

        auto data = sourceIndex.data(Akonadi::EntityTreeModel::ItemIdRole);
        auto matches = match(index(0, 0), Akonadi::EntityTreeModel::ItemIdRole, data, 2, Qt::MatchExactly | Qt::MatchWrap | Qt::MatchRecursive);

        return matches.length() < 1;
    }
};

// TODO move to seperate file
class KalendarCollectionFilterProxyModel : public Akonadi::CollectionFilterProxyModel
{
public:
    explicit KalendarCollectionFilterProxyModel(QObject *parent = nullptr)
        : Akonadi::CollectionFilterProxyModel(parent)
    {
    }

protected:
    bool lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const override
    {
        const auto leftHasChildren = sourceModel()->hasChildren(source_left);
        const auto rightHasChildren = sourceModel()->hasChildren(source_right);
        if (leftHasChildren && !rightHasChildren) {
            return false;
        } else if (!leftHasChildren && rightHasChildren) {
            return true;
        }

        return Akonadi::CollectionFilterProxyModel::lessThan(source_left, source_right);
    }
};
}

ContactManager::ContactManager(QObject *parent)
    : QObject(parent)
{
    m_collectionTree = new Akonadi::EntityMimeTypeFilterModel(this);
    m_collectionTree->setDynamicSortFilter(true);
    m_collectionTree->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_collectionTree->setSourceModel(GlobalContactModel::instance()->model());
    m_collectionTree->addMimeTypeInclusionFilter(Akonadi::Collection::mimeType());
    m_collectionTree->setHeaderGroup(Akonadi::EntityTreeModel::CollectionTreeHeaders);

    m_collectionSelectionModel = new QItemSelectionModel(m_collectionTree);
    m_checkableProxyModel = new ContactCollectionModel(this);
    m_checkableProxyModel->setSelectionModel(m_collectionSelectionModel);
    m_checkableProxyModel->setSourceModel(m_collectionTree);

    m_colorProxy = new ColorProxyModel(this);
    m_colorProxy->setSourceModel(m_checkableProxyModel);
    m_colorProxy->setObjectName(QStringLiteral("Show contact colors"));
    m_colorProxy->setDynamicSortFilter(true);

    KSharedConfig::Ptr config = KSharedConfig::openConfig(QStringLiteral("kalendarrc"));
    m_collectionSelectionModelStateSaver = new Akonadi::ETMViewStateSaver(this);
    KConfigGroup selectionGroup = config->group("ContactCollectionSelection");
    m_collectionSelectionModelStateSaver->setView(nullptr);
    m_collectionSelectionModelStateSaver->setSelectionModel(m_checkableProxyModel->selectionModel());
    m_collectionSelectionModelStateSaver->restoreState(selectionGroup);

    m_contactRightsFilterModel = new Akonadi::EntityRightsFilterModel(this);
    m_contactRightsFilterModel->setAccessRights(Akonadi::Collection::CanCreateItem);
    m_contactRightsFilterModel->setSourceModel(m_collectionTree);

    m_selectableContactCollectionsModel = new KalendarCollectionFilterProxyModel(this);
    m_selectableContactCollectionsModel->setSourceModel(m_contactRightsFilterModel);
    m_selectableContactCollectionsModel->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_selectableContactCollectionsModel->sort(0, Qt::AscendingOrder);

    auto sourceModel = new Akonadi::EmailAddressSelectionModel(this);

    auto filterModel = new Akonadi::ContactsFilterProxyModel(this);
    filterModel->setSourceModel(sourceModel->model());
    filterModel->setFilterFlags(Akonadi::ContactsFilterProxyModel::HasEmail);

    auto model = new ContactsModel(filterModel, this);
    m_model = new QSortFilterProxyModel(this);
    m_model->setSourceModel(model);
    m_model->setDynamicSortFilter(true);
    m_model->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_model->setFilterCaseSensitivity(Qt::CaseInsensitive);
    m_model->sort(0);

    auto selectionProxyModel = new KSelectionProxyModel(m_checkableProxyModel->selectionModel(), this);
    selectionProxyModel->setSourceModel(GlobalContactModel::instance()->model());
    selectionProxyModel->setFilterBehavior(KSelectionProxyModel::ChildrenOfExactSelection);

    auto itemTree = new Akonadi::EntityMimeTypeFilterModel(this);
    itemTree->setSourceModel(selectionProxyModel);
    itemTree->addMimeTypeExclusionFilter(Akonadi::Collection::mimeType());
    itemTree->addMimeTypeInclusionFilter(KContacts::Addressee::mimeType());
    itemTree->setHeaderGroup(Akonadi::EntityTreeModel::ItemListHeaders);

    auto filteredContacts = new QSortFilterProxyModel(this);
    filteredContacts->setSourceModel(new ContactsModel(itemTree, this));
    filteredContacts->setDynamicSortFilter(true);
    filteredContacts->setSortCaseSensitivity(Qt::CaseInsensitive);
    filteredContacts->setFilterCaseSensitivity(Qt::CaseInsensitive);
    filteredContacts->sort(0);
    m_filteredContacts = filteredContacts;
}

ContactManager::~ContactManager()
{
    Akonadi::ETMViewStateSaver treeStateSaver;
    KSharedConfig::Ptr config = KSharedConfig::openConfig(QStringLiteral("kalendarrc"));
    KConfigGroup group = config->group("ContactCollectionSelection");
    treeStateSaver.setView(nullptr);
    treeStateSaver.setSelectionModel(m_checkableProxyModel->selectionModel());
    treeStateSaver.saveState(group);
}

QAbstractItemModel *ContactManager::contactCollections() const
{
    return m_colorProxy;
}

Akonadi::CollectionFilterProxyModel *ContactManager::selectableContacts() const
{
    return m_selectableContactCollectionsModel;
}

QAbstractItemModel *ContactManager::filteredContacts() const
{
    return m_filteredContacts;
}

QSortFilterProxyModel *ContactManager::contactsModel()
{
    return m_model;
}

void ContactManager::contactEmails(qint64 itemId)
{
    Akonadi::Item item(itemId);

    auto job = new Akonadi::ItemFetchJob(item);
    job->fetchScope().fetchFullPayload();

    connect(job, &Akonadi::ItemFetchJob::result, this, [this, itemId](KJob *job) {
        auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
        auto item = fetchJob->items().at(0);
        auto payload = item.payload<KContacts::Addressee>();

        Q_EMIT emailsFetched(payload.emails(), itemId);
    });
}

Akonadi::Item ContactManager::getItem(qint64 itemId)
{
    Akonadi::Item item(itemId);

    return item;
}

QUrl ContactManager::decorationToUrl(QVariant decoration)
{
    if (!decoration.canConvert<QImage>()) {
        return {};
    }

    auto imgDecoration = decoration.value<QImage>();
    QByteArray byteArray;
    QBuffer buffer(&byteArray);
    buffer.open(QIODevice::WriteOnly);
    imgDecoration.save(&buffer, "png");
    const QString base64 = QString::fromUtf8(byteArray.toBase64());
    return QUrl(QLatin1String("data:image/png;base64,") + base64);
}

void ContactManager::updateAllCollections()
{
    for (int i = 0; i < contactCollections()->rowCount(); i++) {
        auto collection = contactCollections()->data(contactCollections()->index(i, 0), Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
        Akonadi::AgentManager::self()->synchronizeCollection(collection, true);
    }
}
