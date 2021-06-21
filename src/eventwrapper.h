// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>
#include <CalendarSupport/KCalPrefs>
#include <CalendarSupport/Utils>
#include <AkonadiCore/CollectionIdentificationAttribute>
#include "remindersmodel.h"
#include "attendeesmodel.h"

/**
 * This class is a wrapper for a KCalendarCore::Event::Ptr object.
 * We can use it to create new events, or create event pointers from
 * pre-existing events, to more cleanly pass around to our QML code
 * or to the CalendarManager, which handles the back-end stuff of
 * adding and editing the event in the collection of our choice.
 */

class EventWrapper : public QObject
{
    Q_OBJECT
    Q_PROPERTY(KCalendarCore::Event::Ptr eventPtr READ eventPtr WRITE setEventPtr NOTIFY eventPtrChanged)
    Q_PROPERTY(QString summary READ summary WRITE setSummary NOTIFY summaryChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY descriptionChanged)
    Q_PROPERTY(QString location READ location WRITE setLocation NOTIFY locationChanged)
    Q_PROPERTY(QDateTime eventStart READ eventStart WRITE setEventStart NOTIFY eventStartChanged)
    Q_PROPERTY(QDateTime eventEnd READ eventEnd WRITE setEventEnd NOTIFY eventEndChanged)
    Q_PROPERTY(KCalendarCore::Recurrence * recurrence READ recurrence)
    Q_PROPERTY(KCalendarCore::Attendee::List attendees READ attendees)
    Q_PROPERTY(RemindersModel * remindersModel READ remindersModel NOTIFY remindersModelChanged)
    Q_PROPERTY(AttendeesModel * attendeesModel READ attendeesModel NOTIFY attendeesModelChanged)
    Q_PROPERTY(QVariantMap recurrenceIntervals READ recurrenceIntervals CONSTANT)

public:
    enum RecurrenceIntervals {
        Daily,
        Weekly,
        Monthly,
        Yearly
    };
    Q_ENUM(RecurrenceIntervals);

    EventWrapper(QObject *parent = nullptr);
    ~EventWrapper() = default;

    KCalendarCore::Event::Ptr eventPtr() const;
    void setEventPtr(KCalendarCore::Event::Ptr eventPtr);
    QString summary() const;
    void setSummary(QString summary);
    QString description() const;
    void setDescription(QString description);
    QString location() const;
    void setLocation(QString location);
    QDateTime eventStart() const;
    void setEventStart(QDateTime eventStart);
    QDateTime eventEnd() const;
    void setEventEnd(QDateTime eventEnd);
    KCalendarCore::Recurrence * recurrence() const;
    KCalendarCore::Attendee::List attendees() const;
    RemindersModel * remindersModel();
    AttendeesModel * attendeesModel();
    QVariantMap recurrenceIntervals();

    Q_INVOKABLE void setAllDay(bool allDay);
    Q_INVOKABLE void addAlarms(KCalendarCore::Alarm::List alarms);
    Q_INVOKABLE void setRegularRecurrence(RecurrenceIntervals interval, int freq = 1);

Q_SIGNALS:
    void eventPtrChanged(KCalendarCore::Event::Ptr eventPtr);
    void summaryChanged();
    void descriptionChanged();
    void locationChanged();
    void eventStartChanged();
    void eventEndChanged();
    void remindersModelChanged();
    void attendeesModelChanged();

private:
    KCalendarCore::Event::Ptr m_event;
    RemindersModel m_remindersModel;
    AttendeesModel m_attendeesModel;
    QVariantMap m_recurrenceIntervals;
};
