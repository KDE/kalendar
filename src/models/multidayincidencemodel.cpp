// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "multidayincidencemodel.h"
#include "kalendar_debug.h"
#include <QBitArray>

MultiDayIncidenceModel::MultiDayIncidenceModel(QObject *parent)
    : QAbstractListModel(parent)
{
    mRefreshTimer.setSingleShot(true);
    mRefreshTimer.setInterval(100);
    mRefreshTimer.callOnTimeout(this, &MultiDayIncidenceModel::resetLayoutLines);

    m_config = KalendarConfig::self();
    QObject::connect(m_config, &KalendarConfig::showSubtodosInCalendarViewsChanged, this, [&]() {
        beginResetModel();
        endResetModel();
    });
}

int MultiDayIncidenceModel::rowCount(const QModelIndex &parent) const
{
    // Number of weeks
    if (!parent.isValid() && mSourceModel) {
        return qMax(mSourceModel->length() / mPeriodLength, 1);
    }
    return 0;
}

static long long getDuration(const QDate &start, const QDate &end)
{
    return qMax(start.daysTo(end) + 1, 1ll);
}

// We first sort all occurrences so we get all-day first (sorted by duration),
// and then the rest sorted by start-date.
QList<QModelIndex> MultiDayIncidenceModel::sortedIncidencesFromSourceModel(const QDate &rowStart) const
{
    // Don't add days if we are going for a daily period
    const auto rowEnd = rowStart.addDays(mPeriodLength > 1 ? mPeriodLength : 0);
    QList<QModelIndex> sorted;
    sorted.reserve(mSourceModel->rowCount());
    // Get incidences from source model
    for (int row = 0; row < mSourceModel->rowCount(); row++) {
        const auto srcIdx = mSourceModel->index(row, 0, {});
        const auto start = srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date();
        const auto end = srcIdx.data(IncidenceOccurrenceModel::EndTime).toDateTime().date();

        // Skip incidences not part of the week
        if (end < rowStart || start > rowEnd) {
            // qCWarning(KALENDAR_LOG) << "Skipping because not part of this week";
            continue;
        }

        if (!incidencePassesFilter(srcIdx)) {
            continue;
        }

        // qCWarning(KALENDAR_LOG) << "found " << srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime() <<
        // srcIdx.data(IncidenceOccurrenceModel::Summary).toString();
        sorted.append(srcIdx);
    }

    // Sort incidences by date
    std::sort(sorted.begin(), sorted.end(), [&](const QModelIndex &left, const QModelIndex &right) {
        // All-day first, sorted by duration (in the hope that we can fit multiple on the same line)
        const auto leftAllDay = left.data(IncidenceOccurrenceModel::AllDay).toBool();
        const auto rightAllDay = right.data(IncidenceOccurrenceModel::AllDay).toBool();

        const auto leftDuration =
            getDuration(left.data(IncidenceOccurrenceModel::StartTime).toDateTime().date(), left.data(IncidenceOccurrenceModel::EndTime).toDateTime().date());
        const auto rightDuration =
            getDuration(right.data(IncidenceOccurrenceModel::StartTime).toDateTime().date(), right.data(IncidenceOccurrenceModel::EndTime).toDateTime().date());

        const auto leftDt = left.data(IncidenceOccurrenceModel::StartTime).toDateTime();
        const auto rightDt = right.data(IncidenceOccurrenceModel::StartTime).toDateTime();

        if (leftAllDay && !rightAllDay) {
            return true;
        }
        if (!leftAllDay && rightAllDay) {
            return false;
        }
        if (leftAllDay && rightAllDay) {
            return leftDuration < rightDuration;
        }

        // The rest sorted by start date
        return leftDt < rightDt && leftDuration <= rightDuration;
    });

    return sorted;
}

/*
 * Layout the lines:
 *
 * The line grouping algorithm then always picks the first incidence,
 * and tries to add more to the same line.
 *
 * We never mix all-day and non-all day, and otherwise try to fit as much as possible
 * on the same line. Same day time-order should be preserved because of the sorting.
 */
