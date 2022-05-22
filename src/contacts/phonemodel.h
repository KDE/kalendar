// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KContacts/Addressee>
#include <QAbstractListModel>

class PhoneModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum ExtraRole {
        TypeRole = Qt::UserRole + 1,
        TypeValueRole,
        DefaultRole,
        SupportSmsRole,
    };

     enum Type {
         Home = 1, /**< Home number */
         Work = 2, /**< Office number */
         Msg = 4, /**< Messaging */
         Pref = 8, /**< Preferred number */
         Voice = 16, /**< Voice */
         Fax = 32, /**< Fax machine */
         Cell = 64, /**< Cell phone */
         Video = 128, /**< Video phone */
         Bbs = 256, /**< Mailbox */
         Modem = 512, /**< Modem */
         Car = 1024, /**< Car phone */
         Isdn = 2048, /**< ISDN connection */
         Pcs = 4096, /**< Personal Communication Service*/
         Pager = 8192, /**< Pager */
         // TODO add Text and textphone support vcard4
         Undefined = 16384, /**< Undefined number type */
     };
    Q_ENUM(Type)

    PhoneModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &idx, int role) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
    QHash<int, QByteArray> roleNames() const override;

    void loadContact(const KContacts::Addressee &contact);
    void storeContact(KContacts::Addressee &contact) const;

    Q_INVOKABLE void addPhoneNumber(const QString &phoneNumber, Type type);
    Q_INVOKABLE void deletePhoneNumber(int row);

Q_SIGNALS:
    void changed(const KContacts::PhoneNumber::List &phoneNumbers);

private:
    KContacts::PhoneNumber::List m_phoneNumbers;
};
