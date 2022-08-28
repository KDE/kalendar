// SPDX-FileCopyrightText: 2020 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QAbstractItemModel>
#include <QItemSelectionModel>
#include <QObject>
#include <qabstractitemmodel.h>

namespace Akonadi
{
class CollectionFilterProxyModel;
class Collection;
class Item;
class Session;
}

class QItemSelectionModel;

class MailModel;

/// Class responsible for exposing the email folder selected by the user
class MailManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)

    /// This property holds the hierachy of mail folders
    Q_PROPERTY(Akonadi::CollectionFilterProxyModel *foldersModel READ foldersModel CONSTANT)

    // This property holds the list of email in a folder
    Q_PROPERTY(MailModel *folderModel READ folderModel NOTIFY folderModelChanged)

    Q_PROPERTY(QString selectedFolderName READ selectedFolderName NOTIFY selectedFolderNameChanged)

public:
    MailManager(QObject *parent = nullptr);
    ~MailManager() override = default;

    bool loading() const;
    Akonadi::CollectionFilterProxyModel *foldersModel() const;
    MailModel *folderModel() const;
    Akonadi::Session *session() const;
    QString selectedFolderName() const;
    void setSelectedFolderName(const QString &folderName);

    /// Load a mail collection by its index in the folderModel
    Q_INVOKABLE void loadMailCollectionByIndex(const QModelIndex &index);

    /// Load a mail collection by its collection
    Q_INVOKABLE void loadMailCollection(const Akonadi::Collection &collection);

    /// Show an email
    Q_INVOKABLE bool showMail(qint64 serialNumber);

Q_SIGNALS:
    void loadingChanged();
    void folderModelChanged();
    void selectedFolderNameChanged();
    void showMailInViewer(const Akonadi::Item &item);

private Q_SLOTS:
    void computeFolderName(const QItemSelection &selected, const QItemSelection &deselected);

private:
    bool m_loading;
    Akonadi::Session *m_session;
    Akonadi::CollectionFilterProxyModel *m_foldersModel;

    // folders
    QItemSelectionModel *m_collectionSelectionModel;
    MailModel *m_folderModel;
    QString m_selectedFolderName;
};
