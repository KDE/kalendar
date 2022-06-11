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
    : QAbstractItemModel(parent)
{
    mRefreshTimer.setSingleShot(true);
    m_config = KalendarConfig::self();

    const auto resetModel = [&] {
        beginResetModel();
        endResetModel();
    };

    connect(m_config, &KalendarConfig::showSubtodosInCalendarViewsChanged, this, resetModel);
    connect(m_config, &KalendarConfig::showDay1Changed, this, &MultiDayIncidenceModel::updateShownDays);
    connect(m_config, &KalendarConfig::showDay2Changed, this, &MultiDayIncidenceModel::updateShownDays);
    connect(m_config, &KalendarConfig::showDay3Changed, this, &MultiDayIncidenceModel::updateShownDays);
    connect(m_config, &KalendarConfig::showDay4Changed, this, &MultiDayIncidenceModel::updateShownDays);
    connect(m_config, &KalendarConfig::showDay5Changed, this, &MultiDayIncidenceModel::updateShownDays);
    connect(m_config, &KalendarConfig::showDay6Changed, this, &MultiDayIncidenceModel::updateShownDays);
    connect(m_config, &KalendarConfig::showDay7Changed, this, &MultiDayIncidenceModel::updateShownDays);

    updateShownDays();
}

void MultiDayIncidenceModel::updateShownDays()
{
    beginResetModel();

    m_hiddenSpaces[0] = !m_config->showDay1();
    m_hiddenSpaces[1] = !m_config->showDay2();
    m_hiddenSpaces[2] = !m_config->showDay3();
    m_hiddenSpaces[3] = !m_config->showDay4();
    m_hiddenSpaces[4] = !m_config->showDay5();
    m_hiddenSpaces[5] = !m_config->showDay6();
    m_hiddenSpaces[6] = !m_config->showDay7();

    m_numHiddenSpaces = m_hiddenSpaces.count(true);

    endResetModel();
}

QModelIndex MultiDayIncidenceModel::index(int row, int column, const QModelIndex &parent) const
{
    if (!hasIndex(row, column, parent)) {
        return {};
    }

    if (!parent.isValid()) {
        return createIndex(row, column);
    }
    return {};
}

QModelIndex MultiDayIncidenceModel::parent(const QModelIndex &) const
{
    return {};
}

int MultiDayIncidenceModel::rowCount(const QModelIndex &parent) const
{
    // Number of weeks
    if (!parent.isValid() && mSourceModel) {
        return qMax(mSourceModel->length() / mPeriodLength, 1);
    }
    return 0;
}

