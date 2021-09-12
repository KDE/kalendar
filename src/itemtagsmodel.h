// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <AkonadiCore/Item>
#include <QAbstractListModel>

class ItemTagsModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Akonadi::Item item READ item WRITE setItem NOTIFY itemChanged)

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        IdRole
    };
    Q_ENUM(Roles);

    ItemTagsModel(QObject *parent = nullptr);
    ~ItemTagsModel() = default;

    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    Akonadi::Item item() const;
    void setItem(Akonadi::Item item);

Q_SIGNALS:
    void itemChanged();

private:
    Akonadi::Item m_item;
};
