// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#include "identitymodel.h"
#include <KIdentityManagementCore/Identity>
#include <KIdentityManagementCore/IdentityManager>
#include <KLocalizedString>


IdentityModel::IdentityModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_identityManager(KIdentityManagementCore::IdentityManager::self())
{
    connect(m_identityManager, &KIdentityManagementCore::IdentityManager::needToReloadIdentitySettings, this, &IdentityModel::reloadUoidList);
    reloadUoidList();

}

void IdentityModel::reloadUoidList()
{
    beginResetModel();
    m_identitiesUoid.clear();
    for (const auto &identity : *m_identityManager) {
        m_identitiesUoid << identity.uoid();
    }
    endResetModel();
}


IdentityModel::~IdentityModel()
{
}

QVariant IdentityModel::data (const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return {};
    }
    const auto &identity = m_identityManager->modifyIdentityForUoid(m_identitiesUoid[index.row()]);
    switch (role) {
        case Qt::DisplayRole:
            return QString(identity.identityName() + i18nc("Separator between identity name and email address", " - ") + identity.fullEmailAddr());
        case EmailRole:
            return identity.primaryEmailAddress();
        case UoidRole:
            return identity.uoid();
    }
    
    return {};
}

int IdentityModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_identitiesUoid.count();
}

QString IdentityModel::email(uint uoid)
{
    return m_identityManager->identityForUoid(uoid).primaryEmailAddress();
}

QHash<int, QByteArray> IdentityModel::roleNames() const
{
    return {
        {Qt::DisplayRole, QByteArrayLiteral("display")},
        {UoidRole, QByteArrayLiteral("uoid")},
        {EmailRole, QByteArrayLiteral("email")}
    };
}
