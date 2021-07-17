// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QMetaEnum>
#include <QBitArray>
#include <eventwrapper.h>

EventWrapper::EventWrapper(QObject *parent)
    : QObject(parent)
    , m_event(new KCalendarCore::Event)
    , m_remindersModel(parent, m_event)
    , m_attendeesModel(parent, m_event)
    , m_recurrenceExceptionsModel(parent, m_event)
{
    for(int i = 0; i < QMetaEnum::fromType<EventWrapper::RecurrenceIntervals>().keyCount(); i++) {
        int value = QMetaEnum::fromType<EventWrapper::RecurrenceIntervals>().value(i);
        QString key = QLatin1String(QMetaEnum::fromType<EventWrapper::RecurrenceIntervals>().key(i));
        m_recurrenceIntervals[key] = value;
    }

    m_event->setDtStart(QDateTime::currentDateTime());
    m_event->setDtEnd(QDateTime::currentDateTime().addSecs(60 * 60));

    // Change event pointer in remindersmodel if changed here
    connect(this, &EventWrapper::eventPtrChanged,
            &m_remindersModel, [=](KCalendarCore::Event::Ptr eventPtr){ m_remindersModel.setEventPtr(eventPtr); });
    connect(this, &EventWrapper::eventPtrChanged,
            &m_attendeesModel, [=](KCalendarCore::Event::Ptr eventPtr){ m_attendeesModel.setEventPtr(eventPtr); });
    connect(this, &EventWrapper::eventPtrChanged,
            &m_recurrenceExceptionsModel, [=](KCalendarCore::Event::Ptr eventPtr){ m_recurrenceExceptionsModel.setEventPtr(eventPtr); });
}

KCalendarCore::Event::Ptr EventWrapper::eventPtr() const
{
    return m_event;
}

void EventWrapper::setEventPtr(KCalendarCore::Event::Ptr eventPtr)
{
    m_event = eventPtr;
    KCalendarCore::Event::Ptr originalEvent(eventPtr->clone());
    m_originalEvent = originalEvent;

    Q_EMIT eventPtrChanged(m_event);
    Q_EMIT originalEventPtrChanged();
    Q_EMIT collectionIdChanged();
    Q_EMIT summaryChanged();
    Q_EMIT descriptionChanged();
    Q_EMIT locationChanged();
    Q_EMIT eventStartChanged();
    Q_EMIT eventEndChanged();
    Q_EMIT allDayChanged();
    Q_EMIT remindersModelChanged();
    Q_EMIT attendeesModelChanged();
    Q_EMIT recurrenceWeekDaysChanged();
    Q_EMIT recurrenceDurationChanged();
    Q_EMIT recurrenceFrequencyChanged();
    Q_EMIT recurrenceEndDateTimeChanged();
    Q_EMIT recurrenceTypeChanged();
    Q_EMIT recurrenceExceptionsModelChanged();
}

KCalendarCore::Event::Ptr EventWrapper::originalEventPtr()
{
    return m_originalEvent;
}


qint64 EventWrapper::collectionId()
{
    return m_collectionId;
}

void EventWrapper::setCollectionId(qint64 collectionId)
{
    m_collectionId = collectionId;
    Q_EMIT collectionIdChanged();
}

QString EventWrapper::summary() const
{
    return m_event->summary();
}

void EventWrapper::setSummary(QString summary)
{
    m_event->setSummary(summary);
    Q_EMIT summaryChanged();
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
    Q_EMIT locationChanged();
}


QDateTime EventWrapper::eventStart() const
{
    return m_event->dtStart();
}

void EventWrapper::setEventStart(QDateTime eventStart)
{
    m_event->setDtStart(eventStart);
    Q_EMIT eventStartChanged();
}

QDateTime EventWrapper::eventEnd() const
{
    return m_event->dtEnd();
}

void EventWrapper::setEventEnd(QDateTime eventEnd)
{
    m_event->setDtEnd(eventEnd);
    Q_EMIT eventEndChanged();
}

bool EventWrapper::allDay() const
{
    return m_event->allDay();
}

void EventWrapper::setAllDay(bool allDay)
{
    m_event->setAllDay(allDay);
    Q_EMIT allDayChanged();
}

