// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <eventcreator.h>

EventCreator::EventCreator(QObject *parent)
    : QObject(parent)
{
    KCalendarCore::Event::Ptr m_event(new KCalendarCore::Event);
}

EventCreator::~EventCreator()
{

}

QString EventCreator::summary()
{
    return m_event->summary();
}

void EventCreator::setSummary(QString summary)
{
    m_event->setSummary(summary);
}

QString EventCreator::description()
{
    return m_event->description();
}

void EventCreator::setDescription(QString description)
{
    m_event->setDescription(description);
}

QDateTime EventCreator::eventStart()
{
    return m_event->dtStart();
}

void EventCreator::setEventStart(QDateTime eventStart)
{
    m_event->setDtStart(eventStart);
}

QDateTime EventCreator::eventEnd()
{
    return m_event->dtEnd();
}

void EventCreator::setEventEnd(QDateTime eventEnd)
{
    m_event->setDtStart(eventEnd);
}

KCalendarCore::Recurrence * EventCreator::recurrence()
{
    KCalendarCore::Recurrence *recurrence = m_event->recurrence();
    return recurrence;
}

KCalendarCore::Attendee::List EventCreator::attendees()
{
    return m_event->attendees();
}

KCalendarCore::Alarm::List EventCreator::alarms()
{
    return m_event->alarms();
}








