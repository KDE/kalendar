// SPDX-FileCopyrightText: 2007 Tobias Koenig <tokoe@kde.org>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

#include <Akonadi/Collection>
#include <Akonadi/EntityTreeModel>
#include <KCheckableProxyModel>

class ContactCollectionModel : public KCheckableProxyModel
{
public:
    explicit ContactCollectionModel(QObject *parent);

    Q_REQUIRED_RESULT QVariant data(const QModelIndex &index, int role) const override;
};
