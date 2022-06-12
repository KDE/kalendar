// SPDX-FileCopyrightText: 2021 Simon Schmeisser <s.schmeisser@gmx.net>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <Akonadi/Item>
#include <QIdentityProxyModel>
#include <QItemSelectionModel>
#include <QObject>

#include "messagestatus.h"

class MailModel : public QIdentityProxyModel
{
    Q_OBJECT

public:
    enum ExtraRole {
        TitleRole = Qt::UserRole + 1,
        SenderRole,
        FromRole,
        ToRole,
        TextColorRole,
        DateRole,
        DateTimeRole,
        BackgroundColorRole,
        StatusRole,
        FavoriteRole,
        ItemRole,
    };

    explicit MailModel(QObject *parent = nullptr);
    QHash<int, QByteArray> roleNames() const override;
    virtual QVariant data(const QModelIndex &index, int role) const override;

    Q_INVOKABLE void updateMessageStatus(int row, MessageStatus messageStatus);
    Q_INVOKABLE MessageStatus copyMessageStatus(MessageStatus messageStatus);

private:
    Akonadi::Item itemForRow(int row) const;
};
