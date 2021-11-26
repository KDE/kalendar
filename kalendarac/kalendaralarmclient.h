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
#include <QSessionManager>

class AlarmDockWindow;
class NotificationHandler;

class KalendarAlarmClient : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.kalendarac")

public:
    explicit KalendarAlarmClient(QObject *parent = nullptr);
    ~KalendarAlarmClient() override;

    // DBUS interface
    void quit();
    void hide();
    void show();
    void forceAlarmCheck();
    Q_REQUIRED_RESULT QString dumpDebug() const;
    Q_REQUIRED_RESULT QStringList dumpAlarms() const;

public Q_SLOTS:
    void slotQuit();

Q_SIGNALS:
    void reminderCount(int);
    void saveAllSignal();

private:
    void deferredInit();
    void restoreSuspendedFromConfig();
    void flushSuspendedToConfig();
    void checkAlarms();
    void setupAkonadi();
    void slotCommitData(QSessionManager &);
    Q_REQUIRED_RESULT bool dockerEnabled();
    Q_REQUIRED_RESULT bool collectionsAvailable() const;
    void saveLastCheckTime();

    AlarmDockWindow *mDocker = nullptr; // the panel icon
    Akonadi::ETMCalendar::Ptr mCalendar;
    Akonadi::EntityTreeModel *mETM = nullptr;

    QDateTime mLastChecked;
    QTimer mCheckTimer;
    NotificationHandler *m_notificationHandler;
};
