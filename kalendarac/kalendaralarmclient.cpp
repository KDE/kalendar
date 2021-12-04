// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "kalendaralarmclient.h"
#include "alarmdockwindow.h"
#include "alarmnotification.h"
#include "kalendaracadaptor.h"
#include "notificationhandler.h"

#include <CalendarSupport/Utils>

#include <KCheckableProxyModel>
#include <KConfigGroup>
#include <KLocalizedString>
#include <KSharedConfig>

#include <QApplication>
#include <QDBusConnection>
#include <QDateTime>

using namespace KCalendarCore;

KalendarAlarmClient::KalendarAlarmClient(QObject *parent)
    : QObject(parent)
{
    new KalendaracAdaptor(this);
    QDBusConnection::sessionBus().registerObject(QStringLiteral("/ac"), this);

    m_notificationHandler = new NotificationHandler(this);

    if (dockerEnabled()) {
        mDocker = new AlarmDockWindow;
        connect(this, &KalendarAlarmClient::reminderCount, mDocker, &AlarmDockWindow::slotUpdate);
        connect(mDocker, &AlarmDockWindow::quitSignal, this, &KalendarAlarmClient::slotQuit);
    }

    // Check if Akonadi is already configured
    const QString akonadiConfigFile = Akonadi::ServerManager::serverConfigFilePath(Akonadi::ServerManager::ReadWrite);
    if (QFileInfo::exists(akonadiConfigFile)) {
        // Akonadi is configured, create ETM and friends, which will start Akonadi
        // if its not running yet
        setupAkonadi();
    } else {
        // Akonadi has not been set up yet, wait for someone else to start it,
        // so that we don't unnecessarily slow session start up
        connect(Akonadi::ServerManager::self(), &Akonadi::ServerManager::stateChanged, this, [this](Akonadi::ServerManager::State state) {
            if (state == Akonadi::ServerManager::Running) {
                setupAkonadi();
            }
        });
    }

    KConfigGroup alarmGroup(KSharedConfig::openConfig(), "Alarms");
    const int interval = alarmGroup.readEntry("Interval", 60);
    qDebug() << "KalendarAlarmClient check interval:" << interval << "seconds.";
    mLastChecked = alarmGroup.readEntry("CalendarsLastChecked", QDateTime::currentDateTime().addDays(-9));

    mCheckTimer.start(1000 * interval); // interval in seconds
    connect(qApp, &QApplication::commitDataRequest, this, &KalendarAlarmClient::slotCommitData);

    restoreSuspendedFromConfig();
}

KalendarAlarmClient::~KalendarAlarmClient()
{
    delete mDocker;
}

void KalendarAlarmClient::setupAkonadi()
{
    const QStringList mimeTypes{Event::eventMimeType(), Todo::todoMimeType()};
    mCalendar = Akonadi::ETMCalendar::Ptr(new Akonadi::ETMCalendar(mimeTypes));
    mCalendar->setObjectName(QStringLiteral("KalendarAC's calendar"));
    mETM = mCalendar->entityTreeModel();

    connect(&mCheckTimer, &QTimer::timeout, this, &KalendarAlarmClient::checkAlarms);
    connect(mETM, &Akonadi::EntityTreeModel::collectionPopulated, this, &KalendarAlarmClient::deferredInit);
    connect(mETM, &Akonadi::EntityTreeModel::collectionTreeFetched, this, &KalendarAlarmClient::deferredInit);

    checkAlarms();
}

void checkAllItems(KCheckableProxyModel *model, const QModelIndex &parent = QModelIndex())
{
    const int rowCount = model->rowCount(parent);
    for (int row = 0; row < rowCount; ++row) {
        QModelIndex index = model->index(row, 0, parent);
        model->setData(index, Qt::Checked, Qt::CheckStateRole);

        if (model->rowCount(index) > 0) {
            checkAllItems(model, index);
        }
    }
}

void KalendarAlarmClient::deferredInit()
{
    if (!collectionsAvailable()) {
        return;
    }

    qDebug() << "Performing delayed initialization.";

    KCheckableProxyModel *checkableModel = mCalendar->checkableProxyModel();
    checkAllItems(checkableModel);

    // Now that everything is set up, a first check for reminders can be performed.
    checkAlarms();
}

