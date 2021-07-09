// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>
#include <CalendarSupport/KCalPrefs>
#include <CalendarSupport/Utils>
#include <AkonadiCore/CollectionIdentificationAttribute>
#include "remindersmodel.h"
#include "attendeesmodel.h"
#include "recurrenceexceptionsmodel.h"
#include "attachmentsmodel.h"

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
    Q_PROPERTY(KCalendarCore::Event::Ptr originalEventPtr READ originalEventPtr NOTIFY originalEventPtrChanged)
    Q_PROPERTY(qint64 collectionId READ collectionId WRITE setCollectionId NOTIFY collectionIdChanged)
    Q_PROPERTY(QString summary READ summary WRITE setSummary NOTIFY summaryChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY descriptionChanged)
    Q_PROPERTY(QString location READ location WRITE setLocation NOTIFY locationChanged)
    Q_PROPERTY(QDateTime eventStart READ eventStart WRITE setEventStart NOTIFY eventStartChanged)
    Q_PROPERTY(QDateTime eventEnd READ eventEnd WRITE setEventEnd NOTIFY eventEndChanged)
    Q_PROPERTY(bool allDay READ allDay WRITE setAllDay NOTIFY allDayChanged)
    Q_PROPERTY(KCalendarCore::Recurrence * recurrence READ recurrence)
    Q_PROPERTY(QVariantMap recurrenceData READ recurrenceData WRITE setRecurrenceData NOTIFY recurrenceDataChanged)
    Q_PROPERTY(QVariantMap organizer READ organizer NOTIFY organizerChanged)
    Q_PROPERTY(KCalendarCore::Attendee::List attendees READ attendees)
    Q_PROPERTY(RemindersModel * remindersModel READ remindersModel NOTIFY remindersModelChanged)
    Q_PROPERTY(AttendeesModel * attendeesModel READ attendeesModel NOTIFY attendeesModelChanged)
    Q_PROPERTY(RecurrenceExceptionsModel * recurrenceExceptionsModel READ recurrenceExceptionsModel NOTIFY recurrenceExceptionsModelChanged)
    Q_PROPERTY(AttachmentsModel * attachmentsModel READ attachmentsModel NOTIFY attachmentsModelChanged)
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
    KCalendarCore::Event::Ptr originalEventPtr();
    qint64 collectionId();
    void setCollectionId(qint64 collectionId);
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
    bool allDay() const;
    void setAllDay(bool allDay);

    KCalendarCore::Recurrence * recurrence() const;
    QVariantMap recurrenceData();
    void setRecurrenceData(QVariantMap recurrenceData);
    void setRecurrenceWeekDays(const QVector<bool> recurrenceWeekDays);
    QVariantMap organizer();

    KCalendarCore::Attendee::List attendees() const;
    RemindersModel * remindersModel();
    AttendeesModel * attendeesModel();
    RecurrenceExceptionsModel * recurrenceExceptionsModel();
    AttachmentsModel * attachmentsModel();
    QVariantMap recurrenceIntervals();

    Q_INVOKABLE void addAlarms(KCalendarCore::Alarm::List alarms);
    Q_INVOKABLE void setRegularRecurrence(RecurrenceIntervals interval, int freq = 1);
    Q_INVOKABLE void setMonthlyPosRecurrence(short pos, int day);
    Q_INVOKABLE void setRecurrenceOcurrences(int ocurrences);
    Q_INVOKABLE void clearRecurrences();

Q_SIGNALS:
    void eventPtrChanged(KCalendarCore::Event::Ptr eventPtr);
    void originalEventPtrChanged();
    void collectionIdChanged();
    void summaryChanged();
    void descriptionChanged();
    void locationChanged();
    void eventStartChanged();
    void eventEndChanged();
    void allDayChanged();
    void remindersModelChanged();
    void recurrenceDataChanged();
    void organizerChanged();
    void attendeesModelChanged();
    void recurrenceExceptionsModelChanged();
    void attachmentsModelChanged();

private:
    KCalendarCore::Event::Ptr m_event;
    KCalendarCore::Event::Ptr m_originalEvent;
    qint64 m_collectionId;
    RemindersModel m_remindersModel;
    AttendeesModel m_attendeesModel;
    RecurrenceExceptionsModel m_recurrenceExceptionsModel;
    AttachmentsModel m_attachmentsModel;
    QVariantMap m_recurrenceIntervals;
};
