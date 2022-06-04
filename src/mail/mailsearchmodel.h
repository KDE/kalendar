// SPDX-FileCopyrightText: 2011-2022 Laurent Montel <montel@kde.org>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-only

#pragma once

#include <Akonadi/MessageModel>
#include <QHash>

/// Model allowing to search for a messae
class MailSearchModel : public Akonadi::MessageModel
{
    Q_OBJECT

public:
    explicit MailSearchModel(Akonadi::Monitor *monitor, QObject *parent = nullptr);
    ~MailSearchModel() override;

    QVariant data(const QModelIndex &idx, int role) const override;

protected:
    int entityColumnCount(HeaderGroup headerGroup) const override;
    QVariant entityData(const Akonadi::Item &item, int column, int role = Qt::DisplayRole) const override;

private:
    Q_REQUIRED_RESULT QString fullCollectionPath(Akonadi::Collection::Id id) const;

    mutable QHash<Akonadi::Collection::Id, QString> m_collectionFullPathCache;
};