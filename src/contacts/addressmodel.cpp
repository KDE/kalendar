// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contacts/addressmodel.h"
#include <QDebug>
#include <qabstractitemmodel.h>

AddressModel::AddressModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int AddressModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_addresses.count();
}

QVariant AddressModel::data(const QModelIndex &idx, int role) const
{
    const auto &address = m_addresses[idx.row()];
    switch (role) {
    case CountryRole:
        return address.country();
    case ExtendedRole:
        return address.extended();
    case FormattedAddressRole:
        return address.formatted(KContacts::AddressFormatStyle::MultiLineInternational);
    case HasGeoRole:
        return address.geo().isValid();
    case LongitudeRole:
        return address.geo().longitude();
    case LatitudeRole:
        return address.geo().latitude();
    case IdRole:
        return address.id();
    case IsEmptyRole:
        return address.isEmpty();
    case LabelRole:
        return address.label();
    case PostalCodeRole:
        return address.postalCode();
    case PostOfficeBoxRole:
        return address.postOfficeBox();
    case RegionRole:
        return address.region();
    case StreetRole:
        return address.street();
    case TypeRole:
        return QVariant::fromValue(address.type());
    case TypeLabelRole:
        return address.typeLabel();
    default:
        return {};
    }
}

QHash<int, QByteArray> AddressModel::roleNames() const
{
    return {{CountryRole, QByteArrayLiteral("country")},
            {ExtendedRole, QByteArrayLiteral("extended")},
            {FormattedAddressRole, QByteArrayLiteral("formattedAddress")},
            {HasGeoRole, QByteArrayLiteral("hasGeo")},
            {LatitudeRole, QByteArrayLiteral("latitude")},
            {LongitudeRole, QByteArrayLiteral("longitude")},
            {IdRole, QByteArrayLiteral("id")},
            {IsEmptyRole, QByteArrayLiteral("isEmpty")},
            {LabelRole, QByteArrayLiteral("label")},
            {PostalCodeRole, QByteArrayLiteral("postalCode")},
            {PostOfficeBoxRole, QByteArrayLiteral("postOfficeBox")},
            {RegionRole, QByteArrayLiteral("region")},
            {StreetRole, QByteArrayLiteral("street")},
            {TypeRole, QByteArrayLiteral("type")},
            {TypeLabelRole, QByteArrayLiteral("typeLabel")}};
}

void AddressModel::setAddresses(const KContacts::Address::List &addresses)
{
    beginResetModel();
    m_addresses = addresses;
    endResetModel();
}