QVariantList MultiDayIncidenceModel::layoutLines(const QDate &rowStart) const
{
    auto getStart = [&rowStart](const QDate &start) {
        return qMax(rowStart.daysTo(start), 0ll);
    };

    QList<QModelIndex> sorted = sortedIncidencesFromSourceModel(rowStart);

    // for (const auto &srcIdx : sorted) {
    //     qCWarning(KALENDAR_LOG) << "sorted " << srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime() <<
    //     srcIdx.data(IncidenceOccurrenceModel::Summary).toString()
    //     << srcIdx.data(IncidenceOccurrenceModel::AllDay).toBool();
    // }

    auto result = QVariantList{};
    while (!sorted.isEmpty()) {
        const auto srcIdx = sorted.takeFirst();
        const auto startDate = srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date() < rowStart
            ? rowStart
            : srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date();
        const auto start = getStart(srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date());
        const auto duration = qMin(getDuration(startDate, srcIdx.data(IncidenceOccurrenceModel::EndTime).toDateTime().date()), mPeriodLength - start);

        // qCWarning(KALENDAR_LOG) << "First of line " << srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime() << duration <<
        // srcIdx.data(IncidenceOccurrenceModel::Summary).toString();
        auto currentLine = QVariantList{};

        auto addToLine = [&currentLine](const QModelIndex &idx, int start, int duration) {
            currentLine.append(QVariantMap{
                {QStringLiteral("text"), idx.data(IncidenceOccurrenceModel::Summary)},
                {QStringLiteral("description"), idx.data(IncidenceOccurrenceModel::Description)},
                {QStringLiteral("location"), idx.data(IncidenceOccurrenceModel::Location)},
                {QStringLiteral("startTime"), idx.data(IncidenceOccurrenceModel::StartTime)},
                {QStringLiteral("endTime"), idx.data(IncidenceOccurrenceModel::EndTime)},
                {QStringLiteral("allDay"), idx.data(IncidenceOccurrenceModel::AllDay)},
                {QStringLiteral("todoCompleted"), idx.data(IncidenceOccurrenceModel::TodoCompleted)},
                {QStringLiteral("priority"), idx.data(IncidenceOccurrenceModel::Priority)},
                {QStringLiteral("starts"), start},
                {QStringLiteral("duration"), duration},
                {QStringLiteral("durationString"), idx.data(IncidenceOccurrenceModel::DurationString)},
                {QStringLiteral("recurs"), idx.data(IncidenceOccurrenceModel::Recurs)},
                {QStringLiteral("hasReminders"), idx.data(IncidenceOccurrenceModel::HasReminders)},
                {QStringLiteral("isOverdue"), idx.data(IncidenceOccurrenceModel::IsOverdue)},
                {QStringLiteral("isReadOnly"), idx.data(IncidenceOccurrenceModel::IsReadOnly)},
                {QStringLiteral("color"), idx.data(IncidenceOccurrenceModel::Color)},
                {QStringLiteral("collectionId"), idx.data(IncidenceOccurrenceModel::CollectionId)},
                {QStringLiteral("incidenceId"), idx.data(IncidenceOccurrenceModel::IncidenceId)},
                {QStringLiteral("incidenceType"), idx.data(IncidenceOccurrenceModel::IncidenceType)},
                {QStringLiteral("incidenceTypeStr"), idx.data(IncidenceOccurrenceModel::IncidenceTypeStr)},
                {QStringLiteral("incidenceTypeIcon"), idx.data(IncidenceOccurrenceModel::IncidenceTypeIcon)},
                {QStringLiteral("incidencePtr"), idx.data(IncidenceOccurrenceModel::IncidencePtr)},
                {QStringLiteral("incidenceOccurrence"), idx.data(IncidenceOccurrenceModel::IncidenceOccurrence)},
            });
        };

        if (start >= mPeriodLength) {
            // qCWarning(KALENDAR_LOG) << "Skipping " << srcIdx.data(IncidenceOccurrenceModel::Summary);
            continue;
        }

        // Add first incidence of line
        addToLine(srcIdx, start, duration);
        // const bool allDayLine = srcIdx.data(IncidenceOccurrenceModel::AllDay).toBool();

        // Fill line with incidences that fit
        QBitArray takenSpaces(mPeriodLength);
        // Set this incidence's space as taken
        for (int i = start; i < start + duration; i++) {
            takenSpaces[i] = true;
        }

        auto doesIntersect = [&](int start, int end) {
            for (int i = start; i < end; i++) {
                if (takenSpaces[i]) {
                    // qCWarning(KALENDAR_LOG) << "Found intersection " << start << end;
                    return true;
                }
            }

            // If incidence fits on line, set its space as taken
            for (int i = start; i < end; i++) {
                takenSpaces[i] = true;
            }
            return false;
        };

        for (auto it = sorted.begin(); it != sorted.end();) {
            const auto idx = *it;
            const auto startDate = idx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date() < rowStart
                ? rowStart
                : idx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date();
            const auto start = getStart(idx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date());
            const auto duration = qMin(getDuration(startDate, idx.data(IncidenceOccurrenceModel::EndTime).toDateTime().date()), mPeriodLength - start);
            const auto end = start + duration;

            // This leaves a space in rows with all day events, making this y area of the row exclusively for all day events
            /*if (allDayLine && !idx.data(IncidenceOccurrenceModel::AllDay).toBool()) {
                continue;
            }*/

            if (doesIntersect(start, end)) {
                it++;
            } else {
                addToLine(idx, start, duration);
                it = sorted.erase(it);
            }
        }
        // qCWarning(KALENDAR_LOG) << "Appending line " << currentLine;
        result.append(QVariant::fromValue(currentLine));
    }
    return result;
}

