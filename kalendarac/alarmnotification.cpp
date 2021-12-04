/*
 * SPDX-FileCopyrightText: 2019 Dimitris Kardarakos <dimkard@posteo.net>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "alarmnotification.h"
#include "notificationhandler.h"
#include <KLocalizedString>
#include <QDebug>

AlarmNotification::AlarmNotification(const QString &uid)
    : m_uid{uid}
    , m_remind_at{QDateTime()}
{
}

AlarmNotification::~AlarmNotification()
{
    // don't delete immediately, in case we end up here as a result
    // of a signal from m_notification itself
    m_notification->deleteLater();
}

void AlarmNotification::send(NotificationHandler *handler)
{
    if (m_notification) {
        return; // already active
    }

    m_notification = new KNotification(QStringLiteral("alarm"));
    m_notification->setText(m_text);
    m_notification->setActions({i18n("Remind in 5 mins"), i18n("Dismiss")});

    // dismiss both with the explicit action and just closing the notification
    // there is no signal for explicit closing though, we only can observe that
    // indirectly from not having received a different signal before closed()
    QObject::connect(m_notification, &KNotification::closed, handler, [this, handler]() {
        handler->dismiss(this);
    });
    QObject::connect(m_notification, &KNotification::action1Activated, handler, [this, handler]() {
        handler->suspend(this);
        QObject::disconnect(m_notification, &KNotification::closed, handler, nullptr);
    });

    m_notification->sendEvent();
}

QString AlarmNotification::uid() const
{
    return m_uid;
}

QString AlarmNotification::text() const
{
    return m_text;
}

void AlarmNotification::setText(const QString &alarmText)
{
    m_text = alarmText;
}

QDateTime AlarmNotification::remindAt() const
{
    return m_remind_at;
}

void AlarmNotification::setRemindAt(const QDateTime &remindAtDt)
{
    m_remind_at = remindAtDt;
}
