// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "emailmodel.h"
#include <KLocalizedString>
#include <QDebug>

EmailModel::EmailModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

void EmailModel::loadContact(const KContacts::Addressee &contact)
{
    beginResetModel();
    m_emails = contact.emailList();
    endResetModel();
}

void EmailModel::storeContact(KContacts::Addressee &contact) const
{
    contact.setEmailList(m_emails);
}

int EmailModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_emails.count();
}

QVariant EmailModel::data(const QModelIndex &idx, int role) const
{
    const auto email = m_emails[idx.row()];
    switch (role) {
    case Qt::DisplayRole:
        return email.mail();
    case TypeRole:
        if (email.type() & KContacts::Email::Home & KContacts::Email::Work) {
            return i18n("Both:");
        }
        if (email.type() & KContacts::Email::Work) {
            return i18n("Work:");
        }
        if (email.type() & KContacts::Email::Home) {
            return i18n("Home:");
        }
        return i18n("Other:");
    case TypeValueRole:
        return (int)email.type();
    case DefaultRole:
        return email.isPreferred();
    }

    return {};
}

bool EmailModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    auto email = m_emails[index.row()];
    switch (role) {
    case Qt::DisplayRole:
        email.setEmail(value.toString());
        m_emails.replace(index.row(), email);
        Q_EMIT changed(m_emails);
        return true;
    case TypeRole:
    case TypeValueRole:
        email.setType((KContacts::Email::Type)value.toInt());
        m_emails.replace(index.row(), email);
        Q_EMIT changed(m_emails);
        return true;
    case DefaultRole:
        email.setPreferred(value.toBool());
        m_emails.replace(index.row(), email);
        Q_EMIT changed(m_emails);
        return true;
    }
    return false;
}

QHash<int, QByteArray> EmailModel::roleNames() const
{
    return {
        {Qt::DisplayRole, QByteArrayLiteral("display")},
        {TypeRole, QByteArrayLiteral("type")},
        {TypeValueRole, QByteArrayLiteral("typeValue")},
        {DefaultRole, QByteArrayLiteral("default")},
    };
}

void EmailModel::addEmail(const QString &email, Type type)
{
    beginInsertRows({}, m_emails.count(), m_emails.count());
    KContacts::Email emailObject(email);
    emailObject.setType((KContacts::Email::Type)type);
    m_emails.append(emailObject);
    endInsertRows();
    Q_EMIT changed(m_emails);
}

void EmailModel::deleteEmail(int row)
{
    if (!hasIndex(row, 0)) {
        return;
    }
    beginRemoveRows({}, row, row);
    m_emails.removeAt(row);
    endRemoveRows();
    Q_EMIT changed(m_emails);
}