void MultiDayIncidenceModel::resetLayoutLines()
{
    beginResetModel();

    m_laidOutLines.clear();

    const auto numPeriods = rowCount({});
    m_laidOutLines.reserve(numPeriods);

    qDebug() << numPeriods;

    for(int i = 0; i < numPeriods; ++i) {
        const auto periodStart = mSourceModel->start().addDays(i * mPeriodLength);
        const auto periodIncidenceLayout = layoutLines(periodStart);
        m_laidOutLines.append(periodIncidenceLayout);
    }

    Q_EMIT incidenceCountChanged();
    endResetModel();
}

QVariant MultiDayIncidenceModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column()) || !mSourceModel || m_laidOutLines.empty()) {
        return {};
    }

    switch (role) {
    case PeriodStartDate:
    {
        const auto rowStart = mSourceModel->start().addDays(idx.row() * mPeriodLength);
        return rowStart.startOfDay();
    }
    case Incidences:
        return m_laidOutLines.at(idx.row());
    default:
        Q_ASSERT(false);
        return {};
    }
}

IncidenceOccurrenceModel *MultiDayIncidenceModel::model()
{
    return mSourceModel;
}

void MultiDayIncidenceModel::setModel(IncidenceOccurrenceModel *model)
{
    beginResetModel();

    m_laidOutLines.clear();
    mSourceModel = model;
    Q_EMIT modelChanged();

    endResetModel();

    auto resetModel = [this] {
        if (!mRefreshTimer.isActive()) {
            mRefreshTimer.start(100);
        }
    };
    QObject::connect(model, &QAbstractItemModel::dataChanged, this, &MultiDayIncidenceModel::slotSourceDataChanged);
    QObject::connect(model, &QAbstractItemModel::layoutChanged, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::modelReset, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::rowsInserted, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::rowsMoved, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::rowsRemoved, this, resetModel);

    mRefreshTimer.start(100);
}

