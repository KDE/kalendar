// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QAbstractItemModel>
#include <QList>
#include <QSet>
#include <QSharedPointer>
#include <QTimer>
#include <QColor>
#include <QDateTime>
#include <etmcalendar.h>

namespace KCalendarCore {
    class MemoryCalendar;
    class Event;
}
namespace Akonadi {
    class ETMCalendar;
}

using namespace KCalendarCore;

/**
 * Loads all event occurrences within the given period and matching the given filter.
 *
 * Recurrences are expanded
 */
class EventOccurrenceModel : public QAbstractItemModel
{
    Q_OBJECT
    Q_PROPERTY(QDate start READ start WRITE setStart NOTIFY startChanged)
    Q_PROPERTY(int length READ length WRITE setLength NOTIFY lengthChanged)
    Q_PROPERTY(QVariantMap filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(Akonadi::ETMCalendar *calendar READ calendar WRITE setCalendar NOTIFY calendarChanged)

public:
    enum Roles {
        Summary = Qt::UserRole + 1,
        Description,
        StartTime,
        EndTime,
        Color,
        AllDay,
        Event,
        EventOccurrence,
        LastRole
    };
    Q_ENUM(Roles);
    EventOccurrenceModel(QObject *parent = nullptr);
    ~EventOccurrenceModel() = default;

    QModelIndex index(int row, int column, const QModelIndex &parent = {}) const override;
    QModelIndex parent(const QModelIndex &index) const override;

    int rowCount(const QModelIndex &parent = {}) const override;
    int columnCount(const QModelIndex &parent) const override;

    QVariant data(const QModelIndex &index, int role) const override;

    void updateQuery(const QDate &start, const QDate &end);
    Akonadi::ETMCalendar *calendar() const;
    void setCalendar(Akonadi::ETMCalendar *calendar);

    void setStart(const QDate &);
    QDate start() const;
    void setLength(int);
    int length() const;
    void setFilter(const QVariantMap &);

    void load();
    void save() const;

    struct Occurrence {
        QDateTime start;
        QDateTime end;
        QSharedPointer<KCalendarCore::Event> event;
        QColor color;
        bool allDay;
    };

Q_SIGNALS:
    void startChanged();
    void lengthChanged();
    void filterChanged();
    void calendarChanged();

private:
    void updateQuery();

    void refreshView();
    void updateFromSource();
    QColor getColor(const KCalendarCore::Event::Ptr &color);

    QSharedPointer<QAbstractItemModel> mSourceModel;
    QDate mStart;
    QDate mEnd;
    int mLength{0};
    Akonadi::ETMCalendar *m_coreCalendar;

    QTimer mRefreshTimer;

    QList<Occurrence> m_events;
    QHash<QString, QColor> m_colors;
    QVariantMap mFilter;
};

Q_DECLARE_METATYPE(EventOccurrenceModel::Occurrence);

