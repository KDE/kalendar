// SPDX-FileCopyrightText: 2007-2009 Tobias Koenig <tokoe@kde.org>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "contactgroupeditor.h"
#include <kconfigwidgets_version.h>
#include <qobjectdefs.h>
#if KCONFIGWIDGETS_VERSION >= QT_VERSION_CHECK(5, 93, 0)
#include <KStatefulBrush> // was moved to own header in 5.93.0
#endif

#include "contactgroupmodel.h"

#include <Akonadi/CollectionDialog>
#include <Akonadi/CollectionFetchJob>
#include <Akonadi/ItemCreateJob>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/ItemModifyJob>
#include <Akonadi/Monitor>
#include <Akonadi/Session>
#include <KColorScheme>
#include <KContacts/ContactGroup>
#include <KLocalizedString>
#include <KMessageBox>

#include <QMessageBox>
#include <QTimer>

using namespace Akonadi;

class ContactGroupEditorPrivate
{
public:
    ContactGroupEditorPrivate(ContactGroupEditor *parent);
    ~ContactGroupEditorPrivate();

    void itemFetchDone(KJob *job);
    void parentCollectionFetchDone(KJob *job);
    void storeDone(KJob *job);
    void itemChanged(const Akonadi::Item &item, const QSet<QByteArray> &notUsed);
    void memberChanged();

    void loadContactGroup(const KContacts::ContactGroup &group);
    Q_REQUIRED_RESULT bool storeContactGroup(KContacts::ContactGroup &group);
    void setupMonitor();

    ContactGroupEditor::Mode mMode = ContactGroupEditor::Mode::CreateMode;
    Item mItem;
    Collection mCollection;
    Collection mDefaultCollection;
    ContactGroupEditor *mParent = nullptr;
    ContactGroupModel *mGroupModel = nullptr;
    Monitor *mMonitor = nullptr;
    QString mName;
    bool mReadOnly = false;
};

ContactGroupEditorPrivate::ContactGroupEditorPrivate(ContactGroupEditor *parent)
    : mParent(parent)
{
}

ContactGroupEditorPrivate::~ContactGroupEditorPrivate()
{
    delete mMonitor;
}

void ContactGroupEditorPrivate::itemFetchDone(KJob *job)
{
    if (job->error()) {
        return;
    }

    auto fetchJob = qobject_cast<ItemFetchJob *>(job);
    if (!fetchJob) {
        return;
    }

    if (fetchJob->items().isEmpty()) {
        return;
    }

    mItem = fetchJob->items().at(0);

    mParent->setReadOnly(false);
    if (mMode == ContactGroupEditor::EditMode) {
        // if in edit mode we have to fetch the parent collection to find out
        // about the modify rights of the item

        auto collectionFetchJob = new Akonadi::CollectionFetchJob(mItem.parentCollection(), Akonadi::CollectionFetchJob::Base);
        mParent->connect(collectionFetchJob, &CollectionFetchJob::result, mParent, [this](KJob *job) {
            parentCollectionFetchDone(job);
        });
    } else {
        const auto group = mItem.payload<KContacts::ContactGroup>();
        loadContactGroup(group);
    }
}

void ContactGroupEditorPrivate::parentCollectionFetchDone(KJob *job)
{
    if (job->error()) {
        return;
    }

    auto fetchJob = qobject_cast<Akonadi::CollectionFetchJob *>(job);
    if (!fetchJob) {
        return;
    }

    const Akonadi::Collection parentCollection = fetchJob->collections().at(0);
    if (parentCollection.isValid()) {
        mReadOnly = !(parentCollection.rights() & Collection::CanChangeItem);
    }
    mCollection = parentCollection;
    Q_EMIT mParent->collectionChanged();

    const auto group = mItem.payload<KContacts::ContactGroup>();
    loadContactGroup(group);

    mParent->setReadOnly(mReadOnly);
}

void ContactGroupEditorPrivate::storeDone(KJob *job)
{
    if (job->error()) {
        Q_EMIT mParent->errorOccured(job->errorString());
        return;
    }

    if (mMode == ContactGroupEditor::EditMode) {
        Q_EMIT mParent->contactGroupStored(mItem);
    } else if (mMode == ContactGroupEditor::CreateMode) {
        Q_EMIT mParent->contactGroupStored(static_cast<ItemCreateJob *>(job)->item());
    }
    Q_EMIT mParent->finished();
}

void ContactGroupEditor::fetchItem()
{
    auto job = new ItemFetchJob(d->mItem);
    job->fetchScope().fetchFullPayload();
    job->fetchScope().setAncestorRetrieval(Akonadi::ItemFetchScope::Parent);

    connect(job, &ItemFetchJob::result, this, [this](KJob *job) {
        d->itemFetchDone(job);
    });
}

void ContactGroupEditorPrivate::loadContactGroup(const KContacts::ContactGroup &group)
{
    mName = group.name();
    Q_EMIT mParent->nameChanged();

    mGroupModel->loadContactGroup(group);
}

