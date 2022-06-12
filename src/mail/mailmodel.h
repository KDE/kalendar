// SPDX-FileCopyrightText: 2021 Simon Schmeisser <s.schmeisser@gmx.net>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <Akonadi/Item>
#include <QItemSelectionModel>
#include <QObject>
#include <QSortFilterProxyModel>

#include "messagestatus.h"

class MailModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString searchString READ searchString WRITE setSearchString NOTIFY searchStringChanged)

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
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

    Q_INVOKABLE void updateMessageStatus(int row, MessageStatus messageStatus);
    Q_INVOKABLE MessageStatus copyMessageStatus(MessageStatus messageStatus);

    QString searchString() const;
    void setSearchString(const QString &searchString);

Q_SIGNALS:
    void searchStringChanged();

private:
    Akonadi::Item itemForRow(int row) const;
    QString m_searchString;
};
