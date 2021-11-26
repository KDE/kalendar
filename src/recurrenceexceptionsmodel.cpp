// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "recurrenceexceptionsmodel.h"
#include "kalendar_debug.h"
#include <QDebug>
#include <QMetaEnum>

RecurrenceExceptionsModel::RecurrenceExceptionsModel(QObject *parent, KCalendarCore::Incidence::Ptr incidencePtr)
    : QAbstractListModel(parent)
    , m_incidence(incidencePtr)
{
    for (int i = 0; i < QMetaEnum::fromType<RecurrenceExceptionsModel::Roles>().keyCount(); i++) {
        const int value = QMetaEnum::fromType<RecurrenceExceptionsModel::Roles>().value(i);
        const QString key = QLatin1String(roleNames().value(value));
        m_dataRoles[key] = value;
    }

    connect(this, &RecurrenceExceptionsModel::incidencePtrChanged, this, &RecurrenceExceptionsModel::updateExceptions);
}

KCalendarCore::Incidence::Ptr RecurrenceExceptionsModel::incidencePtr()
{
    return m_incidence;
}

void RecurrenceExceptionsModel::setIncidencePtr(KCalendarCore::Incidence::Ptr incidence)
{
    if (m_incidence == incidence) {
        return;
    }
    m_incidence = incidence;
    Q_EMIT incidencePtrChanged();
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

    const auto dateTimes = m_incidence->recurrence()->exDateTimes();
    for (const QDateTime &dateTime : dateTimes) {
        m_exceptions.append(dateTime.date());
    }

    const auto dates = m_incidence->recurrence()->exDates();
    for (const QDate &date : dates) {
        m_exceptions.append(date);
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
        qCWarning(KALENDAR_LOG) << "Unknown role for incidence:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return {};
    }
}

QHash<int, QByteArray> RecurrenceExceptionsModel::roleNames() const
{
    return {{DateRole, QByteArrayLiteral("date")}};
}

int RecurrenceExceptionsModel::rowCount(const QModelIndex &) const
{
    return m_exceptions.size();
}

void RecurrenceExceptionsModel::addExceptionDateTime(QDateTime date)
{
    if (!date.isValid()) {
        return;
    }

    // I don't know why, but different types take different date formats
    if (m_incidence->recurrence()->allDay()) {
        m_incidence->recurrence()->addExDateTime(date);
    } else {
        m_incidence->recurrence()->addExDate(date.date());
    }

    updateExceptions();
}

void RecurrenceExceptionsModel::deleteExceptionDateTime(QDateTime date)
{
    if (!date.isValid()) {
        return;
    }

    if (m_incidence->recurrence()->allDay()) {
        auto dateTimes = m_incidence->recurrence()->exDateTimes();
        dateTimes.removeAt(dateTimes.indexOf(date));
        m_incidence->recurrence()->setExDateTimes(dateTimes);
    } else {
        auto dates = m_incidence->recurrence()->exDates();
        int removeIndex = dates.indexOf(date.date());

        if (removeIndex >= 0) {
            dates.removeAt(dates.indexOf(date.date()));
            m_incidence->recurrence()->setExDates(dates);
            updateExceptions();
            return;
        }

        auto dateTimes = m_incidence->recurrence()->exDateTimes();

        for (int i = 0; i < dateTimes.size(); i++) {
            if (dateTimes[i].date() == date.date()) {
                dateTimes.removeAt(i);
            }
        }
        m_incidence->recurrence()->setExDateTimes(dateTimes);
    }

    updateExceptions();
}
