// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KContacts/Addressee>
#include <QAbstractListModel>

class ImppModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum ExtraRole {
        UrlRole = Qt::UserRole,
        TypeRole,
        TypeLabelRole,
        TypeIconRole,
    };

    ImppModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &idx, int role) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
    QHash<int, QByteArray> roleNames() const override;

    void loadContact(const KContacts::Addressee &contact);
    void storeContact(KContacts::Addressee &contact) const;

    Q_INVOKABLE void addImpp(const QUrl &address);
    Q_INVOKABLE void deleteImpp(const int row);

Q_SIGNALS:
    void changed(const KContacts::Impp::List &impps);

private:
    KContacts::Impp::List m_impps;
};
