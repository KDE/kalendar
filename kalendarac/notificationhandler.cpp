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
    , m_active_notifications{QHash<QString, AlarmNotification *>()}
    , m_suspended_notifications{QHash<QString, AlarmNotification *>()}
{
    KConfigGroup generalGroup(KSharedConfig::openConfig(), "General");
    m_suspend_seconds = generalGroup.readEntry("SuspendSeconds", 60 * 5); // 5 minutes
}

NotificationHandler::~NotificationHandler() = default;

void NotificationHandler::addActiveNotification(const QString &uid, const QString &text)
{
    AlarmNotification *notification = new AlarmNotification(this, uid);
    notification->setText(text);
    m_active_notifications[notification->uid()] = notification;
}

void NotificationHandler::addSuspendedNotification(const QString &uid, const QString &txt, const QDateTime &remindTime)
{
    qDebug() << "addSuspendedNotification:\tAdding notification to suspended list, uid:" << uid << "text:" << txt << "remindTime:" << remindTime;
    AlarmNotification *notification = new AlarmNotification(this, uid);
    notification->setText(txt);
    notification->setRemindAt(remindTime);
    m_suspended_notifications[notification->uid()] = notification;
}

void NotificationHandler::sendSuspendedNotifications()
{
    auto suspItr = m_suspended_notifications.begin();
    while (suspItr != m_suspended_notifications.end()) {
        if (suspItr.value()->remindAt() < QDateTime::currentDateTime()) {
            qDebug() << "sendNotifications:\tSending notification for suspended alarm" << suspItr.value()->uid() << ", text is" << suspItr.value()->text();
            suspItr.value()->send();
            suspItr = m_suspended_notifications.erase(suspItr);
        } else {
            suspItr++;
        }
    }
}

void NotificationHandler::sendActiveNotifications()
{
    for (const auto &n : qAsConst(m_active_notifications)) {
        qDebug() << "sendNotifications:\tSending notification for alarm" << n->uid();
        n->send();
    }
}

void NotificationHandler::sendNotifications()
{
    qDebug() << "\nsendNotifications:\tLooking for notifications, total Active:" << m_active_notifications.count()
             << ", total Suspended:" << m_suspended_notifications.count();

    sendSuspendedNotifications();
    sendActiveNotifications();
}

void NotificationHandler::dismiss(AlarmNotification *const notification)
{
    m_active_notifications.remove(notification->uid());

    qDebug() << "\ndismiss:\tAlarm" << notification->uid() << "dismissed";
}

void NotificationHandler::suspend(AlarmNotification *const notification)
{
    AlarmNotification *suspendedNotification = new AlarmNotification(this, notification->uid());
    suspendedNotification->setText(notification->text());
    suspendedNotification->setRemindAt(QDateTime(QDateTime::currentDateTime()).addSecs(m_suspend_seconds));

    m_suspended_notifications[notification->uid()] = suspendedNotification;
    m_active_notifications.remove(notification->uid());

    qDebug() << "\nsuspend\t:Alarm " << notification->uid() << "suspended";
}

QHash<QString, AlarmNotification *> NotificationHandler::activeNotifications() const
{
    return m_active_notifications;
}

QHash<QString, AlarmNotification *> NotificationHandler::suspendedNotifications() const
{
    return m_suspended_notifications;
}