int MultiDayIncidenceModel::columnCount(const QModelIndex &) const
{
    return 1;
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

MultiDayIncidenceModel::ProcessedIncidenceLayout
MultiDayIncidenceModel::layoutIncidenceProcess(const QModelIndex &idx, const QBitArray takenSpaces, const QDate &rowStart) const
{
    auto getStart = [&rowStart](const QDate &start) {
        return (qMax(rowStart.daysTo(start), 0ll));
    };

    const auto startDate = idx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date() < rowStart
        ? rowStart
        : idx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date();

    // There is no way these numbers will realistically require anything larger than an integer.
    // With a minimum of 0 and a maximum of whatever the mPeriodLength is (we skip over events
    // beyond the end of the period being examined in this model) then an int will always suffice.
    // Please don't try and break this wrong with a massive mPeriodLength ;)

    // Start position on view, as an index (i.e. if 7 days in a week in the month view, position ranging 0-6)
    int start = getStart(idx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date());
    // Number of positions to take up (positions being, for example, day grid columns)
    int duration = qMin(static_cast<int>(getDuration(startDate, idx.data(IncidenceOccurrenceModel::EndTime).toDateTime().date())), mPeriodLength - start);

    // For some reason we have received an incidence with a date outside our date range, so skip
    if (start >= mPeriodLength) {
        return {Skip, 0, 0, 0};
    }

    // TODO: Again, generalise this code for other periods
    if (mPeriodLength <= 7) {
        // We always try to exit as quickly as possible to prevent bogging down unnecessarily
        if (duration == 1 && m_hiddenSpaces[start]) {
            return {Skip, 0, 0, 0};
        }

        // We also have to check for which days are hidden by the user. If a day is hidden we have to adjust the start
        // or end numbers as well. Here we move forward start (and cut back duration) if the start date is hidden
        while (start < mPeriodLength && duration > 0 && m_numHiddenSpaces > 0 && m_hiddenSpaces[start]) {
            start += 1;
            duration -= 1;
        }
        if (start >= mPeriodLength || duration < 0) {
            return {Skip, 0, 0, 0};
        }
        for (int i = 0; i < duration; i++) {
            if (m_hiddenSpaces[start + i]) {
                duration -= 1;
            }
        }
        if (start >= mPeriodLength || duration < 0) {
            return {Skip, 0, 0, 0};
        }
    }

    const auto end = start + duration;

    // TODO: Add this as an option
    // This leaves a space in rows with all day events, making this y area of the row exclusively for all day events
    /*if (allDayLine && !idx.data(IncidenceOccurrenceModel::AllDay).toBool()) {
        continue;
    }*/

    bool doesIntersect = false; // Check if positions for this incidence are already taken
    for (int i = start; i < end; i++) {
        if (takenSpaces[i]) {
            return {Delay, 0, 0, 0};
        }
    }

    if (doesIntersect) {
        return {Delay, 0, 0, 0};
    } else {
        // Incidence fits on line, set its space as taken
        return {Proceed, start, duration, end};
    }
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
    QList<QModelIndex> sorted = sortedIncidencesFromSourceModel(rowStart);
    auto result = QVariantList{};

    while (!sorted.isEmpty()) {
        QBitArray takenSpaces(mPeriodLength);
        auto fillSpaces = [&takenSpaces](int start, int duration) {
            for (int i = start; i < start + duration; i++) {
                takenSpaces[i] = true;
            }
        };

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

        const auto srcIdx = sorted.takeFirst();
        const auto processed = layoutIncidenceProcess(srcIdx, takenSpaces, rowStart);

        if (processed.result == Skip) {
            qDebug() << processed.start << srcIdx.data(IncidenceOccurrenceModel::Summary).toString();
            continue;
        }

        // Add first incidence of line
        addToLine(srcIdx, processed.start, processed.duration);
        // const bool allDayLine = srcIdx.data(IncidenceOccurrenceModel::AllDay).toBool();

        // Fill line with incidences that fit
        fillSpaces(processed.start, processed.duration);

        for (auto it = sorted.begin(); it != sorted.end();) {
            const auto idx = *it;
            const auto processed = layoutIncidenceProcess(idx, takenSpaces, rowStart);

            // Somehow the incidences are getting eaten up right to left?
            qDebug() << processed.start << idx.data(IncidenceOccurrenceModel::Summary).toString();
            if (processed.result == Skip) {
                qDebug() << processed.start << idx.data(IncidenceOccurrenceModel::Summary).toString();
                it = sorted.erase(it);
            } else if (processed.result == Delay) {
                it++;
            } else {
                // Incidence fits on line, set its space as taken
                addToLine(idx, processed.start, processed.duration);
                fillSpaces(processed.start, processed.duration);
                it = sorted.erase(it);
            }
        }
        // qCWarning(KALENDAR_LOG) << "Appending line " << currentLine;
        result.append(QVariant::fromValue(currentLine));
    }
    return result;
}

QVariant MultiDayIncidenceModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }
    if (!mSourceModel) {
        return {};
    }
    const auto rowStart = mSourceModel->start().addDays(idx.row() * mPeriodLength);
    switch (role) {
    case PeriodStartDate:
        return rowStart.startOfDay();
    case Incidences:
        return layoutLines(rowStart);
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

    mSourceModel = model;
    Q_EMIT modelChanged();
    auto resetModel = [this] {
        if (!mRefreshTimer.isActive()) {
            beginResetModel();
            endResetModel();
            Q_EMIT incidenceCountChanged();
            mRefreshTimer.start(50);
        }
    };
    QObject::connect(model, &QAbstractItemModel::dataChanged, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::layoutChanged, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::modelReset, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::rowsInserted, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::rowsMoved, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::rowsRemoved, this, resetModel);
    endResetModel();
}

int MultiDayIncidenceModel::periodLength()
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
