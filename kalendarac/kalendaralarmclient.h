// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QDateTime>
#include <QHash>
#include <QTimer>

#include <akonadi_version.h>
#include <Akonadi/EntityTreeModel>
#include <Akonadi/ServerManager>
#include <Akonadi/Calendar/ETMCalendar>

class AlarmNotification;

class KalendarAlarmClient : public QObject
{
    Q_OBJECT

public:
    explicit KalendarAlarmClient(QObject *parent = nullptr);
    ~KalendarAlarmClient() override;

    /** Dismisses any further notification display for the alarm \p notification. */
    void dismiss(AlarmNotification *notification);
    /** Suspends the display of the alarm \p notification. */
    void suspend(AlarmNotification *notification);

private:
    void deferredInit();
    void restoreSuspendedFromConfig();
    void storeNotification(AlarmNotification *notification);
    void removeNotification(AlarmNotification *notification);
    void addNotification(const QString &uid, const QString &text, const QDateTime &occurrence, const QDateTime &remindTime);
    void checkAlarms();
    void setupAkonadi();
    Q_REQUIRED_RESULT bool collectionsAvailable() const;
    void saveLastCheckTime();
    QDateTime occurrenceForAlarm(const KCalendarCore::Incidence::Ptr &incidence, const KCalendarCore::Alarm::Ptr &alarm, const QDateTime &from) const;

    Akonadi::ETMCalendar::Ptr mCalendar;
    Akonadi::EntityTreeModel *mETM = nullptr;

    QDateTime mLastChecked;
    QTimer mCheckTimer;
    QHash<QString, AlarmNotification *> m_notifications;
};
