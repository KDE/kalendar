// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "multidayincidencemodel.h"
#include <QBitArray>

MultiDayIncidenceModel::MultiDayIncidenceModel(QObject *parent)
    : QAbstractItemModel(parent)
{
    mRefreshTimer.setSingleShot(true);
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
    case Incidences: {
        if (!m_incidencesModels.contains(rowStart)) {
            auto viewIncidenceModel = new ViewIncidencesModel(rowStart, mPeriodLength, mSourceModel);
            viewIncidenceModel->setModel(mSourceModel);
            m_incidencesModels[rowStart] = viewIncidenceModel;
        }

        return QVariant::fromValue(m_incidencesModels[rowStart]);
    }
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
    // QObject::connect(model, &QAbstractItemModel::dataChanged, this, resetModel);
    // QObject::connect(model, &QAbstractItemModel::layoutChanged, this, resetModel);
    // QObject::connect(model, &QAbstractItemModel::modelReset, this, resetModel);
    // QObject::connect(model, &QAbstractItemModel::rowsInserted, this, resetModel);
    // QObject::connect(model, &QAbstractItemModel::rowsMoved, this, resetModel);
    // QObject::connect(model, &QAbstractItemModel::rowsRemoved, this, resetModel);

    for (auto incidencesModel : m_incidencesModels) {
        incidencesModel->setModel(mSourceModel);
    }
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
    if (!m_filters) {
        return true;
    }
    bool include = false;
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
                // qWarning() << "Skipping because not part of this week";
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
