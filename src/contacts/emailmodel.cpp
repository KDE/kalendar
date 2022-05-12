// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "emailmodel.h"
#include <KLocalizedString>

EmailModel::EmailModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int EmailModel::rowCount(const QModelIndex &parent) const
{
    return m_emails.count();
}

QVariant EmailModel::data(const QModelIndex &idx, int role) const
{
    const auto email = m_emails[idx.row()];
    switch (role) {
    case Qt::DisplayRole:
        return email.mail();
    case TypeRole:
        if (email.type() & KContacts::Email::Work) {
            return i18n("Work:");
        }
        if (email.type() & KContacts::Email::Home) {
            return i18n("Home:");
        }
        return i18n("Other:");
    case DefaultRole:
        return email.isPreferred();
    }

    return {};
}

QHash<int, QByteArray> EmailModel::roleNames() const
{
    return {
        {Qt::DisplayRole, QByteArrayLiteral("display")},
        {TypeRole, QByteArrayLiteral("type")},
        {DefaultRole, QByteArrayLiteral("default")},
    };
}

void EmailModel::setEmails(const KContacts::Email::List &emails)
{
    beginResetModel();
    m_emails = emails;
    endResetModel();
}
