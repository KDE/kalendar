// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "multidayincidencemodel.h"

enum Roles {
    Incidences = IncidenceOccurrenceModel::LastRole,
    PeriodStartDate
};

MultiDayIncidenceModel::MultiDayIncidenceModel(QObject *parent)
    : QAbstractItemModel(parent)
{
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
    //Number of weeks
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

// We first sort all occurences so we get all-day first (sorted by duration),
// and then the rest sorted by start-date.
QList<QModelIndex> MultiDayIncidenceModel::sortedIncidencesFromSourceModel(const QDate &rowStart) const
{
    // Don't add days if we are going for a daily period
    const auto rowEnd = rowStart.addDays(mPeriodLength > 1 ? mPeriodLength : 0);
    QList<QModelIndex> sorted;
    sorted.reserve(mSourceModel->rowCount());
    for (int row = 0; row < mSourceModel->rowCount(); row++) {
        const auto srcIdx = mSourceModel->index(row, 0, {});
        const auto start = srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date();
        const auto end = srcIdx.data(IncidenceOccurrenceModel::EndTime).toDateTime().date();

        //Skip incidences not part of the week
        if (end < rowStart || start > rowEnd) {
            // qWarning() << "Skipping because not part of this week";
            continue;
        }
        // qWarning() << "found " << srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime() << srcIdx.data(IncidenceOccurrenceModel::Summary).toString();
        sorted.append(srcIdx);
    }
    std::sort(sorted.begin(), sorted.end(), [&] (const QModelIndex &left, const QModelIndex &right) {
        //All-day first, sorted by duration (in the hope that we can fit multiple on the same line)
        const auto leftAllDay = left.data(IncidenceOccurrenceModel::AllDay).toBool();
        const auto rightAllDay = right.data(IncidenceOccurrenceModel::AllDay).toBool();
        if (leftAllDay && !rightAllDay) {
            return true;
        }
        if (!leftAllDay && rightAllDay) {
            return false;
        }
        if (leftAllDay && rightAllDay) {
            const auto leftDuration = getDuration(left.data(IncidenceOccurrenceModel::StartTime).toDateTime().date(), left.data(IncidenceOccurrenceModel::EndTime).toDateTime().date());
            const auto rightDuration = getDuration(right.data(IncidenceOccurrenceModel::StartTime).toDateTime().date(), right.data(IncidenceOccurrenceModel::EndTime).toDateTime().date());
            return leftDuration < rightDuration;
        }
        //The rest sored by start date
        return left.data(IncidenceOccurrenceModel::StartTime).toDateTime() < right.data(IncidenceOccurrenceModel::StartTime).toDateTime();
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
    auto getStart = [&rowStart] (const QDate &start) {
        return qMax(rowStart.daysTo(start), 0ll);
    };

    QList<QModelIndex> sorted = sortedIncidencesFromSourceModel(rowStart);

    // for (const auto &srcIdx : sorted) {
    //     qWarning() << "sorted " << srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime() << srcIdx.data(IncidenceOccurrenceModel::Summary).toString() << srcIdx.data(IncidenceOccurrenceModel::AllDay).toBool();
    // }

    auto result = QVariantList{};
    while (!sorted.isEmpty()) {
        const auto srcIdx = sorted.takeFirst();
        const auto startDate = srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date() < rowStart ?
                rowStart : srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date();
        const auto start = getStart(srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date());
        const auto duration = qMin(getDuration(startDate, srcIdx.data(IncidenceOccurrenceModel::EndTime).toDateTime().date()), mPeriodLength - start);

        // qWarning() << "First of line " << srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime() << duration << srcIdx.data(IncidenceOccurrenceModel::Summary).toString();
        auto currentLine = QVariantList{};

        auto addToLine = [&currentLine] (const QModelIndex &idx, int start, int duration) {
            currentLine.append(QVariantMap{
                {QStringLiteral("text"), idx.data(IncidenceOccurrenceModel::Summary)},
                {QStringLiteral("description"), idx.data(IncidenceOccurrenceModel::Description)},
                {QStringLiteral("location"), idx.data(IncidenceOccurrenceModel::Location)},
                {QStringLiteral("startTime"), idx.data(IncidenceOccurrenceModel::StartTime)},
                {QStringLiteral("endTime"), idx.data(IncidenceOccurrenceModel::EndTime)},
                {QStringLiteral("allDay"), idx.data(IncidenceOccurrenceModel::AllDay)},
                {QStringLiteral("todoCompleted"), idx.data(IncidenceOccurrenceModel::TodoCompleted)},
                {QStringLiteral("starts"), start},
                {QStringLiteral("duration"), duration},
                {QStringLiteral("durationString"), idx.data(IncidenceOccurrenceModel::DurationString)},
                {QStringLiteral("color"), idx.data(IncidenceOccurrenceModel::Color)},
                {QStringLiteral("collectionId"), idx.data(IncidenceOccurrenceModel::CollectionId)},
                {QStringLiteral("incidenceType"), idx.data(IncidenceOccurrenceModel::IncidenceType)},
                {QStringLiteral("incidenceTypeStr"), idx.data(IncidenceOccurrenceModel::IncidenceTypeStr)},
                {QStringLiteral("incidenceTypeIcon"), idx.data(IncidenceOccurrenceModel::IncidenceTypeIcon)},
                {QStringLiteral("incidencePtr"), idx.data(IncidenceOccurrenceModel::IncidencePtr)},
                {QStringLiteral("incidenceOccurrence"), idx.data(IncidenceOccurrenceModel::IncidenceOccurrence)}
            });
        };

        //Add first incidence of line
        addToLine(srcIdx, start, duration);
        const bool allDayLine = srcIdx.data(IncidenceOccurrenceModel::AllDay).toBool();

        //Fill line with incidences that fit
        int lastStart = start;
        int lastDuration = duration;
        auto doesIntersect = [&] (int start, int end) {
            const auto lastEnd = lastStart + lastDuration;
            if (((start <= lastStart) && (end >= lastStart)) ||
                ((start < lastEnd) && (end > lastStart))) {
                // qWarning() << "Found intersection " << start << end;
                return true;
            }
            return false;
        };

        for (auto it = sorted.begin(); it != sorted.end();) {
            const auto idx = *it;
            const auto startDate = idx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date() < rowStart ?
                rowStart : idx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date();
            const auto start = getStart(idx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date());
            const auto duration = qMin(getDuration(startDate, idx.data(IncidenceOccurrenceModel::EndTime).toDateTime().date()), mPeriodLength - start);
            const auto end = start + duration;

            // qWarning() << "Checking " << idx.data(IncidenceOccurrenceModel::StartTime).toDateTime() << duration << idx.data(IncidenceOccurrenceModel::Summary).toString();
            //Avoid mixing all-day and other incidences
            if (allDayLine && !idx.data(IncidenceOccurrenceModel::AllDay).toBool()) {
                break;
            }

            if (doesIntersect(start, end)) {
                it++;
            } else {
                addToLine(idx, start, duration);
                lastStart = start;
                lastDuration = duration;
                it = sorted.erase(it);
            }
        }
        // qWarning() << "Appending line " << currentLine;
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
            return rowStart;
        case Incidences:
            return layoutLines(rowStart);
        default:
            Q_ASSERT(false);
            return {};
    }
}

void MultiDayIncidenceModel::setModel(IncidenceOccurrenceModel *model)
{
    beginResetModel();
    mSourceModel = model;
    auto resetModel = [this] {
        beginResetModel();
        endResetModel();
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

QHash<int, QByteArray> MultiDayIncidenceModel::roleNames() const
{
    return {
        {Incidences, "incidences"},
        {PeriodStartDate, "periodStartDate"}
    };
}
