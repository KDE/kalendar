// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QBitArray>
#include <viewincidencesmodel.h>

ViewIncidencesModel::ViewIncidencesModel(QDate periodStart, int periodLength, IncidenceOccurrenceModel *sourceModel, QObject *parent)
    : QAbstractListModel(parent)
{
    mRefreshTimer.setSingleShot(true);

    m_periodStart = periodStart;
    m_periodEnd = periodStart.addDays(periodLength);
    m_periodLength = periodLength;
    setModel(sourceModel);

    sortedIncidencesFromSourceModel();
    layoutLines();
}

IncidenceOccurrenceModel *ViewIncidencesModel::model()
{
    return m_sourceModel;
}

void ViewIncidencesModel::setModel(IncidenceOccurrenceModel *model)
{
    auto resetModel = [this] {
        if (!mRefreshTimer.isActive()) {
            beginResetModel();
            sortedIncidencesFromSourceModel();
            layoutLines();
            endResetModel();
            mRefreshTimer.start(50);
        }
    };

    m_sourceModel = model;
    QObject::connect(model, &QAbstractItemModel::dataChanged, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::layoutChanged, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::modelReset, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::rowsInserted, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::rowsMoved, this, resetModel);
    QObject::connect(model, &QAbstractItemModel::rowsRemoved, this, resetModel);
    /*connect(model, &QAbstractItemModel::rowsInserted, this, [&]() {
        qDebug() << "wee";
        for(int i = first; i <= last; i++) {
            auto index = model->index(i, 0);
            insertIncidence(index);
        }
    });*/

    Q_EMIT modelChanged();
}

static ViewIncidencesModel::IncidenceOccurrenceData generateStructFromIndex(const QModelIndex &idx)
{
    return {idx.data(IncidenceOccurrenceModel::Summary).toString(),
            idx.data(IncidenceOccurrenceModel::Description).toString(),
            idx.data(IncidenceOccurrenceModel::Location).toString(),
            idx.data(IncidenceOccurrenceModel::StartTime).toDateTime(),
            idx.data(IncidenceOccurrenceModel::EndTime).toDateTime(),
            idx.data(IncidenceOccurrenceModel::AllDay).toBool(),
            idx.data(IncidenceOccurrenceModel::TodoCompleted).toBool(),
            idx.data(IncidenceOccurrenceModel::Priority).toInt(),
            0,
            0,
            0,
            idx.data(IncidenceOccurrenceModel::DurationString).toString(),
            idx.data(IncidenceOccurrenceModel::Recurs).toBool(),
            idx.data(IncidenceOccurrenceModel::HasReminders).toBool(),
            idx.data(IncidenceOccurrenceModel::IsOverdue).toBool(),
            idx.data(IncidenceOccurrenceModel::Color).value<QColor>(),
            idx.data(IncidenceOccurrenceModel::CollectionId).toInt(),
            idx.data(IncidenceOccurrenceModel::IncidenceId).toString(),
            idx.data(IncidenceOccurrenceModel::IncidenceType).toInt(),
            idx.data(IncidenceOccurrenceModel::IncidenceTypeStr).toString(),
            idx.data(IncidenceOccurrenceModel::IncidenceTypeIcon).toString(),
            idx.data(IncidenceOccurrenceModel::IncidencePtr).value<KCalendarCore::Incidence::Ptr>(),
            idx.data(IncidenceOccurrenceModel::IncidenceOccurrence).toDateTime()};
}

static long long getDuration(const QDate &start, const QDate &end)
{
    return qMax(start.daysTo(end) + 1, 1ll);
}

static bool lesserOccurrence(const ViewIncidencesModel::IncidenceOccurrenceData &left, const ViewIncidencesModel::IncidenceOccurrenceData &right)
{
    // All-day first, sorted by duration (in the hope that we can fit multiple on the same line)
    const auto leftAllDay = left.allDay;
    const auto rightAllDay = right.allDay;

    const auto leftDuration = getDuration(left.startTime.date(), left.endTime.date());
    const auto rightDuration = getDuration(right.startTime.date(), right.endTime.date());

    const auto leftDt = left.startTime;
    const auto rightDt = right.startTime;

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
};

