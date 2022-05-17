// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <Akonadi/CollectionIdentificationAttribute>
#include <Akonadi/Item>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/ItemMonitor>
#include <KContacts/Addressee>
#include <QObject>

#include "addressmodel.h"

#include "emailmodel.h"
#include "phonemodel.h"

/// This class is a QObject wrapper for a KContact::Adressee
class AddresseeWrapper : public QObject, public Akonadi::ItemMonitor
{
    Q_OBJECT
    Q_PROPERTY(Akonadi::Item addresseeItem READ addresseeItem WRITE setAddresseeItem NOTIFY addresseeItemChanged)
    Q_PROPERTY(QString uid READ uid NOTIFY uidChanged)
    Q_PROPERTY(qint64 collectionId READ collectionId WRITE setCollectionId NOTIFY collectionIdChanged)

    // Contact information
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString nickName READ nickName WRITE setNickName NOTIFY nickNameChanged)
    Q_PROPERTY(QUrl blogFeed READ blogFeed WRITE setBlogFeed NOTIFY blogFeedChanged)
    Q_PROPERTY(QString preferredEmail READ preferredEmail NOTIFY preferredEmailChanged)
    Q_PROPERTY(KContacts::PhoneNumber::List phoneNumbers READ phoneNumbers NOTIFY phoneNumbersChanged)
    Q_PROPERTY(EmailModel *emailModel READ emailModel CONSTANT)
    Q_PROPERTY(PhoneModel *phoneModel READ phoneModel CONSTANT)

    // Address
    Q_PROPERTY(AddressModel *addressesModel READ addressesModel CONSTANT)

    // Personal information
    Q_PROPERTY(QDateTime birthday READ birthday WRITE setBirthday NOTIFY birthdayChanged)
    Q_PROPERTY(QDate anniversary READ anniversary WRITE setAnniversary NOTIFY anniversaryChanged)
    Q_PROPERTY(QString spousesName READ spousesName WRITE setSpousesName NOTIFY spousesNameChanged)

    // Buisness information
    Q_PROPERTY(QString organization READ organization WRITE setOrganization NOTIFY organizationChanged)
    Q_PROPERTY(QString profession READ profession WRITE setProfession NOTIFY professionChanged)
    Q_PROPERTY(QString title READ title WRITE setTitle NOTIFY titleChanged)
    Q_PROPERTY(QString department READ department WRITE setDepartment NOTIFY departmentChanged)
    Q_PROPERTY(QString office READ office WRITE setOffice NOTIFY officeChanged)
    Q_PROPERTY(QString managersName READ managersName WRITE setManagersName NOTIFY managersNameChanged)
    Q_PROPERTY(QString assistantsName READ assistantsName WRITE setAssistantsName NOTIFY assistantsNameChanged)

    // Other information
    Q_PROPERTY(QString note READ note WRITE setNote NOTIFY noteChanged)
    Q_PROPERTY(KContacts::Picture photo READ photo NOTIFY photoChanged)

public:
    AddresseeWrapper(QObject *parent = nullptr);
    ~AddresseeWrapper() override;

    Akonadi::Item addresseeItem() const;
    void setAddresseeItem(const Akonadi::Item &item);
    QString uid() const;

    qint64 collectionId() const;
    void setCollectionId(qint64 collectionId);

    QString name() const;
    void setName(const QString &name);

    QString nickName() const;
    void setNickName(const QString &nickName);

    QUrl blogFeed() const;
    void setBlogFeed(const QUrl &blogFDeed);

    QDateTime birthday() const;
    void setBirthday(const QDateTime &birthday);

    QString preferredEmail() const;
    KContacts::Picture photo() const;

    void setAddressee(const KContacts::Addressee &addressee);
    AddressModel *addressesModel() const;

    EmailModel *emailModel() const;
    PhoneModel *phoneModel() const;
    KContacts::PhoneNumber::List phoneNumbers() const;

    QString note() const;
    void setNote(const QString &note);

    QDate anniversary() const;
    void setAnniversary(const QDate &anniversary);

    QString organization() const;
    void setOrganization(const QString &organization);

    QString profession() const;
    void setProfession(const QString &profession);

    QString title() const;
    void setTitle(const QString &title);

    QString department() const;
    void setDepartment(const QString &department);

    QString office() const;
    void setOffice(const QString &office);

    QString managersName() const;
    void setManagersName(const QString &managersName);

    QString assistantsName() const;
    void setAssistantsName(const QString &assistantsName);

    void setSpousesName(const QString &spousesName);
    QString spousesName() const;

    // Invokable since we don't want expensive data bindings when any of the
    // fields change, instead generate it on demand
    Q_INVOKABLE QString qrCodeData() const;

    void notifyDataChanged();
Q_SIGNALS:
    void addresseeItemChanged();
    void collectionIdChanged();
    void nameChanged();
    void birthdayChanged();
    void photoChanged();
    void phoneNumbersChanged();
    void preferredEmailChanged();
    void uidChanged();
    void noteChanged();
    void nickNameChanged();
    void blogFeedChanged();

    void anniversaryChanged();
    void spousesNameChanged();

    void organizationChanged();
    void professionChanged();
    void titleChanged();
    void departmentChanged();
    void officeChanged();
    void managersNameChanged();
    void assistantsNameChanged();

private:
    void itemChanged(const Akonadi::Item &item) override;
    KContacts::Addressee m_addressee;
    qint64 m_collectionId = -1; // For when we want to edit, this is temporary
    AddressModel *m_addressesModel;
    EmailModel *m_emailModel;
    PhoneModel *m_phoneModel;
};
