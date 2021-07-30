// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QAbstractItemModel>
#include <QCalendar>
#include <KCalendarCore/Calendar>
#include <QDebugStateSaver>
#include <QDebug>

/**
 *
 */
class AttendeeStatusModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        DisplayNameRole = Qt::UserRole + 1,
        ValueRole
    };
    Q_ENUM(Roles);

    AttendeeStatusModel(QObject *parent = nullptr);
    ~AttendeeStatusModel() = default;

    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

private:
    QHash<int, QString> m_status;
};




class AttendeesModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(KCalendarCore::Incidence::Ptr incidencePtr READ incidencePtr WRITE setIncidencePtr NOTIFY incidencePtrChanged)
    Q_PROPERTY(KCalendarCore::Attendee::List attendees READ attendees NOTIFY attendeesChanged)
    Q_PROPERTY(AttendeeStatusModel * attendeeStatusModel READ attendeeStatusModel NOTIFY attendeeStatusModelChanged)
    Q_PROPERTY(QVariantMap dataroles READ dataroles CONSTANT)

public:
    enum Roles {
        CuTypeRole = Qt::UserRole + 1,
        DelegateRole,
        DelegatorRole,
        EmailRole,
        FullNameRole,
        IsNullRole,
        NameRole,
        RoleRole,
        RSVPRole,
        StatusRole,
        UidRole
    };
    Q_ENUM(Roles);

    explicit AttendeesModel(QObject *parent = nullptr, KCalendarCore::Incidence::Ptr incidencePtr = nullptr);
    ~AttendeesModel() = default;

    KCalendarCore::Incidence::Ptr incidencePtr();
    void setIncidencePtr(KCalendarCore::Incidence::Ptr incidence);
    KCalendarCore::Attendee::List attendees();
    AttendeeStatusModel * attendeeStatusModel();
    QVariantMap dataroles();

    QVariant data(const QModelIndex &idx, int role) const override;
    bool setData(const QModelIndex &idx, const QVariant &value, int role) override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    Q_INVOKABLE void addAttendee();
    Q_INVOKABLE void deleteAttendee(int row);

Q_SIGNALS:
    void incidencePtrChanged();
    void attendeesChanged();
    void attendeeStatusModelChanged();

private:
    KCalendarCore::Incidence::Ptr m_incidence;
    AttendeeStatusModel m_attendeeStatusModel;
    QVariantMap m_dataRoles;
};
