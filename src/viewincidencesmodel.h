// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "incidenceoccurrencemodel.h"
#include "multidayincidencemodel.h"
#include <QAbstractListModel>
#include <QDateTime>
#include <QList>
#include <QModelIndex>
#include <QSharedPointer>
#include <QVariant>

class ViewIncidencesModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(IncidenceOccurrenceModel *model READ model WRITE setModel NOTIFY modelChanged)

public:
    struct IncidenceOccurrenceData {
        QString text;
        QString description;
        QString location;
        QDateTime startTime;
        QDateTime endTime;
        bool allDay;
        bool todoCompleted;
        int priority;
        int line; // Line positioning
        int starts; // X axis positioning
        int duration; // Incidence width
        QString durationString;
        bool recurs;
        bool hasReminders;
        bool isOverdue;
        QColor color;
        qint64 collectionId;
        QString incidenceId;
        int incidenceType;
        QString incidenceTypeStr;
        QString incidenceTypeIcon;
        KCalendarCore::Incidence::Ptr incidencePtr;
        IncidenceOccurrenceModel::Occurrence incidenceOccurrence;
    };

    enum Roles {
        TextRole,
        DescriptionRole,
        LocationRole,
        StartTimeRole,
        EndTimeRole,
        AllDayRole,
        TodoCompletedRole,
        PriorityRole,
        LineRole,
        StartsRole,
        DurationRole,
        DurationStringRole,
        RecursRole,
        HasRemindersRole,
        IsOverdueRole,
        ColorRole,
        CollectionIdRole,
        IncidenceIdRole,
        IncidenceTypeRole,
        IncidenceTypeStrRole,
        IncidenceTypeIconRole,
        IncidencePtrRole,
        IncidenceOccurrenceRole
    };
    Q_ENUM(Roles);

    ViewIncidencesModel(QDate periodStart, int periodLength, IncidenceOccurrenceModel *sourceModel, QObject *parent = nullptr);

    IncidenceOccurrenceModel *model();
    void setModel(IncidenceOccurrenceModel *model);

    // We first sort all occurrences so we get all-day first (sorted by duration),
    // and then the rest sorted by start-date.
    void sortedIncidencesFromSourceModel();

    /*
     * Layout the lines:
     *
     * The line grouping algorithm then always picks the first incidence,
     * and tries to add more to the same line.
     *
     * We never mix all-day and non-all day, and otherwise try to fit as much as possible
     * on the same line. Same day time-order should be preserved because of the sorting.
     */
    void layoutLines();

    int rowCount(const QModelIndex &parent) const override;
    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    bool incidencePassesFilter(const QModelIndex &idx) const;
    void setFilters(MultiDayIncidenceModel::Filters filters);

Q_SIGNALS:
    void modelChanged();
    void filtersChanged();

private:
    QTimer mRefreshTimer;
    QVector<IncidenceOccurrenceData> m_incidenceOccurrences;
    QDate m_periodStart;
    QDate m_periodEnd;
    int m_periodLength;
    IncidenceOccurrenceModel *m_sourceModel = nullptr;
    QFlags<MultiDayIncidenceModel::Filter> m_filters;
};
