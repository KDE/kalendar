// SPDX-FileCopyrightText: 2016 Christian Mollekopf <mollekopf@kolabsys.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once
#include <QObject>
#include <QString>
#include <QStringList>

#include <Akonadi/Item>
#include <QAbstractItemModel>
#include <QModelIndex>

#include <memory>

class MessagePartPrivate;

class MessageParser : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Akonadi::Item item READ item WRITE setItem NOTIFY htmlChanged)
    Q_PROPERTY(QAbstractItemModel *parts READ parts NOTIFY htmlChanged)
    Q_PROPERTY(QAbstractItemModel *attachments READ attachments NOTIFY htmlChanged)
    Q_PROPERTY(QString rawContent READ rawContent NOTIFY htmlChanged)
    Q_PROPERTY(QString structureAsString READ structureAsString NOTIFY htmlChanged)
    Q_PROPERTY(bool loaded READ loaded NOTIFY htmlChanged)

public:
    explicit MessageParser(QObject *parent = Q_NULLPTR);
    ~MessageParser();

    Akonadi::Item item() const;
    void setItem(const Akonadi::Item &item);
    QAbstractItemModel *parts() const;
    QAbstractItemModel *attachments() const;
    QString rawContent() const;
    QString structureAsString() const;
    bool loaded() const;

Q_SIGNALS:
    void htmlChanged();

private:
    std::unique_ptr<MessagePartPrivate> d;
    QString mRawContent;
};
