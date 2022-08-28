/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <Akonadi/Collection>
#include <Akonadi/Item>
#include <KJob>
#include <QDate>
#include <QObject>

#include <memory>
#include <qdatetime.h>
#include <qobjectdefs.h>

class FollowupReminderCreateJobPrivate;
/**
 * @brief The FollowupReminderCreateJob class
 * @author Laurent Montel <montel@kde.org>
 */
class FollowupReminderCreateJob : public KJob
{
    Q_OBJECT
    Q_PROPERTY(QDate followUpReminderDate READ followUpReminderDate WRITE setFollowUpReminderDate NOTIFY followUpReminderDateChanged)
    Q_PROPERTY(Akonadi::Item::Id originalMessageItemId READ originalMessageItemId WRITE setOriginalMessageItemId NOTIFY originalMessageItemIdChanged)

public:
    explicit FollowupReminderCreateJob(QObject *parent = nullptr);
    ~FollowupReminderCreateJob() override;

    QDate followUpReminderDate() const;
    void setFollowUpReminderDate(const QDate &date);

    Akonadi::Item::Id originalMessageItemId() const;
    void setOriginalMessageItemId(Akonadi::Item::Id value);

    QString messageId() const;
    void setMessageId(const QString &messageId);

    QString to() const;
    void setTo(const QString &to);

    QString subject() const;
    void setSubject(const QString &subject);

    Akonadi::Collection collectionToDo() const;
    void setCollectionToDo(const Akonadi::Collection &collection);

    Q_INVOKABLE void start() override;

Q_SIGNALS:
    void collectionToDoChanged();
    void subjectChanged();
    void toChanged();
    void messageIdChanged();
    void originalMessageItemIdChanged();
    void followUpReminderDateChanged();

private Q_SLOTS:
    void slotCreateNewTodo(KJob *job);

private:
    void writeFollowupReminderInfo();

    std::unique_ptr<FollowupReminderCreateJobPrivate> const d;
};
