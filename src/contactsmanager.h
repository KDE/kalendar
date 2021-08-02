// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>
#include <QSortFilterProxyModel>
#include <Akonadi/Contact/ContactsTreeModel>
#include <Akonadi/Contact/ContactsFilterProxyModel>
#include <AkonadiCore/EntityMimeTypeFilterModel>
#include <KItemModels/KDescendantsProxyModel>

class QSortFilterProxyModel;

class ContactsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QSortFilterProxyModel * contactsModel READ contactsModel CONSTANT)

public:
    ContactsManager(QObject *parent = nullptr);
    ~ContactsManager() = default;

    QSortFilterProxyModel *contactsModel();
    Q_INVOKABLE void contactEmails(qint64 itemId);
    Q_INVOKABLE QUrl decorationToUrl(QVariant decoration);

Q_SIGNALS:
    void emailsFetched(QStringList emails, qint64 itemId);

private:
    QSortFilterProxyModel *m_model = nullptr;
};
