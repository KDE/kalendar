// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "hourlyincidencemodel.h"
#include "kalendar_debug.h"
#include <QTimeZone>
#include <cmath>

HourlyIncidenceModel::HourlyIncidenceModel(QObject *parent)
    : QAbstractItemModel(parent)
{
    mRefreshTimer.setSingleShot(true);
    mRefreshTimer.setInterval(100);
    mRefreshTimer.callOnTimeout(this, &HourlyIncidenceModel::resetLayoutLines);

    m_config = KalendarConfig::self();
    QObject::connect(m_config, &KalendarConfig::showSubtodosInCalendarViewsChanged, this, [&]() {
        beginResetModel();
        endResetModel();
    });
}

QModelIndex HourlyIncidenceModel::index(int row, int column, const QModelIndex &parent) const
{
    if (!hasIndex(row, column, parent)) {
        return {};
    }

    if (!parent.isValid()) {
        return createIndex(row, column);
    }
    return {};
}

QModelIndex HourlyIncidenceModel::parent(const QModelIndex &) const
{
    return {};
}

int HourlyIncidenceModel::rowCount(const QModelIndex &parent) const
{
    // Number of weeks
    if (!parent.isValid() && mSourceModel) {
        return qMax(mSourceModel->length(), 1);
    }
    return 0;
}

int HourlyIncidenceModel::columnCount(const QModelIndex &) const
{
    return 1;
}

static double getDuration(const QDateTime &start, const QDateTime &end, int periodLength)
{
    return ((start.secsTo(end) * 1.0) / 60.0) / periodLength;
}

// We first sort all occurrences so we get all-day first (sorted by duration),
// and then the rest sorted by start-date.
QList<QModelIndex> HourlyIncidenceModel::sortedIncidencesFromSourceModel(const QDateTime &rowStart) const
{
    // Don't add days if we are going for a daily period
    const auto rowEnd = rowStart.date().endOfDay();
    QList<QModelIndex> sorted;
    sorted.reserve(mSourceModel->rowCount());
    // Get incidences from source model
    for (int row = 0; row < mSourceModel->rowCount(); row++) {
        const auto srcIdx = mSourceModel->index(row, 0, {});
        const auto start = srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().toTimeZone(QTimeZone::systemTimeZone());
        const auto end = srcIdx.data(IncidenceOccurrenceModel::EndTime).toDateTime().toTimeZone(QTimeZone::systemTimeZone());

        // Skip incidences not part of the week
        if (end < rowStart || start > rowEnd) {
            // qCWarning(KALENDAR_LOG) << "Skipping because not part of this week";
            continue;
        }

        if (m_filters.testFlag(NoAllDay) && srcIdx.data(IncidenceOccurrenceModel::AllDay).toBool()) {
            continue;
        }

        if (m_filters.testFlag(NoMultiDay) && srcIdx.data(IncidenceOccurrenceModel::Duration).value<KCalendarCore::Duration>().asDays() >= 1) {
            continue;
        }

        if (!m_config->showSubtodosInCalendarViews()
            && !srcIdx.data(IncidenceOccurrenceModel::IncidencePtr).value<KCalendarCore::Incidence::Ptr>()->relatedTo().isEmpty()) {
            continue;
        }
        // qCWarning(KALENDAR_LOG) << "found " << srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime() <<
        // srcIdx.data(IncidenceOccurrenceModel::Summary).toString();
        sorted.append(srcIdx);
    }

    // Sort incidences by date
    std::sort(sorted.begin(), sorted.end(), [&](const QModelIndex &left, const QModelIndex &right) {
        // All-day first
        const auto leftAllDay = left.data(IncidenceOccurrenceModel::AllDay).toBool();
        const auto rightAllDay = right.data(IncidenceOccurrenceModel::AllDay).toBool();

        const auto leftDt = left.data(IncidenceOccurrenceModel::StartTime).toDateTime();
        const auto rightDt = right.data(IncidenceOccurrenceModel::StartTime).toDateTime();

        if (leftAllDay && !rightAllDay) {
            return true;
        }
        if (!leftAllDay && rightAllDay) {
            return false;
        }

        // The rest sorted by start date
        return leftDt < rightDt;
    });

    return sorted;
}

/*
 * Layout the lines:
 *
 * The line grouping algorithm then always picks the first incidence,
 * and tries to add more to the same line.
 *
 */
