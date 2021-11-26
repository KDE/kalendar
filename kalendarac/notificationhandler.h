/*
 * SPDX-FileCopyrightText: 2019 Dimitris Kardarakos <dimkard@posteo.net>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef NOTIFICATIONHANDLER_H
#define NOTIFICATIONHANDLER_H

#include <QDateTime>
#include <QVariantMap>

struct FilterPeriod {
    QDateTime from;
    QDateTime to;
};

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
     * @brief Creates an alarm notification object for the Incidence with \p uid. It sets the text to be displayed according to \p text. It adds this alarm
     * notification to the internal list of active notifications (the list of notifications that should be sent at the next check).
     */
    void addActiveNotification(const QString &uid, const QString &text);

    /**
     * @brief  Creates an alarm notification object for the Incidence with \p uid. It sets the text to be displayed according to \p text. It adds this alarm
     * notification to the internal list of suspended notifications.
     */
    void addSuspendedNotification(const QString &uid, const QString &text, const QDateTime &remindTime);

    /**
     * @return The time period to check for alarms
     */
    FilterPeriod period() const;

    /**
     * @brief Sets the time period to check for alarms
     */
    void setPeriod(const FilterPeriod &checkPeriod);

    /**
     * @return The list of active notifications. It is the set of notification that should be sent at the next check
     */
    QHash<QString, AlarmNotification *> activeNotifications() const;

    /**
     * @return The list of suspended notifications
     */
    QHash<QString, AlarmNotification *> suspendedNotifications() const;

    /**
     * @brief The date time of the first suspended alarm scheduled. If no suspended notifications exist, an invalid datetime is returned.
     */
    QDateTime firstSuspended() const;

    Q_SIGNAL void scheduleAlarmCheck();

public Q_SLOTS:
    /**
     * @brief Dismisses any further notification display for the alarm \p notification.
     *
     */
    void dismiss(AlarmNotification *const notification);

    /**
     * @brief Suspends the display of the alarm \p notification, by removing it from the list of active and putting it to the list of suspended notifications.
     * Remind time is set according to configuration.
     */
    void suspend(AlarmNotification *const notification);

private:
    void sendActiveNotifications();
    void sendSuspendedNotifications();

    QHash<QString, AlarmNotification *> m_active_notifications;
    QHash<QString, AlarmNotification *> m_suspended_notifications;
    FilterPeriod m_period;
    int m_suspend_seconds;
};
#endif
