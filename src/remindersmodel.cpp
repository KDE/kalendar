// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QMetaEnum>
#include <remindersmodel.h>

RemindersModel::RemindersModel(QObject *parent, KCalendarCore::Event::Ptr eventPtr)
    : QAbstractListModel(parent)
    , m_event(eventPtr)
{
    for(int i = 0; i < QMetaEnum::fromType<RemindersModel::Roles>().keyCount(); i++) {
        int value = QMetaEnum::fromType<RemindersModel::Roles>().value(i);
        QString key = QLatin1String(roleNames()[value]);
        m_dataRoles[key] = value;
    }
}

KCalendarCore::Event::Ptr RemindersModel::eventPtr()
{
    return m_event;
}

void RemindersModel::setEventPtr(KCalendarCore::Event::Ptr event)
{
    if (m_event == event) {
        return;
    }
    m_event = event;
    Q_EMIT eventPtrChanged();
}

KCalendarCore::Alarm::List RemindersModel::alarms()
{
    return m_event->alarms();
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
    auto alarm = m_event->alarms()[idx.row()];
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
            qWarning() << "Unknown role for event:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return {};
    }
}

bool RemindersModel::setData(const QModelIndex &idx, const QVariant &value, int role)
{
    if (!idx.isValid()) {
        return false;
    }

    switch (role) {
        case TypeRole:
        {
            KCalendarCore::Alarm::Type type = static_cast<KCalendarCore::Alarm::Type>(value.toInt());
            m_event->alarms()[idx.row()]->setType(type);
            break;
        }
        case TimeRole:
        {
            QDateTime time = value.toDateTime();
            m_event->alarms()[idx.row()]->setTime(time);
            break;
        }
        case StartOffsetRole:
        {
            // offset can be set in seconds or days, if we want it to be before the event,
            // it has to be set to a negative value.
            KCalendarCore::Duration offset(value.toInt());
            m_event->alarms()[idx.row()]->setStartOffset(offset);
            break;
        }
        case EndOffsetRole:
        {
            KCalendarCore::Duration offset(value.toInt());
            m_event->alarms()[idx.row()]->setEndOffset(offset);
            break;
        }
        default:
            qWarning() << "Unknown role for event:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return false;
    }
    emit dataChanged(idx, idx);
    return true;
}

QHash<int, QByteArray> RemindersModel::roleNames() const
{
    return {
        { TypeRole, QByteArrayLiteral("type") },
        { TimeRole, QByteArrayLiteral("time") },
        { StartOffsetRole, QByteArrayLiteral("startOffset") },
        { EndOffsetRole, QByteArrayLiteral("endOffset") }
    };
}

int RemindersModel::rowCount(const QModelIndex &) const
{
    return m_event->alarms().size();
}

void RemindersModel::addAlarm()
{
    KCalendarCore::Alarm::Ptr alarm (new KCalendarCore::Alarm(nullptr));
    m_event->addAlarm(alarm);
    Q_EMIT alarmsChanged();
    Q_EMIT layoutChanged();
}

void RemindersModel::deleteAlarm(int row)
{
    if (!hasIndex(row, 0)) {
        return;
    }

    m_event->removeAlarm(m_event->alarms()[row]);
    Q_EMIT alarmsChanged();
    Q_EMIT layoutChanged();
}