QVariantList HourlyIncidenceModel::layoutLines(const QDateTime &rowStart) const
{
    QList<QModelIndex> sorted = sortedIncidencesFromSourceModel(rowStart);
    const auto rowEnd = rowStart.date().endOfDay();
    const int periodsPerDay = (24 * 60) / mPeriodLength;

    // for (const auto &srcIdx : sorted) {
    //     qCWarning(KALENDAR_LOG) << "sorted " << srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime() <<
    //     srcIdx.data(IncidenceOccurrenceModel::Summary).toString()
    //     << srcIdx.data(IncidenceOccurrenceModel::AllDay).toBool();
    // }
    auto result = QVariantList{};

    auto addToResults = [&result](const QModelIndex &idx, double start, double duration) {
        auto incidenceMap = QVariantMap{
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
        };

        result.append(incidenceMap);
    };

    // Since our hourly view displays by the minute, we need to know how many incidences there are in each minute.
    // This hash's keys are the minute of the given day, as the view has accuracy down to the minute. Each value
    // for each key is the number of incidences that occupy that minute's spot.
    QHash<int, int> takenSpaces;
    auto setTakenSpaces = [&](int start, int end) {
        for (int i = start; i < end; i++) {
            if (!takenSpaces.contains(i)) {
                takenSpaces[i] = 1;
            } else {
                takenSpaces[i]++;
            }
        }
    };

    while (!sorted.isEmpty()) {
        const auto idx = sorted.takeFirst();
        const auto startDT = idx.data(IncidenceOccurrenceModel::StartTime).toDateTime().toTimeZone(QTimeZone::systemTimeZone()) > rowStart
            ? idx.data(IncidenceOccurrenceModel::StartTime).toDateTime().toTimeZone(QTimeZone::systemTimeZone())
            : rowStart;
        const auto endDT = idx.data(IncidenceOccurrenceModel::EndTime).toDateTime().toTimeZone(QTimeZone::systemTimeZone()) < rowEnd
            ? idx.data(IncidenceOccurrenceModel::EndTime).toDateTime().toTimeZone(QTimeZone::systemTimeZone())
            : rowEnd;
        // Need to convert ints into doubles to get more accurate starting positions
        // We get a start position relative to the number of period spaces there are in a day
        const auto start = ((startDT.time().hour() * 1.0) * (60.0 / mPeriodLength)) + ((startDT.time().minute() * 1.0) / mPeriodLength);
        auto duration = // Give a minimum acceptable height or otherwise have unclickable incidence
            qMax(getDuration(startDT, idx.data(IncidenceOccurrenceModel::EndTime).toDateTime().toTimeZone(QTimeZone::systemTimeZone()), mPeriodLength), 1.0);

        // Make sure incidence doesn't extend past the end of the day
        if (start + duration > periodsPerDay) {
            duration = periodsPerDay - start;
        }

        const auto realEndMinutesFromDayStart = qMin((endDT.time().hour() * 60) + endDT.time().minute(), 24 * 60 * 60);
        // Todos likely won't have end date
        const auto startMinutesFromDayStart =
            startDT.isValid() ? (startDT.time().hour() * 60) + startDT.time().minute() : qMax(realEndMinutesFromDayStart - mPeriodLength, 0);
        const auto displayedEndMinutesFromDayStart = floor(startMinutesFromDayStart + (mPeriodLength * duration));

        addToResults(idx, start, duration);
        setTakenSpaces(startMinutesFromDayStart, displayedEndMinutesFromDayStart);
    }

    QHash<int, double> takenWidth; // We need this for potential movers
    QHash<int, double> startX;
    // Potential movers are incidences that are placed at first but might need to be moved later as more incidences get placed to
    // the left of them. Rather than loop more than once over our incidences, we create a record of these and then deal with them
    // later, storing the needed data in a struct.
    struct PotentialMover {
        QVariantMap incidenceMap;
        int resultIterator;
        int startMinutesFromDayStart;
        int endMinutesFromDayStart;
    };
    QVector<PotentialMover> potentialMovers;

    // Calculate the width and x position of each incidence rectangle
    for (int i = 0; i < result.length(); i++) {
        auto incidence = result[i].value<QVariantMap>();
        int concurrentIncidences = 1;

        const auto startDT = incidence[QLatin1String("startTime")].toDateTime().toTimeZone(QTimeZone::systemTimeZone()) > rowStart
            ? incidence[QLatin1String("startTime")].toDateTime().toTimeZone(QTimeZone::systemTimeZone())
            : rowStart;
        const auto endDT = incidence[QLatin1String("endTime")].toDateTime().toTimeZone(QTimeZone::systemTimeZone()) < rowEnd
            ? incidence[QLatin1String("endTime")].toDateTime().toTimeZone(QTimeZone::systemTimeZone())
            : rowEnd;
        const auto duration = incidence[QLatin1String("duration")].toDouble();

        // We need a "real" and "displayed" end time for two reasons:
        // 1. We need the real end minutes to give a fake start time to todos which do not have a start time
        // 2. We need the displayed end minutes to be able to properly position those incidences which are displayed as longer
        // than they actually are
        const auto realEndMinutesFromDayStart = qMin((endDT.time().hour() * 60) + endDT.time().minute(), 24 * 60 * 60);
        // Todos likely won't have end date
        const auto startMinutesFromDayStart =
            startDT.isValid() ? (startDT.time().hour() * 60) + startDT.time().minute() : qMax(realEndMinutesFromDayStart - mPeriodLength, 0);
        const int displayedEndMinutesFromDayStart = floor(startMinutesFromDayStart + (mPeriodLength * duration));

        // Get max number of incidences that happen at the same time as this
        // (there can be different numbers of concurrent incidences during the time)
        for (int i = startMinutesFromDayStart; i < displayedEndMinutesFromDayStart; i++) {
            concurrentIncidences = qMax(concurrentIncidences, takenSpaces[i]);
        }

        incidence[QLatin1String("maxConcurrentIncidences")] = concurrentIncidences;
        double widthShare = 1.0 / (concurrentIncidences * 1.0); // Width as a fraction of the whole day column width
        incidence[QLatin1String("widthShare")] = widthShare;

        // This is the value that the QML view will use to position the incidence rectangle on the day column's X axis.
        double priorTakenWidthShare = 0.0;
        // If we have empty space at the very left of the column we want to take advantage and place an incidence there
        // even if there have been other incidences that take up space further to the right. For this we use minStartX,
        // which gathers the lowest x starting position in a given minute; if this is higher than 0, it means that there
        // is empty space at the left of the day column.
        double minStartX = 1.0;

        for (int i = startMinutesFromDayStart; i < displayedEndMinutesFromDayStart - 1; i++) {
            // If this is the first incidence that has taken up this minute position, set details
            if (!startX.contains(i)) {
                takenWidth[i] = widthShare;
                startX[i] = priorTakenWidthShare;
            } else {
                priorTakenWidthShare = qMax(priorTakenWidthShare, takenWidth[i]); // Get maximum prior space taken so we do not overlap with anything
                minStartX = qMin(minStartX, startX[i]);

                if (startX[i] > 0) {
                    takenWidth[i] = widthShare; // Reset as there is space available at the beginning of the column
                } else {
                    takenWidth[i] += widthShare; // Increase the taken width at this minute position
                }
            }
        }

        if (minStartX > 0) {
            priorTakenWidthShare = 0;
            for (int i = startMinutesFromDayStart; i < displayedEndMinutesFromDayStart; i++) {
                startX[i] = 0;
            }
        }

        incidence[QLatin1String("priorTakenWidthShare")] = priorTakenWidthShare;

        if (takenSpaces[startMinutesFromDayStart] < takenSpaces[displayedEndMinutesFromDayStart - 1] && priorTakenWidthShare > 0) {
            potentialMovers.append(PotentialMover{incidence, i, startMinutesFromDayStart, displayedEndMinutesFromDayStart});
        }

        result[i] = incidence;
    }

    for (auto &potentialMover : potentialMovers) {
        double maxTakenWidth = 0;
        for (int i = potentialMover.startMinutesFromDayStart; i < potentialMover.endMinutesFromDayStart; i++) {
            maxTakenWidth = qMax(maxTakenWidth, takenWidth[i]);
        }

        if (maxTakenWidth < 0.98) {
            potentialMover.incidenceMap[QLatin1String("priorTakenWidthShare")] =
                potentialMover.incidenceMap[QLatin1String("widthShare")].toDouble() * (takenSpaces[potentialMover.endMinutesFromDayStart - 1] - 1);

            result[potentialMover.resultIterator] = potentialMover.incidenceMap;
        }
    }

    return result;
}

