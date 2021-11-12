// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// Copyright (c) 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <KConfigWatcher>
#include <QAbstractItemModel>
#include <QColor>
#include <QDateTime>
#include <QList>
#include <QSet>
#include <QSharedPointer>
#include <QTimer>
#include <etmcalendar.h>

namespace KCalendarCore
{
class MemoryCalendar;
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
class IncidenceOccurrenceModel : public QAbstractItemModel
{
    Q_OBJECT
    Q_PROPERTY(QDate start READ start WRITE setStart NOTIFY startChanged)
    Q_PROPERTY(int length READ length WRITE setLength NOTIFY lengthChanged)
    Q_PROPERTY(QVariantMap filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(Akonadi::ETMCalendar *calendar READ calendar WRITE setCalendar NOTIFY calendarChanged)
    Q_PROPERTY(bool handleOwnRefresh READ handleOwnRefresh WRITE setHandleOwnRefresh NOTIFY handleOwnRefreshChanged)

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
    IncidenceOccurrenceModel(QObject *parent = nullptr);
    ~IncidenceOccurrenceModel() override = default;

    QModelIndex index(int row, int column, const QModelIndex &parent = {}) const override;
    QModelIndex parent(const QModelIndex &index) const override;

    int rowCount(const QModelIndex &parent = {}) const override;
    int columnCount(const QModelIndex &parent) const override;

    QVariant data(const QModelIndex &index, int role) const override;

    void updateQuery();
    Akonadi::ETMCalendar *calendar() const;
    void setCalendar(Akonadi::ETMCalendar *calendar);

    void setStart(const QDate &start);
    QDate start() const;
    void setLength(int length);
    int length() const;
    QVariantMap filter() const;
    void setFilter(const QVariantMap &filter);

    bool handleOwnRefresh();
    void setHandleOwnRefresh(bool handleOwnRefresh);

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
    void handleOwnRefreshChanged();

private:
    void refreshView();
    void updateFromSource();
    QColor getColor(const KCalendarCore::Incidence::Ptr &incidence);
    qint64 getCollectionId(const KCalendarCore::Incidence::Ptr &incidence);

    QSharedPointer<QAbstractItemModel> mSourceModel;
    QDate mStart;
    QDate mEnd;
    int mLength{0};
    Akonadi::ETMCalendar *m_coreCalendar;

    QTimer mRefreshTimer;

    QList<Occurrence> m_incidences;
    QHash<QString, QColor> m_colors;
    KConfigWatcher::Ptr m_colorWatcher;
    QVariantMap mFilter;
    bool m_handleOwnRefresh = true;
    bool m_isDirty;
};

Q_DECLARE_METATYPE(IncidenceOccurrenceModel::Occurrence);
Q_DECLARE_METATYPE(KCalendarCore::Incidence::Ptr);
