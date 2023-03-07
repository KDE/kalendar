// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "imppmodel.h"
#include <KContacts/Impp>
#include <KLocalizedString>

ImppModel::ImppModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

void ImppModel::loadContact(const KContacts::Addressee &contact)
{
    beginResetModel();
    m_impps = contact.imppList();
    endResetModel();
}

void ImppModel::storeContact(KContacts::Addressee &contact) const
{
    contact.setImppList(m_impps);
}

int ImppModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_impps.count();
}

QVariant ImppModel::data(const QModelIndex &idx, int role) const
{
    const auto impp = m_impps[idx.row()];
    switch (role) {
    case Qt::DisplayRole:
    case UrlRole:
        return impp.address();
    case TypeRole:
        return impp.serviceType();
    case TypeLabelRole:
        return impp.serviceLabel();
    case TypeIconRole:
        return impp.serviceIcon();
    }

    return {};
}

bool ImppModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    auto impp = m_impps[index.row()];
    switch (role) {
    case UrlRole:
        impp.setAddress(QUrl(value.toString()));
        m_impps.replace(index.row(), impp);
        Q_EMIT changed(m_impps);
        return true;
    }
    return false;
}

QHash<int, QByteArray> ImppModel::roleNames() const
{
    return {
        {UrlRole, QByteArrayLiteral("url")},
        {TypeRole, QByteArrayLiteral("type")},
        {TypeLabelRole, QByteArrayLiteral("typeLabel")},
        {TypeIconRole, QByteArrayLiteral("typeIcon")},
    };
}

void ImppModel::addImpp(const QUrl &impp)
{
    beginInsertRows({}, m_impps.count(), m_impps.count());
    m_impps.append(KContacts::Impp(QUrl(impp)));
    endInsertRows();
    Q_EMIT changed(m_impps);
}

void ImppModel::deleteImpp(int row)
{
    if (!hasIndex(row, 0)) {
        return;
    }
    beginRemoveRows({}, row, row);
    m_impps.removeAt(row);
    endRemoveRows();
    Q_EMIT changed(m_impps);
}
