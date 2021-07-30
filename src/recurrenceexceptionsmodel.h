// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QAbstractItemModel>
#include <QCalendar>
#include <KCalendarCore/Calendar>
#include <QDebug>


class RecurrenceExceptionsModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(KCalendarCore::Incidence::Ptr incidencePtr READ incidencePtr WRITE setIncidencePtr NOTIFY incidencePtrChanged)
    Q_PROPERTY(QList<QDate> exceptions READ exceptions NOTIFY exceptionsChanged)
    Q_PROPERTY(QVariantMap dataroles READ dataroles CONSTANT)

public:
    enum Roles {
        DateRole = Qt::UserRole + 1,
    };
    Q_ENUM(Roles);

    explicit RecurrenceExceptionsModel(QObject *parent = nullptr, KCalendarCore::Incidence::Ptr incidencePtr = nullptr);
    ~RecurrenceExceptionsModel() = default;

    KCalendarCore::Incidence::Ptr incidencePtr();
    void setIncidencePtr(KCalendarCore::Incidence::Ptr incidence);
    QList<QDate> exceptions();
    void updateExceptions();
    QVariantMap dataroles();

    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    Q_INVOKABLE void addExceptionDateTime(QDateTime date);
    Q_INVOKABLE void deleteExceptionDateTime(QDateTime date);

Q_SIGNALS:
    void incidencePtrChanged();
    void exceptionsChanged();

private:
    KCalendarCore::Incidence::Ptr m_incidence;
    QList<QDate> m_exceptions;
    QVariantMap m_dataRoles;
};
