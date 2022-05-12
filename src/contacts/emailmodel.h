// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KContacts/Email>
#include <QAbstractListModel>

class EmailModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum ExtraRole {
        TypeRole = Qt::UserRole + 1,
        DefaultRole,
    };
    EmailModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setEmails(const KContacts::Email::List &emails);

private:
    KContacts::Email::List m_emails;
};
