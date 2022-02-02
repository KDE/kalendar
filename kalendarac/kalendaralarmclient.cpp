// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "kalendaralarmclient.h"
#include "alarmnotification.h"
#include "calendarinterface.h"

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
        QDateTime occurrence = suspendedAlarm.readEntry("Occurrence", QDateTime());
        QDateTime remindAt = suspendedAlarm.readEntry("RemindAt", QDateTime());
        qDebug() << "restoreSuspendedFromConfig: Restoring alarm" << uid << "," << txt << "," << remindAt;

        if (!uid.isEmpty() && remindAt.isValid()) {
            addNotification(uid, txt, occurrence, remindAt);
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

void KalendarAlarmClient::showIncidence(const QString &uid, const QDateTime &occurrence, const QString &xdgActivationToken)
{
    KConfig cfg(QStringLiteral("defaultcalendarrc"));
    KConfigGroup grp(&cfg, QStringLiteral("General"));
    const auto appId = grp.readEntry(QStringLiteral("ApplicationId"), QString());
    if (appId.isEmpty()) {
        return;
    }

    // start the calendar application if it isn't running yet
    QDBusConnection::sessionBus().interface()->startService(appId);

    // if running inside Kontact, select the right plugin
    if (appId == QLatin1String("org.kde.kontact")) {
        const auto kontactPlugin = grp.readEntry(QStringLiteral("KontactPlugin"), QStringLiteral("korganizer"));
        const QString objectName = QLatin1Char('/') + kontactPlugin + QLatin1String("_PimApplication");
        QDBusInterface iface(appId, objectName, QStringLiteral("org.kde.PIMUniqueApplication"), QDBusConnection::sessionBus());
        if (iface.isValid()) {
            QStringList arguments({kontactPlugin});
            iface.call(QStringLiteral("newInstance"), QByteArray(), arguments, QString());
        }
    }

    // select the right incidence/occurrence
    org::kde::calendar::Calendar iface(appId, QStringLiteral("/Calendar"), QDBusConnection::sessionBus());
    iface.showIncidenceByUid(uid, occurrence, xdgActivationToken);
}

void KalendarAlarmClient::storeNotification(AlarmNotification *notification)
{
    KConfigGroup suspendedGroup(KSharedConfig::openConfig(), "Suspended");
    KConfigGroup notificationGroup(&suspendedGroup, notification->uid());
    notificationGroup.writeEntry("UID", notification->uid());
    notificationGroup.writeEntry("Text", notification->text());
    notificationGroup.writeEntry("Occurrence", notification->occurrence());
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

void KalendarAlarmClient::addNotification(const QString &uid, const QString &text, const QDateTime &occurrence, const QDateTime &remindTime)
{
    AlarmNotification *notification = nullptr;
    const auto it = m_notifications.constFind(uid);
    if (it != m_notifications.constEnd()) {
        notification = it.value();
    } else {
        notification = new AlarmNotification(uid);
    }

    if (notification->remindAt().isValid() && notification->remindAt() < remindTime) {
        // we have a notification for this event already, and it's scheduled earlier than the new one
        return;
    }

    // we either have no notification for this event yet, or one that is scheduled for later and that should be replaced
    qDebug() << "Adding notification, uid:" << uid << "text:" << text << "remindTime:" << remindTime;
    notification->setText(text);
    notification->setOccurrence(occurrence);
    notification->setRemindAt(remindTime);
    m_notifications[notification->uid()] = notification;
    storeNotification(notification);
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

    // look for new alarms
    const Alarm::List alarms = mCalendar->alarms(from, mLastChecked, true /* exclude blocked alarms */);
    for (const Alarm::Ptr &alarm : alarms) {
#if AKONADICALENDAR_VERSION < QT_VERSION_CHECK(5, 19, 41)
        const QString uid = alarm->customProperty("ETMCalendar", "parentUid");
#else
        const QString uid = alarm->parentUid();
#endif
        const auto incidence = mCalendar->incidence(uid);
        const auto occurrence = occurrenceForAlarm(incidence, alarm, from);
        addNotification(uid, alarm->text(), occurrence, mLastChecked);
    }

    // execute or update active alarms
    for (auto it = m_notifications.begin(); it != m_notifications.end(); ++it) {
        if (it.value()->remindAt() <= mLastChecked) {
            const auto incidence = mCalendar->incidence(it.value()->uid());
            if (incidence) { // can still be null when we get here during the early stages of loading/restoring
                it.value()->send(this, incidence);
            }
        }
    }

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

// based on KCalendarCore::Calendar::appendRecurringAlarms()
QDateTime
KalendarAlarmClient::occurrenceForAlarm(const KCalendarCore::Incidence::Ptr &incidence, const KCalendarCore::Alarm::Ptr &alarm, const QDateTime &from) const
{
    if (!incidence->recurs()) {
        return {};
    }

    // recurring alarms not handled here for simplicity
    if (alarm->repeatCount()) {
        return {};
    }

    // Alarm time is defined by an offset from the event start or end time.
    // Find the offset from the event start time, which is also used as the
    // offset from the recurrence time.
    Duration offset(0), endOffset(0);
    if (alarm->hasStartOffset()) {
        offset = alarm->startOffset();
    } else if (alarm->hasEndOffset()) {
        offset = alarm->endOffset();
        endOffset = Duration(incidence->dtStart(), incidence->dateTime(Incidence::RoleAlarmEndOffset));
    } else {
        // alarms at a fixed time, not handled here for simplicity
        return {};
    }

    // Find the incidence's earliest alarm
    QDateTime alarmStart = offset.end(alarm->hasEndOffset() ? incidence->dateTime(Incidence::RoleAlarmEndOffset) : incidence->dtStart());
    QDateTime baseStart = incidence->dtStart();
    if (from > alarmStart) {
        alarmStart = from; // don't look earlier than the earliest alarm
        baseStart = (-offset).end((-endOffset).end(alarmStart));
    }

    // Find the next occurrence from the earliest possible alarm time
    return incidence->recurrence()->getNextDateTime(baseStart.addSecs(-1));
}
