// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// Copyright (c) 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <Akonadi/ETMCalendar>
#include <QObject>

#include <KConfigWatcher>
#include <KFormat>
#include <QAbstractItemModel>
#include <QColor>
#include <QDateTime>
#include <QList>
#include <QSharedPointer>
#include <QTimer>

class Filter;
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
    Q_PROPERTY(Filter *filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(Akonadi::ETMCalendar::Ptr calendar READ calendar WRITE setCalendar NOTIFY calendarChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(int resetThrottleInterval READ resetThrottleInterval WRITE setResetThrottleInterval NOTIFY resetThrottleIntervalChanged)

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
    Q_ENUM(Roles)
    explicit IncidenceOccurrenceModel(QObject *parent = nullptr);
    ~IncidenceOccurrenceModel() override = default;

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;

    Akonadi::ETMCalendar::Ptr calendar() const;
    QDate start() const;
    int length() const;
    Filter *filter() const;
    bool loading() const;
    int resetThrottleInterval() const;

    struct Occurrence {
        QDateTime start;
        QDateTime end;
        KCalendarCore::Incidence::Ptr incidence;
        QColor color;
        qint64 collectionId;
        bool allDay;
    };

Q_SIGNALS:
    void startChanged();
    void lengthChanged();
    void filterChanged();
    void calendarChanged();
    void loadingChanged();
    void resetThrottleIntervalChanged();

public Q_SLOTS:
    void setStart(const QDate &start);
    void setLength(int length);
    void setFilter(Filter *filter);
    void setCalendar(Akonadi::ETMCalendar::Ptr calendar);
    void setResetThrottleInterval(const int resetThrottleInterval);

private Q_SLOTS:
    void loadColors();
    void scheduleReset();
    void resetFromSource();
    void setLoading(const bool loading);

private:
    static std::pair<QDateTime, QDateTime> incidenceOccurrenceStartEnd(const QDateTime &ocStart, const KCalendarCore::Incidence::Ptr &incidence);
    bool incidencePassesFilter(const KCalendarCore::Incidence::Ptr &incidence);

    QColor getColor(const KCalendarCore::Incidence::Ptr &incidence);
    qint64 getCollectionId(const KCalendarCore::Incidence::Ptr &incidence);

    QSharedPointer<QAbstractItemModel> mSourceModel;
    QDate mStart;
    QDate mEnd;
    int mLength{0};
    Akonadi::ETMCalendar::Ptr m_coreCalendar;

    QTimer m_resetThrottlingTimer;
    int m_resetThrottleInterval = 100;

    bool m_loading = false;
    QVector<Occurrence> m_incidences; // We need incidences to be in a preditable order for the model
    QHash<QString, QColor> m_colors;
    KConfigWatcher::Ptr m_colorWatcher;
    Filter *mFilter = nullptr;
    KFormat m_format;
};

Q_DECLARE_METATYPE(IncidenceOccurrenceModel::Occurrence)

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
Q_DECLARE_METATYPE(KCalendarCore::Incidence::Ptr)
#endif
