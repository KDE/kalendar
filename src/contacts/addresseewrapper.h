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
#include <kcontacts/addressee.h>

#include "addressmodel.h"

#include "emailmodel.h"
#include "imppmodel.h"
#include "phonemodel.h"

/// This class is a QObject wrapper for a KContact::Adressee
class AddresseeWrapper : public QObject, public Akonadi::ItemMonitor
{
    Q_OBJECT
    // Akonadi properties
    Q_PROPERTY(Akonadi::Item addresseeItem READ addresseeItem WRITE setAddresseeItem NOTIFY addresseeItemChanged)
    Q_PROPERTY(Akonadi::Collection collection READ collection WRITE setCollection NOTIFY collectionChanged)
    Q_PROPERTY(qint64 collectionId READ collectionId NOTIFY collectionChanged)

    Q_PROPERTY(QString uid READ uid NOTIFY uidChanged)

    // Contact information
    Q_PROPERTY(QString formattedName READ formattedName WRITE setFormattedName NOTIFY formattedNameChanged)
    Q_PROPERTY(QString additionalName READ additionalName WRITE setAdditionalName NOTIFY additionalNameChanged)
    Q_PROPERTY(QString familyName READ familyName WRITE setFamilyName NOTIFY familyNameChanged)
    Q_PROPERTY(QString givenName READ givenName WRITE setGivenName NOTIFY givenNameChanged)
    Q_PROPERTY(QString prefix READ prefix WRITE setPrefix NOTIFY prefixChanged)
    Q_PROPERTY(QString suffix READ suffix WRITE setSuffix NOTIFY suffixChanged)
    Q_PROPERTY(QString nickName READ nickName WRITE setNickName NOTIFY nickNameChanged)
    Q_PROPERTY(QUrl blogFeed READ blogFeed WRITE setBlogFeed NOTIFY blogFeedChanged)
    Q_PROPERTY(QString preferredEmail READ preferredEmail NOTIFY preferredEmailChanged)
    Q_PROPERTY(KContacts::PhoneNumber::List phoneNumbers READ phoneNumbers NOTIFY phoneNumbersChanged)
    Q_PROPERTY(EmailModel *emailModel READ emailModel CONSTANT)
    Q_PROPERTY(PhoneModel *phoneModel READ phoneModel CONSTANT)

    // Address
    Q_PROPERTY(AddressModel *addressesModel READ addressesModel CONSTANT)

    // Impp
    Q_PROPERTY(ImppModel *imppModel READ imppModel CONSTANT)

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

    Q_PROPERTY(DisplayType displayType READ displayType WRITE setDisplayType NOTIFY displayTypeChanged)
public:
    /**
     * Describes what the display name should look like.
     */
    enum DisplayType {
        SimpleName, ///< A name of the form: givenName familyName
        FullName, ///< A name of the form: prefix givenName additionalName familyName suffix
        ReverseNameWithComma, ///< A name of the form: familyName, givenName
        ReverseName, ///< A name of the form: familyName givenName
        Organization, ///< The organization name
        CustomName ///< Let the user input a display name
    };
    Q_ENUM(DisplayType);

    AddresseeWrapper(QObject *parent = nullptr);
    ~AddresseeWrapper() override;

    Akonadi::Item addresseeItem() const;
    void setAddresseeItem(const Akonadi::Item &item);

    KContacts::Addressee addressee() const;
    void setAddressee(const KContacts::Addressee &addressee);

    QString uid() const;

    Akonadi::Collection collection() const;
    qint64 collectionId() const;
    void setCollection(Akonadi::Collection collection);

    DisplayType displayType() const;
    void setDisplayType(DisplayType displayType);

    QString formattedName() const;
    void setFormattedName(const QString &formattedName);

    QString nickName() const;
    void setNickName(const QString &nickName);

    QUrl blogFeed() const;
    void setBlogFeed(const QUrl &blogFDeed);

    QDateTime birthday() const;
    void setBirthday(const QDateTime &birthday);

    QString preferredEmail() const;
    KContacts::Picture photo() const;

    AddressModel *addressesModel() const;
    ImppModel *imppModel() const;

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

    QString additionalName() const;
    void setAdditionalName(const QString &additionalName);

    QString familyName() const;
    void setFamilyName(const QString &familyName);

    QString givenName() const;
    void setGivenName(const QString &givenName);

    QString prefix() const;
    void setPrefix(const QString &prefix);

    QString suffix() const;
    void setSuffix(const QString &suffix);

    // Invokable since we don't want expensive data bindings when any of the
    // fields change, instead generate it on demand
    Q_INVOKABLE QString qrCodeData() const;

    void notifyDataChanged();
Q_SIGNALS:
    void addresseeItemChanged();
    void collectionChanged();
    void formattedNameChanged();
    void birthdayChanged();
    void photoChanged();
    void phoneNumbersChanged();
    void preferredEmailChanged();
    void uidChanged();
    void noteChanged();
    void nickNameChanged();
    void blogFeedChanged();
    void additionalNameChanged();
    void familyNameChanged();
    void givenNameChanged();
    void prefixChanged();
    void suffixChanged();

    void anniversaryChanged();
    void spousesNameChanged();

    void organizationChanged();
    void professionChanged();
    void titleChanged();
    void departmentChanged();
    void officeChanged();
    void managersNameChanged();
    void assistantsNameChanged();
    void displayTypeChanged();

private:
    void itemChanged(const Akonadi::Item &item) override;
    KContacts::Addressee m_addressee;
    Akonadi::Collection m_collection; // For when we want to edit, this is temporary
    AddressModel *m_addressesModel;
    EmailModel *m_emailModel;
    ImppModel *m_imppModel;
    PhoneModel *m_phoneModel;
    DisplayType m_displayType;
};
