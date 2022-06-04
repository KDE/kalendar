// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QObject>

class MailModel;

#include <Akonadi/Collection>
#include <MailCommon/SearchPattern>

namespace Akonadi
{
class SearchCreateJob;
class MessageModel;
}

class SearchHelper : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString searchString READ searchString WRITE setSearchString NOTIFY searchStringChanged)
    Q_PROPERTY(QString matches READ matches NOTIFY matchesChanged)
    Q_PROPERTY(MailModel *mailModel READ mailModel NOTIFY mailModelChanged)

public:
    SearchHelper(QObject *parent = nullptr);
    QString searchString() const;
    QString matches() const;
    MailModel *mailModel() const;
    void setSearchString(const QString searchString);

Q_SIGNALS:
    void searchStringChanged();
    void matchesChanged();
    void mailModelChanged();
    void errorOccured(const QString &error);

private:
    QString m_searchString;
    MailModel *m_mailModel = nullptr;
    Akonadi::MessageModel *m_resultModel = nullptr;
    QString m_matches;
    Akonadi::Job *m_searchJob = nullptr;
    Akonadi::SearchQuery m_query;
    QVector<Akonadi::Collection> m_collectionId;
    Akonadi::Collection m_folder;
};
