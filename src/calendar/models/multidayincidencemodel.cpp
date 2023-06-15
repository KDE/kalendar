// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "multidayincidencemodel.h"
#include <QBitArray>

using namespace std::chrono_literals;

MultiDayIncidenceModel::MultiDayIncidenceModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_refreshTimer.setSingleShot(true);
    m_refreshTimer.setInterval(m_active ? 200ms : 1000ms);
    m_refreshTimer.callOnTimeout(this, [this]() {
        Q_EMIT dataChanged(index(0, 0), index(rowCount() - 1, 0));
    });
}

void MultiDayIncidenceModel::classBegin()
{
}

void MultiDayIncidenceModel::componentComplete()
{
    beginResetModel();
    m_initialized = true;
    endResetModel();
}

void MultiDayIncidenceModel::scheduleReset()
{
    if (!m_refreshTimer.isActive()) {
        m_refreshTimer.start();
    }
}

int MultiDayIncidenceModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid() || !mSourceModel || !m_initialized) {
        return 0;
    }

    // Number of weeks
    return qMax(mSourceModel->length() / mPeriodLength, 1);
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
            // qCWarning(KALENDAR_CALENDAR_LOG) << "Skipping because not part of this week";
            continue;
        }

        if (!incidencePassesFilter(srcIdx)) {
            continue;
        }

        // qCWarning(KALENDAR_CALENDAR_LOG) << "found " << srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime() <<
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
    //     qCWarning(KALENDAR_CALENDAR_LOG) << "sorted " << srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime() <<
    //     srcIdx.data(IncidenceOccurrenceModel::Summary).toString()
    //     << srcIdx.data(IncidenceOccurrenceModel::AllDay).toBool();
    // }

    QVariantList result;
    while (!sorted.isEmpty()) {
        const auto srcIdx = sorted.takeFirst();
        const auto startDate = srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date() < rowStart
            ? rowStart
            : srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date();
        const auto start = getStart(srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date());
        const auto duration = qMin(getDuration(startDate, srcIdx.data(IncidenceOccurrenceModel::EndTime).toDateTime().date()), mPeriodLength - start);

        // qCWarning(KALENDAR_CALENDAR_LOG) << "First of line " << srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime() << duration <<
        // srcIdx.data(IncidenceOccurrenceModel::Summary).toString();
        QVariantList currentLine;

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
            // qCWarning(KALENDAR_CALENDAR_LOG) << "Skipping " << srcIdx.data(IncidenceOccurrenceModel::Summary);
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
                    // qCWarning(KALENDAR_CALENDAR_LOG) << "Found intersection " << start << end;
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
        // qCWarning(KALENDAR_CALENDAR_LOG) << "Appending line " << currentLine;
        result.append(QVariant::fromValue(currentLine));
    }
    return result;
}

QVariant MultiDayIncidenceModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(hasIndex(index.row(), index.column()) && mSourceModel);

    const auto rowStart = mSourceModel->start().addDays(index.row() * 7);

    switch (role) {
    case PeriodStartDateRole:
        return rowStart.startOfDay();
    case IncidencesRole:
        return layoutLines(rowStart);
    default:
        return {};
    }
}

IncidenceOccurrenceModel *MultiDayIncidenceModel::model() const
{
    return mSourceModel;
}

void MultiDayIncidenceModel::setModel(IncidenceOccurrenceModel *model)
{
    beginResetModel();
    mSourceModel = model;
    Q_EMIT modelChanged();
    endResetModel();

    auto resetModel = [this] {
        if (!m_refreshTimer.isActive()) {
            m_refreshTimer.start();
        }
    };

    connect(model, &QAbstractItemModel::dataChanged, this, &MultiDayIncidenceModel::slotSourceDataChanged);
    connect(model, &QAbstractItemModel::layoutChanged, this, resetModel);
    connect(model, &QAbstractItemModel::modelReset, this, resetModel);
    connect(model, &QAbstractItemModel::rowsMoved, this, resetModel);
    connect(model, &QAbstractItemModel::rowsInserted, this, resetModel);
    connect(model, &QAbstractItemModel::rowsRemoved, this, resetModel);
    connect(model, &IncidenceOccurrenceModel::lengthChanged, this, [this] {
        beginResetModel();
        endResetModel();
    });
}

