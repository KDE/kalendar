// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "kalendaralarmclient.h"
#include "alarmnotification.h"

#include <akonadi-calendar_version.h>

#include <KCheckableProxyModel>
#include <KConfigGroup>
#include <KLocalizedString>
#include <KSharedConfig>

#include <QDateTime>
#include <QFileInfo>

using namespace KCalendarCore;

KalendarAlarmClient::KalendarAlarmClient(QObject *parent)
    : QObject(parent)
{
    mCheckTimer.setSingleShot(true);
    mCheckTimer.setTimerType(Qt::VeryCoarseTimer);

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
    mLastChecked = alarmGroup.readEntry("CalendarsLastChecked", QDateTime::currentDateTime().addDays(-9));

    restoreSuspendedFromConfig();
}

KalendarAlarmClient::~KalendarAlarmClient() = default;

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
            addNotification(uid, txt, remindAt);
        }
    }
}

void KalendarAlarmClient::dismiss(AlarmNotification *notification)
{
    qDebug() << "Alarm" << notification->uid() << "dismissed";
    removeNotification(notification);
    m_notifications.remove(notification->uid());
    delete notification;
}

void KalendarAlarmClient::suspend(AlarmNotification *notification)
{
    qDebug() << "Alarm " << notification->uid() << "suspended";
    notification->setRemindAt(QDateTime(QDateTime::currentDateTime()).addSecs(5 * 60)); // 5 minutes is hardcoded in the suspend action text
    storeNotification(notification);
}

void KalendarAlarmClient::storeNotification(AlarmNotification *notification)
{
    KConfigGroup suspendedGroup(KSharedConfig::openConfig(), "Suspended");
    KConfigGroup notificationGroup(&suspendedGroup, notification->uid());
    notificationGroup.writeEntry("UID", notification->uid());
    notificationGroup.writeEntry("Text", notification->text());
    notificationGroup.writeEntry("RemindAt", notification->remindAt());
    KSharedConfig::openConfig()->sync();
}

void KalendarAlarmClient::removeNotification(AlarmNotification *notification)
{
    KConfigGroup suspendedGroup(KSharedConfig::openConfig(), "Suspended");
    KConfigGroup notificationGroup(&suspendedGroup, notification->uid());
    notificationGroup.deleteGroup();
    KSharedConfig::openConfig()->sync();
}

void KalendarAlarmClient::addNotification(const QString &uid, const QString &text, const QDateTime &remindTime)
{
    if (m_notifications.contains(uid)) {
        return;
    }
    qDebug() << "Adding notification, uid:" << uid << "text:" << text << "remindTime:" << remindTime;
    AlarmNotification *notification = new AlarmNotification(uid);
    notification->setText(text);
    notification->setRemindAt(remindTime);
    m_notifications[notification->uid()] = notification;
    storeNotification(notification);
}

void KalendarAlarmClient::sendNotifications()
{
    qDebug() << "Looking for notifications, total:" << m_notifications.count();
    for (auto it = m_notifications.begin(); it != m_notifications.end(); ++it) {
        if (it.value()->remindAt() <= QDateTime::currentDateTime()) {
            qDebug() << "Sending notification for alarm" << it.value()->uid() << ", text is" << it.value()->text();
            it.value()->send(this);
        }
    }
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
#if AKONADICALENDAR_VERSION < QT_VERSION_CHECK(5, 19, 41)
        const QString uid = alarm->customProperty("ETMCalendar", "parentUid");
#else
        const QString uid = alarm->parentUid();
#endif
        const KCalendarCore::Incidence::Ptr incidence = mCalendar->incidence(uid);
        QString timeText;

        if (incidence && incidence->type() == KCalendarCore::Incidence::TypeTodo && !incidence->dtStart().isValid()) {
            auto todo = incidence.staticCast<KCalendarCore::Todo>();
            timeText = i18n("Task due at %1", QLocale::system().toString(todo->dtDue().time(), QLocale::NarrowFormat));
            addNotification(uid, QLatin1String("%1\n%2").arg(timeText, incidence->summary()), mLastChecked);
        } else if (incidence) {
            QString incidenceString = incidence->type() == KCalendarCore::Incidence::TypeTodo ? i18n("Task") : i18n("Event");
            timeText = i18nc("Event starts at 10:00",
                             "%1 starts at %2",
                             incidenceString,
                             QLocale::system().toString(incidence->dtStart().time(), QLocale::NarrowFormat));
            addNotification(uid, QLatin1String("%1\n%2").arg(timeText, incidence->summary()), mLastChecked);
        } else {
            QLocale::system().toString(alarm->time(), QLocale::NarrowFormat);
            addNotification(uid, QLatin1String("%1\n%2").arg(timeText, alarm->text()), mLastChecked);
        }
    }

    sendNotifications();
    saveLastCheckTime();

    // schedule next check for the beginning of the next minute
    mCheckTimer.start(std::chrono::seconds(60 - mLastChecked.time().second()));
}

void KalendarAlarmClient::saveLastCheckTime()
{
    KConfigGroup cg(KSharedConfig::openConfig(), "Alarms");
    cg.writeEntry("CalendarsLastChecked", mLastChecked);
    KSharedConfig::openConfig()->sync();
}
