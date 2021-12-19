/*
 * SPDX-FileCopyrightText: 2019 Dimitris Kardarakos <dimkard@posteo.net>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "alarmnotification.h"
#include "kalendaralarmclient.h"
#include <KLocalizedString>

#include <QDebug>
#include <QDesktopServices>
#include <QRegularExpression>
#include <QUrlQuery>

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

void AlarmNotification::send(KalendarAlarmClient *client, const KCalendarCore::Incidence::Ptr &incidence)
{
    const QDateTime startTime = m_occurrence.isValid() ? m_occurrence : incidence->dtStart();
    const bool notificationExists = m_notification;
    if (!notificationExists) {
        m_notification = new KNotification(QStringLiteral("alarm"));
        m_notification->setFlags(KNotification::Persistent);

        // dismiss both with the explicit action and just closing the notification
        // there is no signal for explicit closing though, we only can observe that
        // indirectly from not having received a different signal before closed()
        QObject::connect(m_notification, &KNotification::closed, client, [this, client]() {
            client->dismiss(this);
        });
        QObject::connect(m_notification, &KNotification::defaultActivated, client, [this, client, startTime]() {
            client->showIncidence(uid(), startTime, m_notification->xdgActivationToken());
        });
        QObject::connect(m_notification, &KNotification::action1Activated, client, [this, client]() {
            client->suspend(this);
            QObject::disconnect(m_notification, &KNotification::closed, client, nullptr);
        });
        QObject::connect(m_notification, &KNotification::action3Activated, client, [this]() {
            QDesktopServices::openUrl(m_contextAction);
        });
    }

    // change the content unconditionally, that will also update already existing notifications
    m_notification->setTitle(incidence->summary());
    m_notification->setText(m_text);
    m_notification->setDefaultAction(i18n("View"));

    if (!m_text.isEmpty() && m_text != incidence->summary()) { // MS Teams sometimes repeats the summary as the alarm text, we don't need that
        m_notification->setText(m_text);
    } else if (incidence->type() == KCalendarCore::Incidence::TypeTodo && !incidence->dtStart().isValid()) {
        const auto todo = incidence.staticCast<KCalendarCore::Todo>();
        m_notification->setText(i18n("Task due at %1", QLocale().toString(todo->dtDue().time(), QLocale::NarrowFormat)));
    } else if (!incidence->allDay()) {
        const QString incidenceType = incidence->type() == KCalendarCore::Incidence::TypeTodo ? i18n("Task") : i18n("Event");
        const int startOffset = qRound(QDateTime::currentDateTime().secsTo(startTime) / 60.0);
        if (startOffset > 0 && startOffset < 60) {
            m_notification->setText(i18ncp("Event starts in 5 minutes", "%2 starts in %1 minute", "%2 starts in %1 minutes", startOffset, incidenceType));
        } else {
            m_notification->setText(
                i18nc("Event starts at 10:00", "%1 starts at %2", incidenceType, QLocale().toString(startTime.time(), QLocale::NarrowFormat)));
        }
    }

    m_notification->setIconName(incidence->type() == KCalendarCore::Incidence::TypeTodo ? QStringLiteral("view-task")
                                                                                        : QStringLiteral("view-calendar-upcoming"));

    QStringList actions = {i18n("Remind in 5 mins"), i18n("Dismiss")};
    const auto contextAction = determineContextAction(incidence);
    if (!contextAction.isEmpty()) {
        actions.push_back(contextAction);
    }
    m_notification->setActions(actions);

    if (!notificationExists) {
        m_notification->sendEvent();
    }
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

QDateTime AlarmNotification::occurrence() const
{
    return m_occurrence;
}

void AlarmNotification::setOccurrence(const QDateTime &occurrence)
{
    m_occurrence = occurrence;
}

QDateTime AlarmNotification::remindAt() const
{
    return m_remind_at;
}

void AlarmNotification::setRemindAt(const QDateTime &remindAtDt)
{
    m_remind_at = remindAtDt;
}

bool AlarmNotification::hasValidContextAction() const
{
    return m_contextAction.isValid() && (m_contextAction.scheme() == QLatin1String("https") || m_contextAction.scheme() == QLatin1String("geo"));
}

QString AlarmNotification::determineContextAction(const KCalendarCore::Incidence::Ptr &incidence)
{
    // look for possible (meeting) URLs
    m_contextAction = incidence->url();
    if (!hasValidContextAction()) {
        m_contextAction = QUrl(incidence->location());
    }
    if (!hasValidContextAction()) {
        m_contextAction = QUrl(incidence->customProperty("MICROSOFT", "SKYPETEAMSMEETINGURL"));
    }
    if (!hasValidContextAction()) {
        static QRegularExpression urlFinder(QStringLiteral(R"(https://[^\s>]*)"));
        const auto match = urlFinder.match(incidence->description());
        if (match.hasMatch()) {
            m_contextAction = QUrl(match.captured());
        }
    }

    if (hasValidContextAction()) {
        return i18n("Open URL");
    }

    // navigate to location
    if (incidence->hasGeo()) {
        m_contextAction.clear();
        m_contextAction.setScheme(QStringLiteral("geo"));
        m_contextAction.setPath(QString::number(incidence->geoLatitude()) + QLatin1Char(',') + QString::number(incidence->geoLongitude()));
    } else if (!incidence->location().isEmpty()) {
        m_contextAction.clear();
        m_contextAction.setScheme(QStringLiteral("geo"));
        m_contextAction.setPath(QStringLiteral("0,0"));
        QUrlQuery query;
        query.addQueryItem(QStringLiteral("q"), incidence->location());
        m_contextAction.setQuery(query);
    }

    if (hasValidContextAction()) {
        return i18n("Map");
    }

    return QString();
}
