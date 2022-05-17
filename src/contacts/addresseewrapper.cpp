// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "addresseewrapper.h"
#include "kalendar_contact_debug.h"
#include <Akonadi/ItemMonitor>
#include <KContacts/Addressee>
#include <KContacts/VCardConverter>
#include <KLocalizedString>
#include <QBitArray>
#include <QJSValue>

AddresseeWrapper::AddresseeWrapper(QObject *parent)
    : QObject(parent)
    , Akonadi::ItemMonitor()
    , m_addressesModel(new AddressModel(this))
    , m_emailModel(new EmailModel(this))
    , m_phoneModel(new PhoneModel(this))
{
    Akonadi::ItemFetchScope scope;
    scope.fetchFullPayload();
    scope.fetchAllAttributes();
    scope.setFetchRelations(true);
    scope.setAncestorRetrieval(Akonadi::ItemFetchScope::Parent);
    setFetchScope(scope);
}

AddresseeWrapper::~AddresseeWrapper() = default;

void AddresseeWrapper::notifyDataChanged()
{
    Q_EMIT collectionIdChanged();
    Q_EMIT nameChanged();
    Q_EMIT birthdayChanged();
    Q_EMIT photoChanged();
    Q_EMIT phoneNumbersChanged();
    Q_EMIT preferredEmailChanged();
    Q_EMIT uidChanged();
    Q_EMIT noteChanged();
    Q_EMIT nickNameChanged();
    Q_EMIT blogFeedChanged();
    Q_EMIT anniversaryChanged();
    Q_EMIT spousesNameChanged();
    Q_EMIT organizationChanged();
    Q_EMIT professionChanged();
    Q_EMIT titleChanged();
    Q_EMIT departmentChanged();
    Q_EMIT officeChanged();
    Q_EMIT managersNameChanged();
    Q_EMIT assistantsNameChanged();
}

Akonadi::Item AddresseeWrapper::addresseeItem() const
{
    return item();
}

AddressModel *AddresseeWrapper::addressesModel() const
{
    return m_addressesModel;
}

void AddresseeWrapper::setAddresseeItem(const Akonadi::Item &addresseeItem)
{
    if (addresseeItem.hasPayload<KContacts::Addressee>()) {
        setItem(addresseeItem);
        setAddressee(addresseeItem.payload<KContacts::Addressee>());
        Q_EMIT addresseeItemChanged();
        Q_EMIT collectionIdChanged();
    } else {
        // Payload not found, try to fetch it
        auto job = new Akonadi::ItemFetchJob(addresseeItem);
        job->fetchScope().fetchFullPayload();
        connect(job, &Akonadi::ItemFetchJob::result, this, [this](KJob *job) {
            auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
            auto item = fetchJob->items().at(0);
            if (item.hasPayload<KContacts::Addressee>()) {
                setItem(item);
                setAddressee(item.payload<KContacts::Addressee>());
                Q_EMIT addresseeItemChanged();
                Q_EMIT collectionIdChanged();
            } else {
                qCWarning(KALENDAR_LOG) << "This is not an addressee item.";
            }
        });
    }
}

void AddresseeWrapper::itemChanged(const Akonadi::Item &item)
{
    setAddressee(item.payload<KContacts::Addressee>());
}

void AddresseeWrapper::setAddressee(const KContacts::Addressee &addressee)
{
    m_addressee = addressee;
    m_addressesModel->setAddresses(addressee.addresses());
    m_emailModel->setEmails(addressee.emailList());
    m_phoneModel->setPhoneNumbers(addressee.phoneNumbers());
    notifyDataChanged();
}

QString AddresseeWrapper::uid() const
{
    return m_addressee.uid();
}

qint64 AddresseeWrapper::collectionId() const
{
    return m_collectionId < 0 ? item().parentCollection().id() : m_collectionId;
}

void AddresseeWrapper::setCollectionId(qint64 collectionId)
{
    m_collectionId = collectionId;
    Q_EMIT collectionIdChanged();
}

QString AddresseeWrapper::name() const
{
    return m_addressee.formattedName();
}

void AddresseeWrapper::setName(const QString &name)
{
    if (name == m_addressee.formattedName()) {
        return;
    }
    m_addressee.setFormattedName(name);
    Q_EMIT nameChanged();
}

QDateTime AddresseeWrapper::birthday() const
{
    return m_addressee.birthday();
}

void AddresseeWrapper::setBirthday(const QDateTime &birthday)
{
    if (birthday == m_addressee.birthday()) {
        return;
    }
    m_addressee.setBirthday(birthday);
    Q_EMIT birthdayChanged();
}