void HourlyIncidenceModel::resetLayoutLines()
{
    if(mSourceModel->calendar()->isLoading()) {
        if(!mRefreshTimer.isActive()) {
            mRefreshTimer.start(100);
        }
        return;
    }

    beginResetModel();

    m_laidOutLines.clear();

    const auto numPeriods = rowCount({});
    m_laidOutLines.reserve(numPeriods);

    for(int i = 0; i < numPeriods; ++i) {
        const auto periodStart = mSourceModel->start().addDays(i).startOfDay();
        const auto periodIncidenceLayout = layoutLines(periodStart);
        m_laidOutLines.append(periodIncidenceLayout);
    }

    endResetModel();
}

QVariant HourlyIncidenceModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column()) || !mSourceModel || m_laidOutLines.empty()) {
        return {};
    }
    if (!mSourceModel) {
        return {};
    }
    const auto rowStart = mSourceModel->start().addDays(idx.row()).startOfDay();
    switch (role) {
    case PeriodStartDateTime:
        return rowStart;
    case Incidences:
        return m_laidOutLines.at(idx.row());
    default:
        Q_ASSERT(false);
        return {};
    }
}

IncidenceOccurrenceModel *HourlyIncidenceModel::model()
{
    return mSourceModel;
}

void HourlyIncidenceModel::setModel(IncidenceOccurrenceModel *model)
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
    QObject::connect(model, &QAbstractItemModel::dataChanged, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::layoutChanged, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::modelReset, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::rowsInserted, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::rowsMoved, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::rowsRemoved, this, resetModel);
}

