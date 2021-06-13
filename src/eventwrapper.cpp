// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <eventwrapper.h>

EventWrapper::EventWrapper(QObject *parent)
    : QObject(parent)
    , m_event(new KCalendarCore::Event)
{

}

EventWrapper::~EventWrapper()
{

}

KCalendarCore::Event::Ptr EventWrapper::eventPtr() const
{
    return m_event;
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
    m_event->setDescription(description);
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

KCalendarCore::Alarm::List EventWrapper::alarms() const
{
    return m_event->alarms();
}








