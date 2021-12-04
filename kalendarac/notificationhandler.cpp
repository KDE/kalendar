/*
 * SPDX-FileCopyrightText: 2020 Dimitris Kardarakos <dimkard@posteo.net>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "notificationhandler.h"
#include "alarmnotification.h"
#include <KConfigGroup>
#include <KLocalizedString>
#include <KSharedConfig>
#include <QDebug>

NotificationHandler::NotificationHandler(QObject *parent)
    : QObject(parent)
{
    KConfigGroup generalGroup(KSharedConfig::openConfig(), "General");
    m_suspend_seconds = generalGroup.readEntry("SuspendSeconds", 60 * 5); // 5 minutes
}

NotificationHandler::~NotificationHandler() = default;

void NotificationHandler::addNotification(const QString &uid, const QString &txt, const QDateTime &remindTime)
{
    if (m_notifications.contains(uid)) {
        return;
    }
    qDebug() << "Adding notification, uid:" << uid << "text:" << txt << "remindTime:" << remindTime;
    AlarmNotification *notification = new AlarmNotification(uid);
    notification->setText(txt);
    notification->setRemindAt(remindTime);
    m_notifications[notification->uid()] = notification;
}

void NotificationHandler::sendNotifications()
{
    qDebug() << "Looking for notifications, total:" << m_notifications.count();

    for (auto it = m_notifications.begin(); it != m_notifications.end(); ++it) {
        if (it.value()->remindAt() <= QDateTime::currentDateTime()) {
            qDebug() << "Sending notification for alarm" << it.value()->uid() << ", text is" << it.value()->text();
            it.value()->send(this);
        }
    }
}

void NotificationHandler::dismiss(AlarmNotification *notification)
{
    qDebug() << "Alarm" << notification->uid() << "dismissed";
    m_notifications.remove(notification->uid());
    delete notification;
}

void NotificationHandler::suspend(AlarmNotification *notification)
{
    qDebug() << ":Alarm " << notification->uid() << "suspended";
    notification->setRemindAt(QDateTime(QDateTime::currentDateTime()).addSecs(m_suspend_seconds));
}

QHash<QString, AlarmNotification *> NotificationHandler::activeNotifications() const
{
    return m_notifications;
}