void HourlyIncidenceModel::slotSourceDataChanged(const QModelIndex &upperLeft, const QModelIndex &bottomRight)
{
    if(!upperLeft.isValid() || !bottomRight.isValid()) {
        return;
    }

    const auto startRow = upperLeft.row();
    const auto endRow = bottomRight.row();

    scheduleLayoutLinesUpdates(upperLeft.parent(), startRow, endRow);
}

void HourlyIncidenceModel::scheduleLayoutLinesUpdates(const QModelIndex &sourceIndexParent, const int sourceFirstRow, const int sourceLastRow)
{
    if (!mSourceModel) {
        return;
    }

    // If we have no existing laid out lines it means we have not done an
    // initial setup. Go do that, which will provide incidences anyway
    if (m_laidOutLines.empty()) {
        resetLayoutLines();
        return;
    }

    // Don't bother if we are going for a full reset soon
    if (mRefreshTimer.isActive()) {
        return;
    }

    for (int i = sourceFirstRow; i <= sourceLastRow; ++i) {
        if(m_linesToUpdate.count() == m_laidOutLines.count()) {
            break;
        }

        const auto sourceModelIndex = mSourceModel->index(i, 0, sourceIndexParent);
        const auto occurrence = sourceModelIndex.data(IncidenceOccurrenceModel::IncidenceOccurrence).value<IncidenceOccurrenceModel::Occurrence>();

        const auto sourceModelStartDate = mSourceModel->start();
        const auto startDaysFromSourceStart = sourceModelStartDate.daysTo(occurrence.start.date());
        const auto endDaysFromSourceStart = sourceModelStartDate.daysTo(occurrence.end.date());

        const auto firstPeriodOccurrenceAppears = startDaysFromSourceStart / mPeriodLength;
        const auto lastPeriodOccurrenceAppears = endDaysFromSourceStart / mPeriodLength;

        if(firstPeriodOccurrenceAppears > m_laidOutLines.count() || lastPeriodOccurrenceAppears < 0) {
            continue;
        }

        const auto lastRow = m_laidOutLines.count() - 1;
        const auto minRow = qMin(qMax(static_cast<int>(firstPeriodOccurrenceAppears), 0), lastRow);
        const auto maxRow = qMin(static_cast<int>(lastPeriodOccurrenceAppears), lastRow);

        // We set the layout lines scheduled to redo
        m_linesToUpdate.insert(minRow);
        m_linesToUpdate.insert(maxRow);
    }

    // Throttle how often we are changing the lines or the views will be slow
    if (!m_updateLinesTimer.isActive()) {
        m_updateLinesTimer.start(100);
    }
}

void HourlyIncidenceModel::updateScheduledLayoutLines()
{
    for (const auto lineIndex : m_linesToUpdate) {
        const auto periodStart = mSourceModel->start().addDays(lineIndex).startOfDay();
        const auto idx = index(lineIndex, 0);
        const auto laidOutLine = layoutLines(periodStart);

        m_laidOutLines.replace(lineIndex, laidOutLine);
        Q_EMIT dataChanged(idx, idx);
    }

    m_linesToUpdate.clear();
}

int HourlyIncidenceModel::periodLength()
{
    return mPeriodLength;
}

void HourlyIncidenceModel::setPeriodLength(int periodLength)
{
    mPeriodLength = periodLength;
}

HourlyIncidenceModel::Filters HourlyIncidenceModel::filters()
{
    return m_filters;
}

void HourlyIncidenceModel::setFilters(HourlyIncidenceModel::Filters filters)
{
    beginResetModel();
    m_filters = filters;
    Q_EMIT filtersChanged();
    endResetModel();
}

QHash<int, QByteArray> HourlyIncidenceModel::roleNames() const
{
    return {
        {Incidences, "incidences"},
        {PeriodStartDateTime, "periodStartDateTime"},
    };
}