// We first sort all occurrences so we get all-day first (sorted by duration),
// and then the rest sorted by start-date.
void ViewIncidencesModel::sortedIncidencesFromSourceModel()
{
    m_incidenceOccurrences.clear();

    // Get incidences from source model
    for (int row = 0; row < m_sourceModel->rowCount(); row++) {
        const auto srcIdx = m_sourceModel->index(row, 0, {});
        const auto id = srcIdx.data(IncidenceOccurrenceModel::IncidenceId).toString();
        const auto start = srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().date();
        const auto end = srcIdx.data(IncidenceOccurrenceModel::EndTime).toDateTime().date();

        // Skip incidences not part of the week
        if (end < m_periodStart || start > m_periodEnd) {
            // qWarning() << "Skipping because not part of this week";
            continue;
        }

        /*if (!incidencePassesFilter(srcIdx)) {
         *                continue;
    }*/

        // qWarning() << "found " << srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime() << srcIdx.data(IncidenceOccurrenceModel::Summary).toString();
        m_incidenceOccurrences.append(generateStructFromIndex(srcIdx));
    }

    // Sort incidences by date
    std::sort(m_incidenceOccurrences.begin(), m_incidenceOccurrences.end(), &lesserOccurrence);
}

void ViewIncidencesModel::insertIncidence(QModelIndex srcIdx)
{
    auto incidenceOccurrenceData = generateStructFromIndex(srcIdx);
    qDebug() << incidenceOccurrenceData.text;

    int i = 0;
    while (lesserOccurrence(incidenceOccurrenceData, m_incidenceOccurrences[i])) {
        i++;

        if (i == m_incidenceOccurrences.length()) {
            break;
        }
    }

    beginInsertRows(QModelIndex(), i, i);
    m_incidenceOccurrences.insert(i, incidenceOccurrenceData);
    endInsertRows();

    layoutLines();
};

/*
 * Layout the lines:
 *
 * The line grouping algorithm then always picks the first incidence,
 * and tries to add more to the same line.
 *
 * We never mix all-day and non-all day, and otherwise try to fit as much as possible
 * on the same line. Same day time-order should be preserved because of the sorting.
 */
void ViewIncidencesModel::layoutLines()
{
    auto getStart = [this](const QDate &start) {
        return qMax(m_periodStart.daysTo(start), 0ll);
    };

    QVector<IncidenceOccurrenceData> originalOccurrences;
    QVector<IncidenceOccurrenceData> laidOutOccurrences;
    int lineNum = 0;

    while (!m_incidenceOccurrences.isEmpty()) {
        auto firstOfLine = m_incidenceOccurrences.takeFirst();
        const auto startDate = firstOfLine.startTime.date() < m_periodStart ? m_periodStart : firstOfLine.startTime.date();
        const auto start = getStart(firstOfLine.startTime.date());
        const auto duration = qMin(getDuration(startDate, firstOfLine.endTime.date()), m_periodLength - start);

        qDebug() << firstOfLine.text << start << duration << lineNum;

        if (start >= m_periodLength) {
            // qWarning() << "Skipping " << srcIdx.data(IncidenceOccurrenceModel::Summary);
            continue;
        }

        // Add first incidence of line
        firstOfLine.line = lineNum;
        firstOfLine.starts = start;
        firstOfLine.duration = duration;
        laidOutOccurrences.append(firstOfLine);
        // const bool allDayLine = srcIdx.data(IncidenceOccurrenceModel::AllDay).toBool();

        // Fill line with incidences that fit
        QBitArray takenSpaces(m_periodLength);
        // Set this incidence's space as taken
        for (int i = start; i < start + duration; i++) {
            takenSpaces[i] = true;
        }

        auto doesIntersect = [&](int start, int end) {
            for (int i = start; i < end; i++) {
                if (takenSpaces[i]) {
                    // qWarning() << "Found intersection " << start << end;
                    return true;
                }
            }

            // If incidence fits on line, set its space as taken
            for (int i = start; i < end; i++) {
                takenSpaces[i] = true;
            }
            return false;
        };

        for (auto it = m_incidenceOccurrences.begin(); it != m_incidenceOccurrences.end();) {
            auto occ = *it;
            const auto startDate = occ.startTime.date() < m_periodStart ? m_periodStart : occ.startTime.date();
            const auto start = getStart(occ.startTime.date());
            const auto duration = qMin(getDuration(startDate, occ.endTime.date()), m_periodLength - start);
            const auto end = start + duration;

            // This leaves a space in rows with all day events, making this y area of the row exclusively for all day events
            /*if (allDayLine && !idx.data(IncidenceOccurrenceModel::AllDay).toBool()) {
             *                    continue;
        }*/

            qDebug() << occ.text << start << duration << lineNum;
            if (doesIntersect(start, end)) {
                it++;
            } else {
                occ.line = lineNum;
                occ.starts = start;
                occ.duration = duration;
                laidOutOccurrences.append(occ);
                it = m_incidenceOccurrences.erase(it);
            }
        }
        // qWarning() << "Adding line " << lineNum;
        lineNum++;
    }
    m_incidenceOccurrences = laidOutOccurrences;

    for (int i = 0; i < originalOccurrences.length(); i++) {
        if (laidOutOccurrences[i].starts == originalOccurrences[i].starts && laidOutOccurrences[i].duration == originalOccurrences[i].duration
            && laidOutOccurrences[i].line == originalOccurrences[i].line) {
            continue;
        }

        Q_EMIT dataChanged(index(i, 0), index(i, 0));
    }
}