bool ContactGroupEditorPrivate::storeContactGroup(KContacts::ContactGroup &group)
{
    group.setName(mName);

    if (!mGroupModel->storeContactGroup(group)) {
        Q_EMIT mParent->errorOccured(mGroupModel->lastErrorMessage());
        return false;
    }

    return true;
}

void ContactGroupEditorPrivate::setupMonitor()
{
    delete mMonitor;
    mMonitor = new Monitor;
    mMonitor->setObjectName(QStringLiteral("ContactGroupEditorMonitor"));
    mMonitor->ignoreSession(Session::defaultSession());

    QObject::connect(mMonitor, &Monitor::itemChanged, mParent, [this](const Akonadi::Item &, const QSet<QByteArray> &) {
        mParent->itemChanged();
    });
}

ContactGroupEditor::ContactGroupEditor(QObject *parent)
    : QObject(parent)
    , d(new ContactGroupEditorPrivate(this))
{
    d->mMode = ContactGroupEditor::CreateMode;
    d->mGroupModel = new ContactGroupModel(true, this);
    KContacts::ContactGroup dummyGroup;
    d->mGroupModel->loadContactGroup(dummyGroup);
}

ContactGroupEditor::~ContactGroupEditor() = default;

void ContactGroupEditor::loadContactGroup(const Akonadi::Item &item)
{
    if (d->mMode == CreateMode) {
        Q_ASSERT_X(false, "ContactGroupEditor::loadContactGroup", "You are calling loadContactGroup in CreateMode!");
    }


    auto job = new ItemFetchJob(item);
    job->fetchScope().fetchFullPayload();
    job->fetchScope().setAncestorRetrieval(Akonadi::ItemFetchScope::Parent);

    connect(job, &ItemModifyJob::result, this, [this](KJob *job) {
        d->itemFetchDone(job);
    });

    d->setupMonitor();
    d->mMonitor->setItemMonitored(item);
}

bool ContactGroupEditor::saveContactGroup()
{
    if (d->mMode == EditMode) {
        if (!d->mItem.isValid()) {
            return false;
        }

        if (d->mReadOnly) {
            return true;
        }

        auto group = d->mItem.payload<KContacts::ContactGroup>();

        if (!d->storeContactGroup(group)) {
            return false;
        }

        d->mItem.setPayload<KContacts::ContactGroup>(group);

        auto job = new ItemModifyJob(d->mItem);
        connect(job, &ItemModifyJob::result, this, [this](KJob *job) {
            d->storeDone(job);
        });
    } else if (d->mMode == CreateMode) {
        if (!d->mDefaultCollection.isValid()) {
            const QStringList mimeTypeFilter(KContacts::ContactGroup::mimeType());
            Q_EMIT errorOccured(i18n("No address book selected"));
            return false;

            // TODO check if this can happen
            // QPointer<CollectionDialog> dlg = new CollectionDialog(this);
            // dlg->setMimeTypeFilter(mimeTypeFilter);
            // dlg->setAccessRightsFilter(Collection::CanCreateItem);
            // dlg->setWindowTitle(i18nc("@title:window", "Select Address Book"));
            // dlg->setDescription(i18n("Select the address book the new contact group shall be saved in:"));

            // if (dlg->exec() == QDialog::Accepted) {
            //     setDefaultAddressBook(dlg->selectedCollection());
            //     delete dlg;
            // } else {
            //     delete dlg;
            //     return false;
            // }
        }

        KContacts::ContactGroup group;
        if (!d->storeContactGroup(group)) {
            return false;
        }

        Item item;
        item.setPayload<KContacts::ContactGroup>(group);
        item.setMimeType(KContacts::ContactGroup::mimeType());

        auto job = new ItemCreateJob(item, d->mDefaultCollection);
        connect(job, &ItemCreateJob::result, this, [this](KJob *job) {
            d->storeDone(job);
        });
    }

    return true;
}

void ContactGroupEditor::setDefaultAddressBook(const Akonadi::Collection &collection)
{
    d->mDefaultCollection = collection;
}

QString ContactGroupEditor::name() const
{
    return d->mName;
}

void ContactGroupEditor::setName(const QString &name)
{
    if (d->mName == name) {
        return;
    }

    d->mName = name;
    Q_EMIT nameChanged();
}

qint64 ContactGroupEditor::collectionId() const
{
    return d->mCollection.isValid() ? d->mCollection.id() : d->mDefaultCollection.id();
}

ContactGroupEditor::Mode ContactGroupEditor::mode() const
{
    return d->mMode;
}

void ContactGroupEditor::setMode(Mode mode)
{
    if (d->mMode == mode) {
        return;
    }
    d->mMode = mode;
    Q_EMIT modeChanged();
}

bool ContactGroupEditor::isReadOnly() const
{
    return d->mReadOnly;
}

void ContactGroupEditor::setReadOnly(bool isReadOnly)
{
    if (d->mReadOnly == isReadOnly) {
        return;
    }
    d->mReadOnly = isReadOnly;
    Q_EMIT isReadOnlyChanged();
}

QAbstractItemModel *ContactGroupEditor::groupModel() const
{
    return d->mGroupModel;
}

#include "moc_contactgroupeditor.cpp"
