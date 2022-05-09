// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KContacts/Address>
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
    Q_ENUM(Roles);
    AddressModel(QObject *parent = nullptr);

    void setAddresses(const KContacts::Address::List &addresses);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

private:
    KContacts::Address::List m_addresses;
};
