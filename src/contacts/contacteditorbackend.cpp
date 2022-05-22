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
    m_defaltAddressBook = addressbook;
}

AddresseeWrapper *ContactEditorBackend::contact()
{
    if (m_addressee) {
        return m_addressee;
    }

    // Only create
    if (m_mode == ContactEditorBackend::CreateMode) {
        m_addressee = new AddresseeWrapper(this);
        Q_EMIT addresseeChanged();
        return m_addressee;
    }

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

void ContactEditorBackend::loadContact(const Akonadi::Item &item)
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

    connect(m_monitor, &Akonadi::Monitor::itemChanged, this, [this](const Akonadi::Item &item, const QSet<QByteArray> &set) {
        itemChanged(item, set);
    });
}

void ContactEditorBackend::itemChanged(const Akonadi::Item &item, const QSet<QByteArray> &)
{
    Q_UNUSED(item)
    // TODO port to QML
    // QPointer<QMessageBox> dlg = new QMessageBox(mParent); // krazy:exclude=qclasses

    // dlg->setInformativeText(i18n("The contact has been changed by someone else.\nWhat should be done?"));
    // dlg->addButton(i18n("Take over changes"), QMessageBox::AcceptRole);
    // dlg->addButton(i18n("Ignore and Overwrite changes"), QMessageBox::RejectRole);

    // if (dlg->exec() == QMessageBox::AcceptRole) {
    //     auto job = new Akonadi::ItemFetchJob(mItem);
    //     job->fetchScope().fetchFullPayload();
    //     job->fetchScope().fetchAttribute<ContactMetaDataAttribute>();
    //     job->fetchScope().setAncestorRetrieval(Akonadi::ItemFetchScope::Parent);

    //    mParent->connect(job, &ItemFetchJob::result, mParent, [this](KJob *job) {
    //        itemFetchDone(job);
    //    });
    //}

    // delete dlg;
}

void ContactEditorBackend::itemFetchDone(KJob *job)
{
    if (job->error() != KJob::NoError) {
        Q_EMIT error(job->errorString());
        Q_EMIT finished();
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
        m_addressee->setDisplayType((AddresseeWrapper::DisplayType)m_contactMetaData.displayNameMode());
        m_addressee->setAddressee(m_item.payload<KContacts::Addressee>());
    }
}

void ContactEditorBackend::parentCollectionFetchDone(KJob *job)
{
    if (job->error()) {
        Q_EMIT error(job->errorString());
        Q_EMIT finished();
        return;
    }

    auto fetchJob = qobject_cast<Akonadi::CollectionFetchJob *>(job);
    if (!fetchJob) {
        return;
    }

    const Akonadi::Collection parentCollection = fetchJob->collections().at(0);
    if (parentCollection.isValid()) {
        setReadOnly(!(parentCollection.rights() & Akonadi::Collection::CanChangeItem));
    }

    m_contactMetaData.load(m_item);
    m_addressee->setDisplayType((AddresseeWrapper::DisplayType)m_contactMetaData.displayNameMode());
    m_addressee->setAddressee(m_item.payload<KContacts::Addressee>());
}

void ContactEditorBackend::saveContactInAddressBook()
{
    if (m_mode == EditMode) {
        if (!m_item.isValid() || m_readOnly) {
            Q_EMIT finished();
            return;
        }

        auto addr = m_item.payload<KContacts::Addressee>();

        storeContact(addr, m_contactMetaData);

        m_contactMetaData.store(m_item);

        m_item.setPayload<KContacts::Addressee>(addr);

        auto job = new Akonadi::ItemModifyJob(m_item);
        connect(job, &Akonadi::ItemModifyJob::result, this, [this](KJob *job) {
            storeDone(job);
        });
    } else if (m_mode == CreateMode) {
        if (!m_defaltAddressBook.isValid()) {
            const QStringList mimeTypeFilter(KContacts::Addressee::mimeType());
            // TODO port to collection picker page
            //
            // QPointer<Akonadi::CollectionDialog> dlg = new Akonadi::CollectionDialog(nullptr);
            // dlg->setMimeTypeFilter(mimeTypeFilter);
            // dlg->setAccessRightsFilter(Akonadi::Collection::CanCreateItem);
            // dlg->setWindowTitle(i18nc("@title:window", "Select Address Book"));
            // dlg->setDescription(i18n("Select the address book the new contact shall be saved in:"));
            // if (dlg->exec() == QDialog::Accepted) {
            //     setDefaultAddressBook(dlg->selectedCollection());
            //     delete dlg;
            // } else {
            //     delete dlg;
            //     return;
            // }
        }

        KContacts::Addressee addr(m_addressee->addressee());
        storeContact(addr, m_contactMetaData);

        Akonadi::Item item;
        item.setPayload<KContacts::Addressee>(addr);
        item.setMimeType(KContacts::Addressee::mimeType());

        m_contactMetaData.store(item);

        auto job = new Akonadi::ItemCreateJob(item, m_defaltAddressBook);
        connect(job, &Akonadi::ItemCreateJob::result, this, [this](KJob *job) {
            storeDone(job);
        });
    }
}

void ContactEditorBackend::storeDone(KJob *job)
{
    if (job->error() != KJob::NoError) {
        Q_EMIT error(job->errorString());
        Q_EMIT finished();
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
