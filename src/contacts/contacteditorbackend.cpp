// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "contacteditorbackend.h"
#include "addresseewrapper.h"
#include "attributes/contactmetadataattribute_p.h"
#include <Akonadi/Collection>
#include <Akonadi/CollectionDialog>
#include <Akonadi/CollectionFetchJob>
#include <Akonadi/ItemCreateJob>
#include <Akonadi/ItemModifyJob>
#include <Akonadi/Monitor>
#include <Akonadi/Session>
#include <KLocalizedString>

ContactEditorBackend::ContactEditorBackend(QObject *parent)
    : QObject(parent)
    , m_mode(ContactEditorBackend::CreateMode)
{
}

ContactEditorBackend::~ContactEditorBackend() = default;

void ContactEditorBackend::setDefaultAddressBook(const Akonadi::Collection &addressbook)
{
    m_defaultAddressBook = addressbook;
}

AddresseeWrapper *ContactEditorBackend::contact()
{
    if (m_addressee) {
        return m_addressee;
    }

    m_addressee = new AddresseeWrapper(this);
    Q_EMIT contactChanged();
    return m_addressee;
}

ContactEditorBackend::Mode ContactEditorBackend::mode() const
{
    return m_mode;
}

void ContactEditorBackend::setMode(ContactEditorBackend::Mode mode)
{
    if (m_mode == mode) {
        return;
    }
    m_mode = mode;
    Q_EMIT modeChanged();
}

Akonadi::Item ContactEditorBackend::item() const
{
    return m_item;
}

void ContactEditorBackend::setItem(const Akonadi::Item &item)
{
    if (m_mode == CreateMode) {
        Q_ASSERT_X(false, "ContactEditorBackend::loadContact", "You are calling loadContact in CreateMode!");
    }

    auto job = new Akonadi::ItemFetchJob(item);
    job->fetchScope().fetchFullPayload();
    job->fetchScope().fetchAttribute<ContactMetaDataAttribute>();
    job->fetchScope().setAncestorRetrieval(Akonadi::ItemFetchScope::Parent);

    connect(job, &Akonadi::ItemFetchJob::result, this, [this](KJob *job) {
        itemFetchDone(job);
    });

    setupMonitor();
    m_monitor->setItemMonitored(item);
}

void ContactEditorBackend::setupMonitor()
{
    delete m_monitor;
    m_monitor = new Akonadi::Monitor;
    m_monitor->setObjectName(QStringLiteral("ContactEditorMonitor"));
    m_monitor->ignoreSession(Akonadi::Session::defaultSession());

    connect(m_monitor, &Akonadi::Monitor::itemChanged, this, [this](const Akonadi::Item &item, const QSet<QByteArray> &) {
        m_item = item;
        Q_EMIT itemChangedExternally();
    });
}

void ContactEditorBackend::fetchItem()
{
     auto job = new Akonadi::ItemFetchJob(m_item);
     job->fetchScope().fetchFullPayload();
     job->fetchScope().fetchAttribute<ContactMetaDataAttribute>();
     job->fetchScope().setAncestorRetrieval(Akonadi::ItemFetchScope::Parent);

    connect(job, &Akonadi::ItemFetchJob::result, this, [this](KJob *job) {
        itemFetchDone(job);
    });
}

void ContactEditorBackend::itemFetchDone(KJob *job)
{
    if (job->error() != KJob::NoError) {
        Q_EMIT errorOccured(job->errorString());
        return;
    }

    auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
    if (!fetchJob) {
        return;
    }

    if (fetchJob->items().isEmpty()) {
        return;
    }

    m_item = fetchJob->items().at(0);
    Q_EMIT itemChanged();

    setReadOnly(false);
    if (m_mode == ContactEditorBackend::EditMode) {
        // if in edit mode we have to fetch the parent collection to find out
        // about the modify rights of the item

        auto collectionFetchJob = new Akonadi::CollectionFetchJob(m_item.parentCollection(), Akonadi::CollectionFetchJob::Base);
        this->connect(collectionFetchJob, &Akonadi::CollectionFetchJob::result, this, [this](KJob *job) {
            parentCollectionFetchDone(job);
        });
    } else {
        const auto addr = m_item.payload<KContacts::Addressee>();
        m_contactMetaData.load(m_item);
        contact()->setDisplayType((AddresseeWrapper::DisplayType)m_contactMetaData.displayNameMode());
        contact()->setAddressee(m_item.payload<KContacts::Addressee>());
    }
    Q_EMIT itemChanged();
    Q_EMIT contactChanged();
}