int ViewIncidencesModel::rowCount(const QModelIndex &) const
{
    return m_incidenceOccurrences.count();
}

QVariant ViewIncidencesModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }
    if (!m_sourceModel) {
        return {};
    }

    switch (role) {
    case TextRole:
        return m_incidenceOccurrences[idx.row()].text;
    case DescriptionRole:
        return m_incidenceOccurrences[idx.row()].description;
    case LocationRole:
        return m_incidenceOccurrences[idx.row()].location;
    case StartTimeRole:
        return m_incidenceOccurrences[idx.row()].startTime;
    case EndTimeRole:
        return m_incidenceOccurrences[idx.row()].endTime;
    case AllDayRole:
        return m_incidenceOccurrences[idx.row()].allDay;
    case TodoCompletedRole:
        return m_incidenceOccurrences[idx.row()].todoCompleted;
    case PriorityRole:
        return m_incidenceOccurrences[idx.row()].priority;
    case LineRole:
        return m_incidenceOccurrences[idx.row()].line;
    case StartsRole:
        return m_incidenceOccurrences[idx.row()].starts;
    case DurationRole:
        return m_incidenceOccurrences[idx.row()].duration;
    case DurationStringRole:
        return m_incidenceOccurrences[idx.row()].durationString;
    case RecursRole:
        return m_incidenceOccurrences[idx.row()].recurs;
    case HasRemindersRole:
        return m_incidenceOccurrences[idx.row()].hasReminders;
    case IsOverdueRole:
        return m_incidenceOccurrences[idx.row()].isOverdue;
    case ColorRole:
        return m_incidenceOccurrences[idx.row()].color;
    case CollectionIdRole:
        return m_incidenceOccurrences[idx.row()].collectionId;
    case IncidenceIdRole:
        return m_incidenceOccurrences[idx.row()].incidenceId;
    case IncidenceTypeRole:
        return m_incidenceOccurrences[idx.row()].incidenceType;
    case IncidenceTypeStrRole:
        return m_incidenceOccurrences[idx.row()].incidenceTypeStr;
    case IncidenceTypeIconRole:
        return m_incidenceOccurrences[idx.row()].incidenceTypeIcon;
    case IncidencePtrRole:
        return QVariant::fromValue(m_incidenceOccurrences[idx.row()].incidencePtr);
    case IncidenceOccurrenceRole:
        return QVariant::fromValue(m_incidenceOccurrences[idx.row()].incidenceOccurrence);
    default:
        Q_ASSERT(false);
        return {};
    }
}

QHash<int, QByteArray> ViewIncidencesModel::roleNames() const
{
    return {{TextRole, "text"},
            {DescriptionRole, "description"},
            {LocationRole, "location"},
            {StartTimeRole, "startTime"},
            {EndTimeRole, "endTime"},
            {AllDayRole, "allDay"},
            {TodoCompletedRole, "todoCompleted"},
            {PriorityRole, "priority"},
            {LineRole, "line"},
            {StartsRole, "starts"},
            {DurationRole, "duration"},
            {DurationStringRole, "durationString"},
            {RecursRole, "recurs"},
            {HasRemindersRole, "hasReminders"},
            {IsOverdueRole, "isOverdue"},
            {ColorRole, "color"},
            {CollectionIdRole, "collectionId"},
            {IncidenceIdRole, "incidenceId"},
            {IncidenceTypeRole, "incidenceType"},
            {IncidenceTypeStrRole, "incidenceTypeStr"},
            {IncidenceTypeIconRole, "IncidenceTypeIcon"},
            {IncidencePtrRole, "incidencePtr"},
            {IncidenceOccurrenceRole, "incidenceOccurrence"}};
}
