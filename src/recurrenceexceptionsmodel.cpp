// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QMetaEnum>
#include "recurrenceexceptionsmodel.h"

RecurrenceExceptionsModel::RecurrenceExceptionsModel(QObject* parent, KCalendarCore::Event::Ptr eventPtr)
    : QAbstractListModel(parent)
    , m_event(eventPtr)
{
    for(int i = 0; i < QMetaEnum::fromType<RecurrenceExceptionsModel::Roles>().keyCount(); i++) {
        int value = QMetaEnum::fromType<RecurrenceExceptionsModel::Roles>().value(i);
        QString key = QLatin1String(roleNames()[value]);
        m_dataRoles[key] = value;
    }

    connect(this, &RecurrenceExceptionsModel::eventPtrChanged, this, &RecurrenceExceptionsModel::updateExceptions);
}

KCalendarCore::Event::Ptr RecurrenceExceptionsModel::eventPtr()
{
    return m_event;
}

void RecurrenceExceptionsModel::setEventPtr(KCalendarCore::Event::Ptr event)
{
    if (m_event == event) {
        return;
    }
    m_event = event;
    Q_EMIT eventPtrChanged();
    Q_EMIT exceptionsChanged();
    Q_EMIT layoutChanged();
}

QList<QDate> RecurrenceExceptionsModel::exceptions()
{
    return m_exceptions;
}

void RecurrenceExceptionsModel::updateExceptions()
{
    m_exceptions.clear();

    for(const QDateTime &dt : m_event->recurrence()->exDateTimes()) {
        m_exceptions.append(dt.date());
    }

    for(const QDate &dt : m_event->recurrence()->exDates()) {
        m_exceptions.append(dt);
    }
    Q_EMIT exceptionsChanged();
    Q_EMIT layoutChanged();
}


QVariantMap RecurrenceExceptionsModel::dataroles()
{
    return m_dataRoles;
}

QVariant RecurrenceExceptionsModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }
    QDate exception = m_exceptions[idx.row()];
    switch (role) {
        case DateRole:
            return exception;
        default:
            qWarning() << "Unknown role for event:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return {};
    }
}

QHash<int, QByteArray> RecurrenceExceptionsModel::roleNames() const
{
	return {
        { DateRole, QByteArrayLiteral("date") }
    };
}

int RecurrenceExceptionsModel::rowCount(const QModelIndex &) const
{
    return m_exceptions.size();
}

void RecurrenceExceptionsModel::addExceptionDateTime(QDateTime date)
{
    if(!date.isValid()) {
        return;
    }

    // I don't know why, but different types take different date formats
    if (m_event->recurrence()->allDay()) {
        m_event->recurrence()->addExDateTime(date);
    } else {
        m_event->recurrence()->addExDate(date.date());
    }

    updateExceptions();
}

void RecurrenceExceptionsModel::deleteExceptionDateTime(QDateTime date)
{
    if(!date.isValid()) {
        return;
    }


    if (m_event->recurrence()->allDay()) {
        auto dateTimes = m_event->recurrence()->exDateTimes();
        dateTimes.removeAt(dateTimes.indexOf(date));
        m_event->recurrence()->setExDateTimes(dateTimes);
    } else {
        auto dates = m_event->recurrence()->exDates();
        int removeIndex = dates.indexOf(date.date());

        if (removeIndex >= 0) {
            dates.removeAt(dates.indexOf(date.date()));
            m_event->recurrence()->setExDates(dates);
            updateExceptions();
            return;
        }

        auto dateTimes = m_event->recurrence()->exDateTimes();

        for(int i = 0; i < dateTimes.size(); i++) {
            if (dateTimes[i].date() == date.date()) {
                dateTimes.removeAt(i);
            }
        }
        m_event->recurrence()->setExDateTimes(dateTimes);
    }

    updateExceptions();
}