KContacts::PhoneNumber::List AddresseeWrapper::phoneNumbers() const
{
    return m_addressee.phoneNumbers();
}

KContacts::Picture AddresseeWrapper::photo() const
{
    return m_addressee.photo();
}

QString AddresseeWrapper::preferredEmail() const
{
    return m_addressee.preferredEmail();
}

EmailModel *AddresseeWrapper::emailModel() const
{
    return m_emailModel;
}

PhoneModel *AddresseeWrapper::phoneModel() const
{
    return m_phoneModel;
}

QString AddresseeWrapper::qrCodeData() const
{
    KContacts::VCardConverter converter;
    KContacts::Addressee addr(m_addressee);
    addr.setPhoto(KContacts::Picture());
    addr.setLogo(KContacts::Picture());
    return QString::fromUtf8(converter.createVCard(addr));
}

QString AddresseeWrapper::note() const
{
    return m_addressee.note();
}

QDate AddresseeWrapper::anniversary() const
{
    return m_addressee.anniversary();
}

QString AddresseeWrapper::spousesName() const
{
    return m_addressee.spousesName();
}

QString AddresseeWrapper::organization() const
{
    return m_addressee.organization();
}

QString AddresseeWrapper::profession() const
{
    return m_addressee.profession();
}

QString AddresseeWrapper::title() const
{
    return m_addressee.title();
}

QString AddresseeWrapper::department() const
{
    return m_addressee.department();
}

QString AddresseeWrapper::office() const
{
    return m_addressee.office();
}

QString AddresseeWrapper::managersName() const
{
    return m_addressee.managersName();
}

QString AddresseeWrapper::assistantsName() const
{
    return m_addressee.assistantsName();
}

void AddresseeWrapper::setNote(const QString &note)
{
    if (note == m_addressee.note()) {
        return;
    }
    m_addressee.setNote(note);
    Q_EMIT noteChanged();
}

void AddresseeWrapper::setAnniversary(const QDate &anniversary)
{
    if (anniversary == m_addressee.anniversary()) {
        return;
    }
    m_addressee.setAnniversary(anniversary);
    Q_EMIT anniversaryChanged();
}

void AddresseeWrapper::setSpousesName(const QString &spousesName)
{
    if (spousesName == m_addressee.spousesName()) {
        return;
    }
    m_addressee.setSpousesName(spousesName);
    Q_EMIT spousesNameChanged();
}

void AddresseeWrapper::setOrganization(const QString &organization)
{
    if (organization == m_addressee.organization()) {
        return;
    }
    m_addressee.setOrganization(organization);
    Q_EMIT organizationChanged();
}

void AddresseeWrapper::setProfession(const QString &profession)
{
    if (profession == m_addressee.profession()) {
        return;
    }
    m_addressee.setProfession(profession);
    Q_EMIT professionChanged();
}

void AddresseeWrapper::setTitle(const QString &title)
{
    if (title == m_addressee.title()) {
        return;
    }
    m_addressee.setTitle(title);
    Q_EMIT titleChanged();
}

void AddresseeWrapper::setDepartment(const QString &department)
{
    if (department == m_addressee.department()) {
        return;
    }
    m_addressee.setDepartment(department);
    Q_EMIT departmentChanged();
}

void AddresseeWrapper::setOffice(const QString &office)
{
    if (office == m_addressee.office()) {
        return;
    }
    m_addressee.setOffice(office);
    Q_EMIT officeChanged();
}

void AddresseeWrapper::setManagersName(const QString &managersName)
{
    if (managersName == m_addressee.managersName()) {
        return;
    }
    m_addressee.setManagersName(managersName);
    Q_EMIT managersNameChanged();
}

void AddresseeWrapper::setAssistantsName(const QString &assistantsName)
{
    if (assistantsName == m_addressee.assistantsName()) {
        return;
    }
    m_addressee.setAssistantsName(assistantsName);
    Q_EMIT assistantsNameChanged();
}

QString AddresseeWrapper::nickName() const
{
    return m_addressee.nickName();
}

void AddresseeWrapper::setNickName(const QString &nickName)
{
    if (nickName == m_addressee.nickName()) {
        return;
    }
    m_addressee.setNickName(nickName);
    Q_EMIT nickNameChanged();
}

QUrl AddresseeWrapper::blogFeed() const
{
    return m_addressee.blogFeed();
}

void AddresseeWrapper::setBlogFeed(const QUrl &blogFeed)
{
    if (blogFeed == m_addressee.blogFeed()) {
        return;
    }
    m_addressee.setBlogFeed(blogFeed);
    Q_EMIT blogFeedChanged();
}