void MultiDayIncidenceModel::slotSourceDataChanged(const QModelIndex &upperLeft, const QModelIndex &bottomRight)
{
    if(!upperLeft.isValid() || !bottomRight.isValid()) {
        return;
    }

    const auto startRow = upperLeft.row();
    const auto endRow = bottomRight.row();

    for (int i = startRow; i <= endRow; ++i) {
        const auto sourceModelIndex = mSourceModel->index(i);
        const auto occurrence = sourceModelIndex.data(IncidenceOccurrenceModel::IncidenceOccurrence).value<IncidenceOccurrenceModel::Occurrence>();

        const auto sourceModelStartDate = mSourceModel->start();
        const auto startDaysFromSourceStart = sourceModelStartDate.daysTo(occurrence.start.date());
        const auto endDaysFromSourceStart = sourceModelStartDate.daysTo(occurrence.end.date());

        const auto firstPeriodOccurrenceAppears = startDaysFromSourceStart / mPeriodLength;
        const auto lastPeriodOccurrenceAppears = endDaysFromSourceStart / mPeriodLength;

        qDebug() << occurrence.incidence->summary() << firstPeriodOccurrenceAppears << lastPeriodOccurrenceAppears;

        if(firstPeriodOccurrenceAppears > m_laidOutLines.count() || lastPeriodOccurrenceAppears < 0) {
            continue;
        }

        for (int i = firstPeriodOccurrenceAppears; i <= lastPeriodOccurrenceAppears; ++i) {
            const auto periodStart = mSourceModel->start().addDays(i * mPeriodLength);
            const auto idx = index(i, 0);

            m_laidOutLines.replace(i, layoutLines(periodStart));
            Q_EMIT dataChanged(idx, idx);
        }
    }
}

int MultiDayIncidenceModel::periodLength() const
{
    return mPeriodLength;
}

void MultiDayIncidenceModel::setPeriodLength(int periodLength)
{
    mPeriodLength = periodLength;
}

MultiDayIncidenceModel::Filters MultiDayIncidenceModel::filters()
{
    return m_filters;
}

void MultiDayIncidenceModel::setFilters(MultiDayIncidenceModel::Filters filters)
{
    beginResetModel();
    m_filters = filters;
    Q_EMIT filtersChanged();
    endResetModel();
}

bool MultiDayIncidenceModel::incidencePassesFilter(const QModelIndex &idx) const
{
    if (!m_filters && m_config->showSubtodosInCalendarViews()) {
        return true;
    }
    bool include = false;

    if (m_filters) {
        const auto start = idx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date();

        if (m_filters.testFlag(AllDayOnly) && idx.data(IncidenceOccurrenceModel::AllDay).toBool()) {
            include = true;
        }

        if (m_filters.testFlag(NoStartDateOnly) && !start.isValid()) {
            include = true;
        }
        if (m_filters.testFlag(MultiDayOnly) && idx.data(IncidenceOccurrenceModel::Duration).value<KCalendarCore::Duration>().asDays() >= 1) {
            include = true;
        }
    }

    if (!m_config->showSubtodosInCalendarViews()
        && idx.data(IncidenceOccurrenceModel::IncidencePtr).value<KCalendarCore::Incidence::Ptr>()->relatedTo().isEmpty()) {
        include = true;
    }

    return include;
}

int MultiDayIncidenceModel::incidenceCount()
{
    int count = 0;

    for (int i = 0; i < rowCount({}); i++) {
        const auto rowStart = mSourceModel->start().addDays(i * mPeriodLength);
        const auto rowEnd = rowStart.addDays(mPeriodLength > 1 ? mPeriodLength : 0);

        for (int row = 0; row < mSourceModel->rowCount(); row++) {
            const auto srcIdx = mSourceModel->index(row, 0, {});
            const auto start = srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date();
            const auto end = srcIdx.data(IncidenceOccurrenceModel::EndTime).toDateTime().date();

            // Skip incidences not part of the week
            if (end < rowStart || start > rowEnd) {
                // qCWarning(KALENDAR_LOG) << "Skipping because not part of this week";
                continue;
            }

            if (!incidencePassesFilter(srcIdx)) {
                continue;
            }

            count++;
        }
    }

    return count;
}

QHash<int, QByteArray> MultiDayIncidenceModel::roleNames() const
{
    return {
        {Incidences, "incidences"},
        {PeriodStartDate, "periodStartDate"},
    };
}
