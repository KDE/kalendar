// SPDX-FileCopyrightText: 2009 Tobias Koenig <tokoe@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QAbstractListModel>
#include <QSortFilterProxyModel>

#include <KContacts/ContactGroup>

#include <memory>

class ContactGroupModelPrivate;

class ContactGroupModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Role {
        IsReferenceRole = Qt::UserRole,
        AllEmailsRole,
        EmailRole,
        IconNameRole,
    };

    explicit ContactGroupModel(bool isEditing, QObject *parent = nullptr);
    ~ContactGroupModel() override;

    void loadContactGroup(const KContacts::ContactGroup &contactGroup);
    bool storeContactGroup(KContacts::ContactGroup &contactGroup) const;

    QString lastErrorMessage() const;

    QModelIndex index(int row, int col, const QModelIndex &parent = QModelIndex()) const override;
    QModelIndex parent(const QModelIndex &child) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
    QHash<int, QByteArray> roleNames() const override;
    QVariant headerData(int section, Qt::Orientation orientation, int role) const override;
    Qt::ItemFlags flags(const QModelIndex &index) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    Q_INVOKABLE void removeContact(int row);
    Q_INVOKABLE void addContactFromReference(const QString &gid, const QString &email);
    Q_INVOKABLE void addContactFromData(const QString &name, const QString &email);

private:
    friend class ContactGroupModelPrivate;
    std::unique_ptr<ContactGroupModelPrivate> const d;
};
