// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "addressmodel.h"
#include <Akonadi/CollectionIdentificationAttribute>
#include <Akonadi/Item>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/ItemMonitor>
#include <KContacts/Addressee>
#include <QObject>
#include <qdatetime.h>

/// This class is a QObject wrapper for a KContact::Adressee
class AddresseeWrapper : public QObject, public Akonadi::ItemMonitor
{
    Q_OBJECT
    Q_PROPERTY(Akonadi::Item addresseeItem READ addresseeItem WRITE setAddresseeItem NOTIFY addresseeItemChanged)
    Q_PROPERTY(QString uid READ uid NOTIFY uidChanged)
    Q_PROPERTY(qint64 collectionId READ collectionId WRITE setCollectionId NOTIFY collectionIdChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString preferredEmail READ preferredEmail NOTIFY preferredEmailChanged)
    Q_PROPERTY(QDateTime birthday READ birthday WRITE setBirthday NOTIFY birthdayChanged)
    Q_PROPERTY(KContacts::PhoneNumber::List phoneNumbers READ phoneNumbers NOTIFY phoneNumbersChanged)
    Q_PROPERTY(KContacts::Picture photo READ photo NOTIFY photoChanged)
    Q_PROPERTY(AddressModel *addressesModel READ addressesModel CONSTANT)

public:
    AddresseeWrapper(QObject *parent = nullptr);
    ~AddresseeWrapper() override;

    Akonadi::Item addresseeItem() const;
    void setAddresseeItem(const Akonadi::Item &item);
    QString uid() const;

    KContacts::PhoneNumber::List phoneNumbers() const;
    AddressModel *addressesModel() const;

    qint64 collectionId() const;
    void setCollectionId(qint64 collectionId);
    QString name() const;
    QString preferredEmail() const;
    QDateTime birthday() const;
    void setName(const QString &name);
    void setBirthday(const QDateTime &birthday);
    KContacts::Picture photo() const;
    void setAddressee(const KContacts::Addressee &addressee);
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

private:
    void itemChanged(const Akonadi::Item &item) override;
    KContacts::Addressee m_addressee;
    qint64 m_collectionId = -1; // For when we want to edit, this is temporary
    AddressModel *m_addressesModel;
};
