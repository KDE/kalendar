// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// Copyright (c) 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QObject>
#include <akonadi-calendar_version.h>
#if AKONADICALENDAR_VERSION > QT_VERSION_CHECK(5, 19, 41)
#include <Akonadi/ETMCalendar>
#else
#include <Akonadi/Calendar/ETMCalendar>
#endif

#include <KConfigWatcher>
#include <KFormat>
#include <QAbstractItemModel>
#include <QColor>
#include <QDateTime>
#include <QList>
#include <QSharedPointer>
#include <QTimer>

namespace KCalendarCore
{
class Incidence;
}
namespace Akonadi
{
class ETMCalendar;
}

using namespace KCalendarCore;

/**
 * Loads all event occurrences within the given period and matching the given filter.
 *
 * Recurrences are expanded
 */
class IncidenceOccurrenceModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QDate start READ start WRITE setStart NOTIFY startChanged)
    Q_PROPERTY(int length READ length WRITE setLength NOTIFY lengthChanged)
    Q_PROPERTY(QVariantMap filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(Akonadi::ETMCalendar::Ptr calendar READ calendar WRITE setCalendar NOTIFY calendarChanged)

public:
    enum Roles {
        Summary = Qt::UserRole + 1,
        Description,
        Location,
        StartTime,
        EndTime,
        Duration,
        DurationString,
        Recurs,
        HasReminders,
        Priority,
        Color,
        CollectionId,
        AllDay,
        TodoCompleted,
        IsOverdue,
        IsReadOnly,
        IncidenceId,
        IncidenceType,
        IncidenceTypeStr,
        IncidenceTypeIcon,
        IncidencePtr,
        IncidenceOccurrence,
        LastRole
    };
    Q_ENUM(Roles);
    explicit IncidenceOccurrenceModel(QObject *parent = nullptr);
    ~IncidenceOccurrenceModel() override = default;

    int rowCount(const QModelIndex &parent = {}) const override;

    QVariant data(const QModelIndex &index, int role) const override;

    void updateQuery();
    Akonadi::ETMCalendar::Ptr calendar() const;
    void setCalendar(Akonadi::ETMCalendar::Ptr calendar);

    void setStart(const QDate &start);
    QDate start() const;
    void setLength(int length);
    int length() const;
    QVariantMap filter() const;
    void setFilter(const QVariantMap &filter);

    void load();

    struct Occurrence {
        QDateTime start;
        QDateTime end;
        QSharedPointer<KCalendarCore::Incidence> incidence;
        QColor color;
        qint64 collectionId;
        bool allDay;
    };

Q_SIGNALS:
    void startChanged();
    void lengthChanged();
    void filterChanged();
    void calendarChanged();

private:
    void refreshView();
    void updateFromSource();
    QColor getColor(const KCalendarCore::Incidence::Ptr &incidence);
    qint64 getCollectionId(const KCalendarCore::Incidence::Ptr &incidence);

    QSharedPointer<QAbstractItemModel> mSourceModel;
    QDate mStart;
    QDate mEnd;
    int mLength{0};
    Akonadi::ETMCalendar::Ptr m_coreCalendar;

    QTimer mRefreshTimer;

    QList<Occurrence> m_incidences;
    QHash<QString, QColor> m_colors;
    KConfigWatcher::Ptr m_colorWatcher;
    QVariantMap mFilter;
    KFormat m_format;
};

Q_DECLARE_METATYPE(IncidenceOccurrenceModel::Occurrence)
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
Q_DECLARE_METATYPE(KCalendarCore::Incidence::Ptr)
#endif
