// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KContacts/PhoneNumber>
#include <QAbstractListModel>

class PhoneModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum ExtraRole {
        TypeRole = Qt::UserRole + 1,
        DefaultRole,
        SupportSmsRole,
    };
    PhoneModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setPhoneNumbers(const KContacts::PhoneNumber::List &phoneNumbers);

private:
    KContacts::PhoneNumber::List m_phoneNumbers;
};
