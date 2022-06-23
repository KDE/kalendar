// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: LGPL-2.0-or-later

#include "contactmanager.h"

#include <Akonadi/AgentManager>
#include <Akonadi/Collection>
#include <Akonadi/ETMViewStateSaver>
#include <Akonadi/EntityMimeTypeFilterModel>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/Monitor>
#include <Akonadi/SelectionProxyModel>
#include <qsortfilterproxymodel.h>
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
#include <Akonadi/EntityMimeTypeFilterModel>
#include <Akonadi/EntityRightsFilterModel>
#include <KCheckableProxyModel>
#include <KConfigGroup>
#include <KContacts/Addressee>
#include <KContacts/ContactGroup>
#include <KSelectionProxyModel>
#include <KSharedConfig>
#include <QBuffer>
#include <QItemSelectionModel>
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

void ContactManager::updateAllCollections()
{
    for (int i = 0; i < contactCollections()->rowCount(); i++) {
        auto collection = contactCollections()->data(contactCollections()->index(i, 0), Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
        Akonadi::AgentManager::self()->synchronizeCollection(collection, true);
    }
}