void KalendarAlarmClient::restoreSuspendedFromConfig()
{
    qDebug() << "\nrestoreSuspendedFromConfig: Restore suspended alarms from config";
    KConfigGroup suspendedGroup(KSharedConfig::openConfig(), "Suspended");
    const auto suspendedAlarms = suspendedGroup.groupList();

    for (const auto &s : suspendedAlarms) {
        KConfigGroup suspendedAlarm(&suspendedGroup, s);
        QString uid = suspendedAlarm.readEntry("UID");
        QString txt = suspendedAlarm.readEntry("Text");
        QDateTime remindAt = suspendedAlarm.readEntry("RemindAt", QDateTime());
        qDebug() << "restoreSuspendedFromConfig: Restoring alarm" << uid << "," << txt << "," << remindAt;

        if (!uid.isEmpty() && remindAt.isValid() && !txt.isEmpty()) {
            m_notificationHandler->addNotification(uid, txt, remindAt);
        }
    }
}

void KalendarAlarmClient::flushSuspendedToConfig()
{
    KConfigGroup suspendedGroup(KSharedConfig::openConfig(), "Suspended");
    suspendedGroup.deleteGroup();

    const auto notifications = m_notificationHandler->activeNotifications();

    if (notifications.isEmpty()) {
        qDebug() << "flushSuspendedToConfig: No pending notification exists, nothing to write to config";
        KSharedConfig::openConfig()->sync();

        return;
    }

    for (const auto &s : notifications) {
        qDebug() << "flushSuspendedToConfig: Flushing alarm" << s->uid() << s->remindAt() << " to config";
        KConfigGroup notificationGroup(&suspendedGroup, s->uid());
        notificationGroup.writeEntry("UID", s->uid());
        notificationGroup.writeEntry("Text", s->text());
        notificationGroup.writeEntry("RemindAt", s->remindAt());
    }
    KSharedConfig::openConfig()->sync();
}

bool KalendarAlarmClient::dockerEnabled()
{
    KConfig kalendarConfig(QStandardPaths::locate(QStandardPaths::ConfigLocation, QStringLiteral("kalendarrc")));
    KConfigGroup generalGroup(&kalendarConfig, "System Tray");
    return generalGroup.readEntry("ShowReminderDaemon", true);
}

bool KalendarAlarmClient::collectionsAvailable() const
{
    // The list of collections must be available.
    if (!mETM->isCollectionTreeFetched()) {
        return false;
    }

    // All collections must be populated.
    const int rowCount = mETM->rowCount();
    for (int row = 0; row < rowCount; ++row) {
        static const int column = 0;
        const QModelIndex index = mETM->index(row, column);
        const bool haveData = mETM->data(index, Akonadi::EntityTreeModel::IsPopulatedRole).toBool();
        if (!haveData) {
            return false;
        }
    }

    return true;
}

void KalendarAlarmClient::checkAlarms()
{
    KConfigGroup cfg(KSharedConfig::openConfig(), "General");

    if (!cfg.readEntry("Enabled", true)) {
        return;
    }

    // We do not want to miss any reminders, so don't perform check unless
    // the collections are available and populated.
    if (!collectionsAvailable()) {
        qDebug() << "Collections are not available; aborting check.";
        return;
    }

    const QDateTime from = mLastChecked.addSecs(1);
    mLastChecked = QDateTime::currentDateTime();

    qDebug() << "Check:" << from.toString() << " -" << mLastChecked.toString();

    const Alarm::List alarms = mCalendar->alarms(from, mLastChecked, true /* exclude blocked alarms */);
    for (const Alarm::Ptr &alarm : alarms) {
        const QString uid = alarm->customProperty("ETMCalendar", "parentUid");
        const KCalendarCore::Incidence::Ptr incidence = mCalendar->incidence(uid);
        QString timeText;

        if (incidence && incidence->type() == KCalendarCore::Incidence::TypeTodo && !incidence->dtStart().isValid()) {
            auto todo = incidence.staticCast<KCalendarCore::Todo>();
            timeText = i18n("Task due at %1", QLocale::system().toString(todo->dtDue().time(), QLocale::NarrowFormat));
            m_notificationHandler->addNotification(uid, QLatin1String("%1\n%2").arg(timeText, incidence->summary()), mLastChecked);
        } else if (incidence) {
            QString incidenceString = incidence->type() == KCalendarCore::Incidence::TypeTodo ? i18n("Task") : i18n("Event");
            timeText = i18nc("Event starts at 10:00",
                             "%1 starts at %2",
                             incidenceString,
                             QLocale::system().toString(incidence->dtStart().time(), QLocale::NarrowFormat));
            m_notificationHandler->addNotification(uid, QLatin1String("%1\n%2").arg(timeText, incidence->summary()), mLastChecked);
        } else {
            QLocale::system().toString(alarm->time(), QLocale::NarrowFormat);
            m_notificationHandler->addNotification(uid, QLatin1String("%1\n%2").arg(timeText, alarm->text()), mLastChecked);
        }
    }

    m_notificationHandler->sendNotifications();
    saveLastCheckTime();
    flushSuspendedToConfig();
}

