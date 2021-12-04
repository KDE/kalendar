/*
 * SPDX-FileCopyrightText: 2019 Dimitris Kardarakos <dimkard@posteo.net>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef NOTIFICATIONHANDLER_H
#define NOTIFICATIONHANDLER_H

#include <QDateTime>
#include <QHash>
#include <QObject>

class AlarmNotification;
/**
 * @brief Manages the creation and triggering of event alarm notifications
 *
 */
class NotificationHandler : public QObject
{
    Q_OBJECT
public:
    explicit NotificationHandler(QObject *parent);
    ~NotificationHandler() override;

    /**
     * @brief Parses the internal list of active and suspended notifications and triggers their sending
     */
    void sendNotifications();

    /**
     * @brief  Creates an alarm notification object for the Incidence with \p uid. It sets the text to be displayed according to \p text.
     */
    void addNotification(const QString &uid, const QString &text, const QDateTime &remindTime);

    /**
     * @return The list of active notifications. It is the set of notification that should be sent at the next check
     */
    QHash<QString, AlarmNotification *> activeNotifications() const;

public Q_SLOTS:
    /**
     * @brief Dismisses any further notification display for the alarm \p notification.
     *
     */
    void dismiss(AlarmNotification *notification);

    /**
     * @brief Suspends the display of the alarm \p notification, by removing it from the list of active and putting it to the list of suspended notifications.
     * Remind time is set according to configuration.
     */
    void suspend(AlarmNotification *notification);

private:
    QHash<QString, AlarmNotification *> m_notifications;
    int m_suspend_seconds;
};
#endif
