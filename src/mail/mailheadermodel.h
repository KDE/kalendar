// SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#pragma once

#include <QAbstractListModel>

class MailHeaderModel : public QAbstractListModel 
{
    Q_OBJECT

public: 
    enum Roles {
        NameRole = Qt::UserRole,
        ValueRole,
    };
    Q_ENUM(Roles)

    enum Header {
        To,
        From,
        BCC,
        CC,
        ReplyTo,
    };
    Q_ENUM(Header);

    explicit MailHeaderModel(QObject *parent = nullptr);
    ~MailHeaderModel() override = default;

    QVariant data(const QModelIndex &index, int role) const override;
    Q_INVOKABLE int rowCount(const QModelIndex &parent = {}) const override;

    Q_INVOKABLE void updateModel(const int row, const QString &value);
    Q_INVOKABLE void updateHeaderType(const int row, const Header headerName);
private:
    struct HeaderItem {
        Header header;
        QString value;
    };

    QList<HeaderItem> m_headers;
};
