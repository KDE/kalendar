// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: LGPL-2.0-or-later

#include "contactmanager.h"

#include "contactcollectionmodel.h"
#include "globalcontactmodel.h"
#include "kalendar_contact_debug.h"
#include <Akonadi/AgentManager>
#include <Akonadi/Collection>
#include <Akonadi/CollectionColorAttribute>
#include <Akonadi/CollectionDeleteJob>
#include <Akonadi/CollectionModifyJob>
#include <Akonadi/CollectionPropertiesDialog>
#include <Akonadi/CollectionStatistics>
#include <Akonadi/CollectionUtils>
#include <Akonadi/ContactsFilterProxyModel>
#include <Akonadi/ContactsTreeModel>
#include <Akonadi/ETMViewStateSaver>
#include <Akonadi/EmailAddressSelectionModel>
#include <Akonadi/EntityMimeTypeFilterModel>
#include <Akonadi/EntityRightsFilterModel>
#include <Akonadi/ItemDeleteJob>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/Monitor>
#include <Akonadi/SelectionProxyModel>
#include <KCheckableProxyModel>
#include <KConfigGroup>
#include <KDescendantsProxyModel>
#include <KLocalizedString>
#include <KSelectionProxyModel>
#include <KSharedConfig>
#include <QBuffer>
#include <QItemSelectionModel>
#include <QPointer>
#include <colorproxymodel.h>
#include <sortedcollectionproxymodel.h>

ContactManager::ContactManager(QObject *parent)
    : QObject(parent)
{
    // Sidebar collection model
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

    // List of contacts for the main contact view
    auto selectionProxyModel = new Akonadi::SelectionProxyModel(m_checkableProxyModel->selectionModel(), this);
    selectionProxyModel->setSourceModel(GlobalContactModel::instance()->model());
    selectionProxyModel->setFilterBehavior(KSelectionProxyModel::ChildrenOfExactSelection);

    auto flatModel = new KDescendantsProxyModel(this);
    flatModel->setSourceModel(selectionProxyModel);

    auto entityMimeTypeFilterModel = new Akonadi::EntityMimeTypeFilterModel(this);
    entityMimeTypeFilterModel->setSourceModel(flatModel);
    entityMimeTypeFilterModel->addMimeTypeExclusionFilter(Akonadi::Collection::mimeType());
    entityMimeTypeFilterModel->setHeaderGroup(Akonadi::EntityTreeModel::ItemListHeaders);

    m_filteredContacts = new QSortFilterProxyModel(this);
    m_filteredContacts->setSourceModel(entityMimeTypeFilterModel);
    m_filteredContacts->setSortLocaleAware(true);
    m_filteredContacts->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_filteredContacts->setFilterCaseSensitivity(Qt::CaseInsensitive);
    m_filteredContacts->sort(0);
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

QAbstractItemModel *ContactManager::filteredContacts() const
{
    return m_filteredContacts;
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

void ContactManager::deleteItem(const Akonadi::Item &item)
{
    new Akonadi::ItemDeleteJob(item);
}

void ContactManager::updateAllCollections()
{
    for (int i = 0; i < contactCollections()->rowCount(); i++) {
        auto collection = contactCollections()->data(contactCollections()->index(i, 0), Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
        Akonadi::AgentManager::self()->synchronizeCollection(collection, true);
    }
}

void ContactManager::updateCollection(const Akonadi::Collection &collection)
{
    Akonadi::AgentManager::self()->synchronizeCollection(collection, false);
}

void ContactManager::deleteCollection(const Akonadi::Collection &collection)
{
    const bool isTopLevel = collection.parentCollection() == Akonadi::Collection::root();

    if (!isTopLevel) {
        // deletes contents
        auto job = new Akonadi::CollectionDeleteJob(collection, this);
        connect(job, &Akonadi::CollectionDeleteJob::result, this, [](KJob *job) {
            if (job->error()) {
                qCWarning(KALENDAR_LOG) << "Error occurred deleting collection: " << job->errorString();
            }
        });
        return;
    }
    // deletes the agent, not the contents
    const Akonadi::AgentInstance instance = Akonadi::AgentManager::self()->instance(collection.resource());
    if (instance.isValid()) {
        Akonadi::AgentManager::self()->removeInstance(instance);
    }
}

void ContactManager::editCollection(const Akonadi::Collection &collection)
{
    // TODO: Reimplement this dialog in QML
    QPointer<Akonadi::CollectionPropertiesDialog> dlg = new Akonadi::CollectionPropertiesDialog(collection);
    dlg->setWindowTitle(i18nc("@title:window", "Properties of Address Book %1", collection.name()));
    dlg->show();
}

QVariantMap ContactManager::getCollectionDetails(const Akonadi::Collection &collection)
{
    QVariantMap collectionDetails;

    collectionDetails[QLatin1String("id")] = collection.id();
    collectionDetails[QLatin1String("name")] = collection.name();
    collectionDetails[QLatin1String("displayName")] = collection.displayName();
    collectionDetails[QLatin1String("color")] = m_colorProxy->color(collection.id());
    collectionDetails[QLatin1String("count")] = collection.statistics().count();
    collectionDetails[QLatin1String("isResource")] = Akonadi::CollectionUtils::isResource(collection);
    collectionDetails[QLatin1String("resource")] = collection.resource();
    collectionDetails[QLatin1String("readOnly")] = collection.rights().testFlag(Akonadi::Collection::ReadOnly);
    collectionDetails[QLatin1String("canChange")] = collection.rights().testFlag(Akonadi::Collection::CanChangeCollection);
    collectionDetails[QLatin1String("canCreate")] = collection.rights().testFlag(Akonadi::Collection::CanCreateCollection);
    collectionDetails[QLatin1String("canDelete")] =
        collection.rights().testFlag(Akonadi::Collection::CanDeleteCollection) && !Akonadi::CollectionUtils::isResource(collection);

    return collectionDetails;
}

void ContactManager::setCollectionColor(Akonadi::Collection collection, const QColor &color)
{
    auto colorAttr = collection.attribute<Akonadi::CollectionColorAttribute>(Akonadi::Collection::AddIfMissing);
    colorAttr->setColor(color);
    auto modifyJob = new Akonadi::CollectionModifyJob(collection);
    connect(modifyJob, &Akonadi::CollectionModifyJob::result, this, [this, collection, color](KJob *job) {
        if (job->error()) {
            qCWarning(KALENDAR_LOG) << "Error occurred modifying collection color: " << job->errorString();
        } else {
            m_colorProxy->setColor(collection.id(), color);
        }
    });
}