void ContactEditorBackend::parentCollectionFetchDone(KJob *job)
{
    if (job->error()) {
        Q_EMIT errorOccured(job->errorString());
        return;
    }

    auto fetchJob = qobject_cast<Akonadi::CollectionFetchJob *>(job);
    if (!fetchJob) {
        return;
    }

    const Akonadi::Collection parentCollection = fetchJob->collections().at(0);
    if (parentCollection.isValid()) {
        setReadOnly(!(parentCollection.rights() & Akonadi::Collection::CanChangeItem));
        m_defaultAddressBook = parentCollection;
        Q_EMIT collectionChanged();
    }

    m_contactMetaData.load(m_item);
    contact()->setDisplayType((AddresseeWrapper::DisplayType)m_contactMetaData.displayNameMode());
    contact()->setAddressee(m_item.payload<KContacts::Addressee>());
}

qint64 ContactEditorBackend::collectionId() const
{
    return m_defaultAddressBook.id();
}

void ContactEditorBackend::saveContactInAddressBook()
{
    if (m_mode == EditMode) {
        if (!m_item.isValid() || m_readOnly) {
            qDebug() << "item not valid anymore";
            return;
        }

        auto addressee = m_addressee->addressee();

        storeContact(addressee, m_contactMetaData);

        m_contactMetaData.store(m_item);

        m_item.setPayload<KContacts::Addressee>(addressee);

        auto job = new Akonadi::ItemModifyJob(m_item);
        connect(job, &Akonadi::ItemModifyJob::result, this, [this](KJob *job) {
            storeDone(job);
        });
    } else if (m_mode == CreateMode) {
        Q_ASSERT(m_defaultAddressBook.isValid());

        KContacts::Addressee addr(m_addressee->addressee());
        storeContact(addr, m_contactMetaData);

        Akonadi::Item item;
        item.setPayload<KContacts::Addressee>(addr);
        item.setMimeType(KContacts::Addressee::mimeType());

        m_contactMetaData.store(item);

        auto job = new Akonadi::ItemCreateJob(item, m_defaultAddressBook);
        connect(job, &Akonadi::ItemCreateJob::result, this, [this](KJob *job) {
            storeDone(job);
        });
    }
}

void ContactEditorBackend::storeDone(KJob *job)
{
    if (job->error() != KJob::NoError) {
        Q_EMIT errorOccured(job->errorString());
        return;
    }

    if (m_mode == EditMode) {
        Q_EMIT contactStored(m_item);
    } else if (m_mode == CreateMode) {
        Q_EMIT contactStored(static_cast<Akonadi::ItemCreateJob *>(job)->item());
    }
    Q_EMIT finished();
}

void ContactEditorBackend::storeContact(KContacts::Addressee &contact, ContactMetaData &metaData) const
{
    // TODO custom fields group description support
    // metaData.setCustomFieldDescriptions(d->mCustomFieldsWidget->localCustomFieldDescriptions());

    metaData.setDisplayNameMode(m_addressee->displayType());
}

bool ContactEditorBackend::isReadOnly() const
{
    return m_readOnly;
}
void ContactEditorBackend::setReadOnly(bool isReadOnly)
{
    if (m_readOnly == isReadOnly) {
        return;
    }
    m_readOnly = isReadOnly;
    Q_EMIT isReadOnlyChanged();
}
