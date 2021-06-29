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
    Q_PROPERTY(KCalendarCore::Event::Ptr eventPtr READ eventPtr WRITE setEventPtr NOTIFY eventPtrChanged)
    Q_PROPERTY(QList<QDate> exceptions READ exceptions NOTIFY exceptionsChanged)
    Q_PROPERTY(QVariantMap dataroles READ dataroles CONSTANT)

public:
    enum Roles {
        DateRole = Qt::UserRole + 1,
    };
    Q_ENUM(Roles);

    explicit RecurrenceExceptionsModel(QObject *parent = nullptr, KCalendarCore::Event::Ptr eventPtr = nullptr);
    ~RecurrenceExceptionsModel() = default;

    KCalendarCore::Event::Ptr eventPtr();
    void setEventPtr(KCalendarCore::Event::Ptr event);
    QList<QDate> exceptions();
    void updateExceptions();
    QVariantMap dataroles();

    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    Q_INVOKABLE void addExceptionDateTime(QDateTime date);
    Q_INVOKABLE void deleteExceptionDateTime(QDateTime date);

Q_SIGNALS:
    void eventPtrChanged();
    void exceptionsChanged();

private:
    KCalendarCore::Event::Ptr m_event;
    QList<QDate> m_exceptions;
    QVariantMap m_dataRoles;
};
