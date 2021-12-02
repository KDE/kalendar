/*
 * SPDX-FileCopyrightText: 2019 Dimitris Kardarakos <dimkard@posteo.net>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#pragma once

#include <KNotification>
#include <QDateTime>
#include <QPointer>

class NotificationHandler;

/**
 * @brief The alarm notification that should be displayed. It is a wrapper of a KNotification enhanced with alarm properties, like uid and remind time
 *
 */
class AlarmNotification : public QObject
{
    Q_OBJECT
public:
    explicit AlarmNotification(NotificationHandler *handler, const QString &uid);
    ~AlarmNotification() override;

    /**
     * @brief Sends the notification to be displayed
     */
    void send() const;

    /**
     * @return The uid of the Incidence of the alarm of the notification
     */
    QString uid() const;

    /**
     * @brief The text of the notification that should be displayed
     */
    QString text() const;

    /**
     * @brief Sets the to-be-displayed text of the notification
     */
    void setText(const QString &alarmText);

    /**
     * @return In case of a suspended notification, the time that the notification should be displayed. Otherwise, it is empty.
     */
    QDateTime remindAt() const;

    /**
     * @brief Sets the time that should be displayed a suspended notification
     */
    void setRemindAt(const QDateTime &remindAtDt);

Q_SIGNALS:

    /**
     * @brief Signal that should be emitted when the user clicks to the Dismiss action button of the KNotification displayed
     */
    void dismiss();

    /**
     * @brief Signal that should be emitted when the user clicks to the Suspend action button of the KNotification displayed
     */
    void suspend();

private:
    QPointer<KNotification> m_notification;
    QString m_uid;
    QDateTime m_remind_at;
    NotificationHandler *m_notification_handler;
};