KCalendarCore::Recurrence * EventWrapper::recurrence() const
{
    KCalendarCore::Recurrence *recurrence = m_event->recurrence();
    return recurrence;
}

QVector<bool> EventWrapper::recurrenceWeekDays()
{
    QBitArray weekDaysBits = m_event->recurrence()->days();
    QVector<bool> weekDaysBools(7);

    for(int i = 0; i < weekDaysBits.size(); i++) {
        weekDaysBools[i] = weekDaysBits[i];
    }

    return weekDaysBools;
}

void EventWrapper::setRecurrenceWeekDays(const QVector<bool> recurrenceWeekDays)
{
    QBitArray days(7);

    for(int i = 0; i < recurrenceWeekDays.size(); i++) {
        days[i] = recurrenceWeekDays[i];
    }

    KCalendarCore::RecurrenceRule *rrule = m_event->recurrence()->defaultRRule();
    QList<KCalendarCore::RecurrenceRule::WDayPos> positions;

    for (int i = 0; i < 7; ++i) {
        if (days.testBit(i)) {
            KCalendarCore::RecurrenceRule::WDayPos p(0, i + 1);
            positions.append(p);
        }
    }

    rrule->setByDays(positions);
    m_event->recurrence()->updated();

    Q_EMIT recurrenceWeekDaysChanged();
}

int EventWrapper::recurrenceDuration()
{
    return m_event->recurrence()->duration();
}

void EventWrapper::setRecurrenceDuration(int recurrenceDuration)
{
    m_event->recurrence()->setDuration(recurrenceDuration);
    Q_EMIT recurrenceDurationChanged();
}

int EventWrapper::recurrenceFrequency()
{
    return m_event->recurrence()->frequency();
}

void EventWrapper::setRecurrenceFrequency(int recurrenceFrequency)
{
    m_event->recurrence()->setFrequency(recurrenceFrequency);
    Q_EMIT recurrenceFrequencyChanged();
}

QDateTime EventWrapper::recurrenceEndDateTime()
{
    return m_event->recurrence()->endDateTime();
}

void EventWrapper::setRecurrenceEndDateTime(QDateTime endDateTime)
{
    m_event->recurrence()->setEndDateTime(endDateTime);
    Q_EMIT recurrenceEndDateTimeChanged();
}

ushort EventWrapper::recurrenceType()
{
    return m_event->recurrence()->recurrenceType();
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

RecurrenceExceptionsModel * EventWrapper::recurrenceExceptionsModel()
{
    return &m_recurrenceExceptionsModel;
}


QVariantMap EventWrapper::recurrenceIntervals()
{
    return m_recurrenceIntervals;
}


void EventWrapper::addAlarms(KCalendarCore::Alarm::List alarms)
{
    for (int i = 0; i < alarms.size(); i++) {
        m_event->addAlarm(alarms[i]);
    }
}

void EventWrapper::setRegularRecurrence(EventWrapper::RecurrenceIntervals interval, int freq)
{
    switch(interval) {
        case Daily:
            m_event->recurrence()->setDaily(freq);
            Q_EMIT recurrenceFrequencyChanged();
            return;
        case Weekly:
            m_event->recurrence()->setWeekly(freq);
            Q_EMIT recurrenceFrequencyChanged();
            return;
        case Monthly:
            m_event->recurrence()->setMonthly(freq);
            Q_EMIT recurrenceFrequencyChanged();
            return;
        case Yearly:
            m_event->recurrence()->setYearly(freq);
            Q_EMIT recurrenceFrequencyChanged();
            return;
        default:
            qWarning() << "Unknown interval for recurrence" << interval;
            return;
    }
}

void EventWrapper::setMonthlyPosRecurrence(short pos, int day)
{
    QBitArray daysBitArray(7);
    daysBitArray[day] = 1;
    m_event->recurrence()->addMonthlyPos(pos, daysBitArray);
}

void EventWrapper::setRecurrenceOcurrences(int ocurrences)
{
    m_event->recurrence()->setDuration(ocurrences);
    Q_EMIT recurrenceDurationChanged();
}

void EventWrapper::clearRecurrences()
{
    m_event->recurrence()->clear();
    Q_EMIT recurrenceDurationChanged();
}

