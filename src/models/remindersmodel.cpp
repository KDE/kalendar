// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "kalendar_debug.h"
#include <QMetaEnum>
#include <models/remindersmodel.h>

RemindersModel::RemindersModel(QObject *parent, KCalendarCore::Incidence::Ptr incidencePtr)
    : QAbstractListModel(parent)
    , m_incidence(incidencePtr)
{
    for (int i = 0; i < QMetaEnum::fromType<RemindersModel::Roles>().keyCount(); i++) {
        const int value = QMetaEnum::fromType<RemindersModel::Roles>().value(i);
        const QString key = QLatin1String(roleNames().value(value));
        m_dataRoles[key] = value;
    }
}

KCalendarCore::Incidence::Ptr RemindersModel::incidencePtr()
{
    return m_incidence;
}

void RemindersModel::setIncidencePtr(KCalendarCore::Incidence::Ptr incidence)
{
    if (m_incidence == incidence) {
        return;
    }
    m_incidence = incidence;
    Q_EMIT incidencePtrChanged();
    Q_EMIT alarmsChanged();
    Q_EMIT layoutChanged();
}

KCalendarCore::Alarm::List RemindersModel::alarms()
{
    return m_incidence->alarms();
}

QVariantMap RemindersModel::dataroles()
{
    return m_dataRoles;
}

QVariant RemindersModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }
    auto alarm = m_incidence->alarms()[idx.row()];
    switch (role) {
    case TypeRole:
        return alarm->type();
    case TimeRole:
        return alarm->time();
    case StartOffsetRole:
        return alarm->startOffset().asSeconds();
    case EndOffsetRole:
        return alarm->endOffset().asSeconds();
    default:
        qCWarning(KALENDAR_LOG) << "Unknown role for incidence:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return {};
    }
}

bool RemindersModel::setData(const QModelIndex &idx, const QVariant &value, int role)
{
    if (!idx.isValid()) {
        return false;
    }

    switch (role) {
    case TypeRole: {
        auto type = static_cast<KCalendarCore::Alarm::Type>(value.toInt());
        m_incidence->alarms()[idx.row()]->setType(type);
        break;
    }
    case TimeRole: {
        QDateTime time = value.toDateTime();
        m_incidence->alarms()[idx.row()]->setTime(time);
        break;
    }
    case StartOffsetRole: {
        // offset can be set in seconds or days, if we want it to be before the incidence,
        // it has to be set to a negative value.
        KCalendarCore::Duration offset(value.toInt());
        m_incidence->alarms()[idx.row()]->setStartOffset(offset);
        break;
    }
    case EndOffsetRole: {
        KCalendarCore::Duration offset(value.toInt());
        m_incidence->alarms()[idx.row()]->setEndOffset(offset);
        break;
    }
    default:
        qCWarning(KALENDAR_LOG) << "Unknown role for incidence:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return false;
    }
    Q_EMIT dataChanged(idx, idx);
    return true;
}

QHash<int, QByteArray> RemindersModel::roleNames() const
{
    return {
        {TypeRole, QByteArrayLiteral("type")},
        {TimeRole, QByteArrayLiteral("time")},
        {StartOffsetRole, QByteArrayLiteral("startOffset")},
        {EndOffsetRole, QByteArrayLiteral("endOffset")},
    };
}

int RemindersModel::rowCount(const QModelIndex &) const
{
    return m_incidence->alarms().size();
}

void RemindersModel::addAlarm()
{
    KCalendarCore::Alarm::Ptr alarm(new KCalendarCore::Alarm(m_incidence.get()));
    alarm->setEnabled(true);
    alarm->setType(KCalendarCore::Alarm::Display);
    alarm->setText(m_incidence->summary());
    alarm->setStartOffset(0);

    qCDebug(KALENDAR_LOG) << alarm->parentUid();

    m_incidence->addAlarm(alarm);
    Q_EMIT alarmsChanged();
    Q_EMIT layoutChanged();
}

void RemindersModel::deleteAlarm(int row)
{
    if (!hasIndex(row, 0)) {
        return;
    }

    m_incidence->removeAlarm(m_incidence->alarms()[row]);
    Q_EMIT alarmsChanged();
    Q_EMIT layoutChanged();
}
