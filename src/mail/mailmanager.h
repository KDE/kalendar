// SPDX-FileCopyrightText: 2020 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include <QObject>

namespace Akonadi {
    class CollectionFilterProxyModel;
    class EntityMimeTypeFilterModel;
    class Session;
}

class QAbstractListModel;
class QItemSelectionModel;

class MailModel;

/// Class responsible for exposing the email folder selected by the user
class MailManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(Akonadi::CollectionFilterProxyModel *foldersModel READ foldersModel CONSTANT)
    Q_PROPERTY(MailModel *folderModel READ folderModel NOTIFY folderModelChanged)

public:
    MailManager(QObject *parent = nullptr);
    ~MailManager() override = default;

    bool loading() const;
    Akonadi::CollectionFilterProxyModel *foldersModel() const;
    MailModel *folderModel() const;
    Akonadi::Session *session() const;

    Q_INVOKABLE void loadMailCollection(const QModelIndex &index);

Q_SIGNALS:
    void loadingChanged();
    void folderModelChanged();

private:
    bool m_loading;
    Akonadi::Session *m_session;
    Akonadi::CollectionFilterProxyModel *m_foldersModel;

    //folders
    QItemSelectionModel *m_collectionSelectionModel;
    MailModel *m_folderModel;
};

