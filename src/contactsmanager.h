// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once
#include <QObject>
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
#include <akonadi_version.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 19, 40)
#include <Akonadi/ContactsFilterProxyModel>
#include <Akonadi/ContactsTreeModel>
#else
#include <Akonadi/Contact/ContactsFilterProxyModel>
#include <Akonadi/Contact/ContactsTreeModel>
#endif
#else
#include <Akonadi/ContactsFilterProxyModel>
#include <Akonadi/ContactsTreeModel>
#endif
#include <QObject>
#include <QSortFilterProxyModel>
#include <Akonadi/EntityMimeTypeFilterModel>

class QSortFilterProxyModel;

class ContactsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QSortFilterProxyModel *contactsModel READ contactsModel CONSTANT)

public:
    ContactsManager(QObject *parent = nullptr);
    ~ContactsManager() override = default;

    QSortFilterProxyModel *contactsModel();
    Q_INVOKABLE void contactEmails(qint64 itemId);
    Q_INVOKABLE QUrl decorationToUrl(QVariant decoration);

Q_SIGNALS:
    void emailsFetched(QStringList emails, qint64 itemId);

private:
    QSortFilterProxyModel *m_model = nullptr;
};
