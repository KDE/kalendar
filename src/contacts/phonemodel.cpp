// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "phonemodel.h"
#include <KContacts/PhoneNumber>

PhoneModel::PhoneModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

void PhoneModel::loadContact(const KContacts::Addressee &contact)
{
    beginResetModel();
    m_phoneNumbers = contact.phoneNumbers();
    endResetModel();
}

void PhoneModel::storeContact(KContacts::Addressee &contact) const
{
    contact.setPhoneNumbers(m_phoneNumbers);
}

int PhoneModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_phoneNumbers.count();
}

QVariant PhoneModel::data(const QModelIndex &idx, int role) const
{
    const auto phone = m_phoneNumbers[idx.row()];
    switch (role) {
    case Qt::DisplayRole:
        return phone.number();
    case TypeRole:
        return phone.typeLabel();
    case TypeValueRole:
        return (int)phone.type();
    case SupportSmsRole:
        return phone.supportsSms();
    case DefaultRole:
        return phone.isPreferred();
    }

    return {};
}

bool PhoneModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    auto phoneNumber = m_phoneNumbers[index.row()];
    switch (role) {
    case Qt::DisplayRole:
        phoneNumber.setNumber(value.toString());
        Q_EMIT changed(m_phoneNumbers);
        return true;
    case TypeRole:
    case TypeValueRole:
        phoneNumber.setType((KContacts::PhoneNumber::Type)value.toInt());
        Q_EMIT changed(m_phoneNumbers);
        return true;
    }
    return false;
}

QHash<int, QByteArray> PhoneModel::roleNames() const
{
    return {
        {Qt::DisplayRole, QByteArrayLiteral("display")},
        {TypeRole, QByteArrayLiteral("type")},
        {TypeValueRole, QByteArrayLiteral("typeValue")},
        {DefaultRole, QByteArrayLiteral("default")},
    };
}

void PhoneModel::addPhoneNumber(const QString &phoneNumber, Type type)
{
    beginInsertRows({}, m_phoneNumbers.count(), m_phoneNumbers.count());
    m_phoneNumbers.append({phoneNumber, (KContacts::PhoneNumber::Type)type});
    endInsertRows();
    Q_EMIT changed(m_phoneNumbers);
}

void PhoneModel::deletePhoneNumber(int row)
{
    if (!hasIndex(row, 0)) {
        return;
    }
    beginRemoveRows({}, row, row);
    m_phoneNumbers.removeAt(row);
    endRemoveRows();
    Q_EMIT changed(m_phoneNumbers);
}