void KalendarAlarmClient::slotQuit()
{
    Q_EMIT saveAllSignal();
    flushSuspendedToConfig();
    saveLastCheckTime();
    quit();
}

void KalendarAlarmClient::saveLastCheckTime()
{
    KConfigGroup cg(KSharedConfig::openConfig(), "Alarms");
    cg.writeEntry("CalendarsLastChecked", mLastChecked);
    KSharedConfig::openConfig()->sync();
}

void KalendarAlarmClient::quit()
{
    // qCDebug(KOALARMCLIENT_LOG);
    qApp->quit();
}

void KalendarAlarmClient::slotCommitData(QSessionManager &)
{
    Q_EMIT saveAllSignal();
    saveLastCheckTime();
}

void KalendarAlarmClient::forceAlarmCheck()
{
    checkAlarms();
    saveLastCheckTime();
}

QString KalendarAlarmClient::dumpDebug() const
{
    KConfigGroup cfg(KSharedConfig::openConfig(), "Alarms");
    const QDateTime lastChecked = cfg.readEntry("CalendarsLastChecked", QDateTime());
    const QString str = QStringLiteral("Last Check: %1").arg(lastChecked.toString());
    return str;
}

QStringList KalendarAlarmClient::dumpAlarms() const
{
    const QDateTime start = QDateTime(QDate::currentDate(), QTime(0, 0), Qt::LocalTime);
    const QDateTime end = start.addDays(1).addSecs(-1);

    QStringList lst;
    const Alarm::List alarms = mCalendar->alarms(start, end);
    lst.reserve(1 + (alarms.isEmpty() ? 1 : alarms.count()));
    // Don't translate, this is for debugging purposes.
    lst << QStringLiteral("dumpAlarms() from ") + start.toString() + QLatin1String(" to ") + end.toString();

    if (alarms.isEmpty()) {
        lst << QStringLiteral("No alarm found.");
    } else {
        for (const Alarm::Ptr &alarm : alarms) {
            const QString uid = alarm->customProperty("ETMCalendar", "parentUid");
            const Akonadi::Item::Id id = mCalendar->item(uid).id();
            const Akonadi::Item item = mCalendar->item(id);

            const Incidence::Ptr incidence = CalendarSupport::incidence(item);
            const QString summary = incidence->summary();

            const QDateTime time = incidence->dateTime(Incidence::RoleAlarm);
            lst << QStringLiteral("%1: \"%2\" (alarm text \"%3\")").arg(time.toString(Qt::ISODate), summary, alarm->text());
        }
    }

    return lst;
}

void KalendarAlarmClient::hide()
{
    delete mDocker;
    mDocker = nullptr;
}

void KalendarAlarmClient::show()
{
    if (!mDocker) {
        if (dockerEnabled()) {
            mDocker = new AlarmDockWindow;
            connect(this, &KalendarAlarmClient::reminderCount, mDocker, &AlarmDockWindow::slotUpdate);
            connect(mDocker, &AlarmDockWindow::quitSignal, this, &KalendarAlarmClient::slotQuit);
        }
    }
}
