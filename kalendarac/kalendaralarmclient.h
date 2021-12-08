// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QDateTime>
#include <QTimer>
#include <akonadi_version.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 18, 41)
#include <Akonadi/EntityTreeModel>
#include <Akonadi/ServerManager>
#else
#include <AkonadiCore/EntityTreeModel>
#include <AkonadiCore/ServerManager>
#endif
#include <Akonadi/Calendar/ETMCalendar>

class AlarmNotification;
class NotificationHandler;

class KalendarAlarmClient : public QObject
{
    Q_OBJECT

public:
    explicit KalendarAlarmClient(QObject *parent = nullptr);
    ~KalendarAlarmClient() override;

private:
    void deferredInit();
    void restoreSuspendedFromConfig();
    void storeNotification(AlarmNotification *notification);
    void removeNotification(AlarmNotification *notification);
    void checkAlarms();
    void setupAkonadi();
    Q_REQUIRED_RESULT bool collectionsAvailable() const;
    void saveLastCheckTime();

    Akonadi::ETMCalendar::Ptr mCalendar;
    Akonadi::EntityTreeModel *mETM = nullptr;

    QDateTime mLastChecked;
    QTimer mCheckTimer;
    NotificationHandler *m_notificationHandler;
};
