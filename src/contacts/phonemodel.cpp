// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "phonemodel.h"
#include <KLocalizedString>

PhoneModel::PhoneModel(QObject *parent)
    : QAbstractListModel(parent)
{
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
    case SupportSmsRole:
        return phone.supportsSms();
    case DefaultRole:
        return phone.isPreferred();
    }

    return {};
}

QHash<int, QByteArray> PhoneModel::roleNames() const
{
    return {
        {Qt::DisplayRole, QByteArrayLiteral("display")},
        {TypeRole, QByteArrayLiteral("type")},
        {DefaultRole, QByteArrayLiteral("default")},
    };
}

void PhoneModel::setPhoneNumbers(const KContacts::PhoneNumber::List &phoneNumbers)
{
    beginResetModel();
    m_phoneNumbers = phoneNumbers;
    endResetModel();
}
