// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KContacts/Address>
#include <KContacts/Addressee>
#include <QAbstractListModel>

class AddressModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        CountryRole = Qt::UserRole + 1,
        ExtendedRole,
        FormattedAddressRole,
        HasGeoRole,
        LatitudeRole,
        LongitudeRole,
        IdRole,
        IsEmptyRole,
        LabelRole,
        PostalCodeRole,
        PostOfficeBoxRole,
        RegionRole,
        StreetRole,
        TypeRole,
        TypeLabelRole,
    };
    Q_ENUM(Roles)

    enum Type {
        Dom = 1, /**< Domestic */
        Intl = 2, /**< International */
        Postal = 4, /**< Postal */
        Parcel = 8, /**< Preferred number */
        Home = 16, /**< Home address */
        Work = 32, /**< Address at work */
        Pref = 64, /**< Preferred */
    };
    Q_ENUM(Type)

    AddressModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &idx, int role) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
    QHash<int, QByteArray> roleNames() const override;

    void loadContact(const KContacts::Addressee &contact);
    void storeContact(KContacts::Addressee &contact) const;

    Q_INVOKABLE void addAddress();
    Q_INVOKABLE void deleteAddress(int row);

Q_SIGNALS:
    void changed(KContacts::Address::List address);

private:
    KContacts::Address::List m_addresses;
};
