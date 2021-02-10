// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QAbstractItemModel>
#include <KCalendarCore/Event>

using namespace KCalendarCore;

/**
 * List model over the events.
 */
class EventsModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QDate date READ date WRITE setDate NOTIFY dateChanged)
    Q_PROPERTY(QVariantList events READ events WRITE setEvents NOTIFY eventsChanged)

public:
    enum Roles {
        Summary = Qt::UserRole,
        Location,
        IsEnd,
        IsBegin,
    };

public:
    explicit EventsModel(QObject *parent = nullptr);
    ~EventsModel();
    
    QVariantList events() const;
    void setEvents(const QVariantList &events);
    QDate date() const;
    void setDate(const QDate &date);
    QVariant data(const QModelIndex& index, int role) const override;
    int rowCount(const QModelIndex& parent) const override;
    QHash<int, QByteArray> roleNames() const override;
    
Q_SIGNALS:
    void eventsChanged();
    void dateChanged();
private:
    QVariantList m_events;
    QDate m_date;
};
