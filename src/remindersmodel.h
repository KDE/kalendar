// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QAbstractItemModel>
#include <QCalendar>
#include <KCalendarCore/Calendar>
#include <QDebugStateSaver>
#include <QDebug>

/**
 * This class provides a QAbstractItemModel for an events' reminders/alarms.
 * This can be useful for letting users add, modify, or delete events on new or pre-existing events.
 * It treats the event's list of alarms as the signle source of truth (and it should be kept this way!)
 *
 * The data for the model comes from m_event, which is set in the constructor. This is a pointer to the
 * event this model is getting the alarm info from. All alarm pointers are then added to m_alarms, which
 * is a list. Elements in this model are therefore accessed through row numbers, as the list is a one-
 * dimensional data structure.
 */

class RemindersModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(KCalendarCore::Event::Ptr eventPtr READ eventPtr WRITE setEventPtr NOTIFY eventPtrChanged)
    Q_PROPERTY(KCalendarCore::Alarm::List alarms READ alarms NOTIFY alarmsChanged)
    Q_PROPERTY(QVariantMap dataroles READ dataroles CONSTANT)

public:
    enum Roles {
        TypeRole = Qt::UserRole + 1,
        TimeRole,
        StartOffsetRole,
        EndOffsetRole
    };
    Q_ENUM(Roles);

    explicit RemindersModel(QObject *parent = nullptr, KCalendarCore::Event::Ptr eventPtr = nullptr);
    ~RemindersModel() = default;

    KCalendarCore::Event::Ptr eventPtr();
    void setEventPtr(KCalendarCore::Event::Ptr event);
    KCalendarCore::Alarm::List alarms();
    QVariantMap dataroles();

    QVariant data(const QModelIndex &idx, int role) const override;
    bool setData(const QModelIndex &idx, const QVariant &value, int role) override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    Q_INVOKABLE void addAlarm();
    Q_INVOKABLE void deleteAlarm(int row);

Q_SIGNALS:
    void eventPtrChanged();
    void alarmsChanged();

private:
    KCalendarCore::Event::Ptr m_event;
    QVariantMap m_dataRoles;
};
