// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QMetaEnum>
#include <eventwrapper.h>

EventWrapper::EventWrapper(QObject *parent)
    : QObject(parent)
    , m_event(new KCalendarCore::Event)
    , m_remindersModel(parent, m_event)
    , m_attendeesModel(parent, m_event)
{
    for(int i = 0; i < QMetaEnum::fromType<EventWrapper::RecurrenceIntervals>().keyCount(); i++) {
        int value = QMetaEnum::fromType<EventWrapper::RecurrenceIntervals>().value(i);
        QString key = QLatin1String(QMetaEnum::fromType<EventWrapper::RecurrenceIntervals>().key(i));
        m_recurrenceIntervals[key] = value;
    }

    // Change event pointer in remindersmodel if changed here
    connect(this, SIGNAL(eventPtrChanged(KCalendarCore::Event::Ptr)),
            &m_remindersModel, SLOT(setEventPtr(KCalendarCore::Event::Ptr)));
}

KCalendarCore::Event::Ptr EventWrapper::eventPtr() const
{
    return m_event;
}

void EventWrapper::setEventPtr(KCalendarCore::Event::Ptr eventPtr)
{
    m_event = eventPtr;
}

QString EventWrapper::summary() const
{
    return m_event->summary();
}

void EventWrapper::setSummary(QString summary)
{
    m_event->setSummary(summary);
}

QString EventWrapper::description() const
{
    return m_event->description();
}

void EventWrapper::setDescription(QString description)
{
    if (m_event->description() == description) {
         return;
    }
    m_event->setDescription(description);
    Q_EMIT descriptionChanged();
}

QString EventWrapper::location() const
{
    return m_event->location();
}

void EventWrapper::setLocation(QString location)
{
    m_event->setLocation(location);
}


QDateTime EventWrapper::eventStart() const
{
    return m_event->dtStart();
}

void EventWrapper::setEventStart(QDateTime eventStart)
{
    m_event->setDtStart(eventStart);
}

QDateTime EventWrapper::eventEnd() const
{
    return m_event->dtEnd();
}

void EventWrapper::setEventEnd(QDateTime eventEnd)
{
    m_event->setDtStart(eventEnd);
}

KCalendarCore::Recurrence * EventWrapper::recurrence() const
{
    KCalendarCore::Recurrence *recurrence = m_event->recurrence();
    return recurrence;
}

KCalendarCore::Attendee::List EventWrapper::attendees() const
{
    return m_event->attendees();
}

RemindersModel * EventWrapper::remindersModel()
{
    return &m_remindersModel;
}

AttendeesModel * EventWrapper::attendeesModel()
{
    return &m_attendeesModel;
}

QVariantMap EventWrapper::recurrenceIntervals()
{
    return m_recurrenceIntervals;
}


void EventWrapper::setAllDay(bool allDay)
{
    m_event->setAllDay(allDay);
}


void EventWrapper::addAlarms(KCalendarCore::Alarm::List alarms)
{
    for (int i = 0; i < alarms.size(); i++) {
        m_event->addAlarm(alarms[i]);
    }
}

void EventWrapper::setRegularRecurrence(EventWrapper::RecurrenceIntervals interval)
{
    switch(interval) {
        case Daily:
            m_event->recurrence()->setDaily(1);
            return;
        case Weekly:
            m_event->recurrence()->setWeekly(1);
            return;
        case Monthly:
            m_event->recurrence()->setMonthly(1);
            return;
        case Yearly:
            m_event->recurrence()->setYearly(1);
            return;
        default:
            qWarning() << "Unknown interval for recurrence" << interval;
            return;
    }
}


