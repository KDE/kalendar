// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>
#include <CalendarSupport/KCalPrefs>
#include <CalendarSupport/Utils>
#include <AkonadiCore/CollectionIdentificationAttribute>


class EventCreator : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString summary READ summary WRITE setSummary NOTIFY summaryChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY descriptionChanged)
    Q_PROPERTY(QDateTime eventStart READ eventStart WRITE setEventStart NOTIFY eventStartChanged)
    Q_PROPERTY(QDateTime eventEnd READ eventEnd WRITE setEventEnd NOTIFY eventEndChanged)
    Q_PROPERTY(KCalendarCore::Recurrence * recurrence READ recurrence)
    Q_PROPERTY(KCalendarCore::Attendee::List attendees READ attendees)
    Q_PROPERTY(KCalendarCore::Alarm::List alarms READ alarms)

public:
    EventCreator(QObject *parent = nullptr);
    ~EventCreator() override;

    QString summary();
    void setSummary(QString summary);
    QString description();
    void setDescription(QString description);
    QDateTime eventStart();
    void setEventStart(QDateTime eventStart);
    QDateTime eventEnd();
    void setEventEnd(QDateTime eventEnd);
    KCalendarCore::Recurrence * recurrence();
    KCalendarCore::Attendee::List attendees();
    KCalendarCore::Alarm::List alarms();

Q_SIGNALS:
    void summaryChanged();
    void descriptionChanged();
    void eventStartChanged();
    void eventEndChanged();

private:
    KCalendarCore::Event::Ptr m_event;
};
