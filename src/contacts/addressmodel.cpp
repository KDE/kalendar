// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "addressmodel.h"
#include <QAbstractItemModel>

AddressModel::AddressModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

void AddressModel::loadContact(const KContacts::Addressee &contact)
{
    beginResetModel();
    m_addresses = contact.addresses();
    endResetModel();
}

void AddressModel::storeContact(KContacts::Addressee &contact) const
{
    KContacts::Address::List addresses;

    for (const auto &address : contact.addresses()) {
        contact.removeAddress(address);
    }
    for (const auto &address : m_addresses) {
        if (!address.isEmpty()) {
            addresses.append(address);
        }
    }
    for (const auto &address : addresses) {
        contact.insertAddress(address);
    }
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

bool AddressModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    auto address = m_addresses[index.row()];
    switch (role) {
    case CountryRole:
        address.setCountry(value.toString());
        m_addresses.replace(index.row(), address);
        return true;
    case ExtendedRole:
        address.setExtended(value.toString());
        m_addresses.replace(index.row(), address);
        return true;
    case LongitudeRole: {
        auto geo = address.geo();
        KContacts::Geo newGeo(geo.latitude(), value.toFloat());
        address.setGeo(newGeo);
        m_addresses.replace(index.row(), address);
        return true;
    }
    case LatitudeRole: {
        auto geo = address.geo();
        KContacts::Geo newGeo(value.toFloat(), geo.longitude());
        address.setGeo(newGeo);
        m_addresses.replace(index.row(), address);
        return true;
    }
    case LabelRole:
        address.setLabel(value.toString());
        m_addresses.replace(index.row(), address);
        return true;
    case PostalCodeRole:
        address.setPostalCode(value.toString());
        m_addresses.replace(index.row(), address);
        return true;
    case PostOfficeBoxRole:
        address.setPostOfficeBox(value.toString());
        m_addresses.replace(index.row(), address);
        return true;
    case RegionRole:
        address.setRegion(value.toString());
        m_addresses.replace(index.row(), address);
        return true;
    case StreetRole:
        address.setStreet(value.toString());
        m_addresses.replace(index.row(), address);
        return true;
    case TypeRole:
        address.setType((KContacts::Address::Type)value.toInt());
        m_addresses.replace(index.row(), address);
        return true;
    }
    return false;
}

QHash<int, QByteArray> AddressModel::roleNames() const
{
    return {
        {CountryRole, QByteArrayLiteral("country")},
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
        {TypeLabelRole, QByteArrayLiteral("typeLabel")},
    };
}

void AddressModel::addAddress()
{
    beginInsertRows({}, m_addresses.count(), m_addresses.count());
    KContacts::Address addressObject;
    m_addresses.append(addressObject);
    endInsertRows();
    Q_EMIT changed(m_addresses);
}

void AddressModel::deleteAddress(int row)
{
    if (!hasIndex(row, 0)) {
        return;
    }
    beginRemoveRows({}, row, row);
    m_addresses.removeAt(row);
    endRemoveRows();
    Q_EMIT changed(m_addresses);
}