void MultiDayIncidenceModel::slotSourceDataChanged(const QModelIndex &upperLeft, const QModelIndex &bottomRight)
{
    if (m_refreshTimer.isActive()) {
        // We don't care resetting will be done soon
        return;
    }

    QSet<int> rows;

    for (int i = upperLeft.row(); i <= bottomRight.row(); ++i) {
        const auto sourceModelIndex = mSourceModel->index(i, 0, {});
        const auto occurrence = sourceModelIndex.data(IncidenceOccurrenceModel::IncidenceOccurrence).value<IncidenceOccurrenceModel::Occurrence>();

        const auto sourceModelStartDate = mSourceModel->start();
        const auto startDaysFromSourceStart = sourceModelStartDate.daysTo(occurrence.start.date());
        const auto endDaysFromSourceStart = sourceModelStartDate.daysTo(occurrence.end.date());

        const auto firstPeriodOccurrenceAppears = startDaysFromSourceStart / mPeriodLength;
        const auto lastPeriodOccurrenceAppears = endDaysFromSourceStart / mPeriodLength;

        if (firstPeriodOccurrenceAppears > rowCount() || lastPeriodOccurrenceAppears < 0) {
            continue;
        }

        const auto lastRow = rowCount() - 1;
        rows.insert(qMin(qMax(static_cast<int>(firstPeriodOccurrenceAppears), 0), lastRow));
        rows.insert(qMin(static_cast<int>(lastPeriodOccurrenceAppears), lastRow));
    }

    for (const auto row : std::as_const(rows)) {
        Q_EMIT dataChanged(index(row, 0), index(row, 0), {IncidencesRole});
    }
}

int MultiDayIncidenceModel::periodLength() const
{
    return mPeriodLength;
}

void MultiDayIncidenceModel::setPeriodLength(int periodLength)
{
    beginResetModel();
    if (mPeriodLength == periodLength) {
        return;
    }
    mPeriodLength = periodLength;
    Q_EMIT periodLengthChanged();
    endResetModel();
}

MultiDayIncidenceModel::Filters MultiDayIncidenceModel::filters() const
{
    return m_filters;
}

void MultiDayIncidenceModel::setFilters(MultiDayIncidenceModel::Filters filters)
{
    if (m_filters == filters) {
        return;
    }
    m_filters = filters;
    Q_EMIT filtersChanged();

    scheduleReset();
}

bool MultiDayIncidenceModel::showTodos() const
{
    return m_showTodos;
}

void MultiDayIncidenceModel::setShowTodos(const bool showTodos)
{
    if (showTodos == m_showTodos) {
        return;
    }

    m_showTodos = showTodos;
    Q_EMIT showTodosChanged();

    scheduleReset();
}

bool MultiDayIncidenceModel::showSubTodos() const
{
    return m_showSubTodos;
}

void MultiDayIncidenceModel::setShowSubTodos(const bool showSubTodos)
{
    if (showSubTodos == m_showSubTodos) {
        return;
    }

    m_showSubTodos = showSubTodos;
    Q_EMIT showSubTodosChanged();

    scheduleReset();
}

bool MultiDayIncidenceModel::incidencePassesFilter(const QModelIndex &idx) const
{
    if (!m_filters && m_showTodos && m_showSubTodos) {
        return true;
    }

    bool include = true;

    if (m_filters) {
        // Start out assuming the worst, filter everything out
        include = false;

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

    const auto incidencePtr = idx.data(IncidenceOccurrenceModel::IncidencePtr).value<KCalendarCore::Incidence::Ptr>();
    const auto incidenceIsTodo = incidencePtr->type() == Incidence::TypeTodo;
    if (!m_showTodos && incidenceIsTodo) {
        include = false;
    } else if (m_showTodos && incidenceIsTodo && !m_showSubTodos && !incidencePtr->relatedTo().isEmpty()) {
        include = false;
    }

    return include;
}

int MultiDayIncidenceModel::incidenceCount() const
{
    int count = 0;

    for (int i = 0; i < rowCount(); i++) {
        const auto rowStart = mSourceModel->start().addDays(i * mPeriodLength);
        const auto rowEnd = rowStart.addDays(mPeriodLength > 1 ? mPeriodLength : 0);

        for (int row = 0; row < mSourceModel->rowCount(); row++) {
            const auto srcIdx = mSourceModel->index(row, 0, {});
            const auto start = srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date();
            const auto end = srcIdx.data(IncidenceOccurrenceModel::EndTime).toDateTime().date();

            // Skip incidences not part of the week
            if (end < rowStart || start > rowEnd) {
                // qCWarning(KALENDAR_CALENDAR_LOG) << "Skipping because not part of this week";
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

bool MultiDayIncidenceModel::active() const
{
    return m_active;
}

void MultiDayIncidenceModel::setActive(const bool active)
{
    if (active == m_active) {
        return;
    }

    m_active = active;
    Q_EMIT activeChanged();

    if (active && m_refreshTimer.isActive() && std::chrono::milliseconds(m_refreshTimer.remainingTime()) > 200ms) {
        Q_EMIT dataChanged(index(0, 0), index(rowCount() - 1, 0));
        m_refreshTimer.stop();
    }
    m_refreshTimer.setInterval(active ? 200ms : 1000ms);
}

QHash<int, QByteArray> MultiDayIncidenceModel::roleNames() const
{
    return {
        {IncidencesRole, "incidences"},
        {PeriodStartDateRole, "periodStartDate"},
    };
}
